/// 룰 기반 인사이트 엔진 — pure Dart, 결정적.
/// 같은 날 같은 데이터면 항상 같은 문장이 나온다 (신뢰).
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../core/formats.dart';
import '../core/month.dart';
import '../data/entry.dart';
import '../data/entry_store.dart';
import '../data/month_start_store.dart';
import 'baseline.dart';
import 'insight.dart';
import 'insight_messages.dart' as msg;

const int _coldStartMinEntries = 8;
const int _coldStartMinDays = 7;

/// 소액 노이즈 필터 — baseline·이번 주 모두 이 밑이면 델타 룰이 침묵한다.
const int _minBaselineWon = 10000;
const int _minThisWeekWon = 10000;
const double _upRatio = 1.4;
const double _downRatio = 0.6;
const double _quietRatio = 0.7;
const int _quietMinBaselineWon = 30000;
const double _weekdayShare = 0.4;

final insightResultProvider = Provider<InsightResult>((ref) {
  final entries = ref.watch(entryStoreProvider);
  final now = ref.watch(clockProvider)();
  return evaluateInsights(entries, now);
});

/// 홈 소문(『이번 주 지출 …』)용 이번 주 지출 총액.
final weekExpenseWonProvider = Provider<int>((ref) {
  final entries = ref.watch(entryStoreProvider);
  final now = ref.watch(clockProvider)();
  return WeekStats.of(entries, weekStartOf(now)).totalWon;
});

/// 홈 소문(『오늘 지출 …』)용 오늘 지출 총액. 습관은 하루 단위로 만들어진다.
final todayExpenseWonProvider = Provider<int>((ref) {
  final entries = ref.watch(entryStoreProvider);
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  var total = 0;
  for (final e in entries) {
    if (e.kind != EntryKind.expense) continue;
    if (e.occurredAt.isBefore(today) || !e.occurredAt.isBefore(tomorrow)) {
      continue;
    }
    total += e.amountWon;
  }
  return total;
});

/// 이번 달 지출·수입 합계 (FR-403). 정산 기준일(FR-601)을 존중한다.
int _monthSum(Ref ref, EntryKind kind) {
  final entries = ref.watch(entryStoreProvider);
  final now = ref.watch(clockProvider)();
  final startDay = ref.watch(monthStartDayProvider);
  final range = financialMonthRange(now, startDay);
  var total = 0;
  for (final e in entries) {
    if (e.kind != kind) continue;
    if (e.occurredAt.isBefore(range.start) ||
        !e.occurredAt.isBefore(range.end)) {
      continue;
    }
    total += e.amountWon;
  }
  return total;
}

final monthExpenseWonProvider =
    Provider<int>((ref) => _monthSum(ref, EntryKind.expense));
final monthIncomeWonProvider =
    Provider<int>((ref) => _monthSum(ref, EntryKind.income));

int _dayOfYear(DateTime t) => t.difference(DateTime(t.year)).inDays + 1;

bool _isColdStart(List<Entry> entries, DateTime now) {
  if (entries.length < _coldStartMinEntries) return true;
  final earliest = entries
      .map((e) => e.occurredAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  return now.difference(earliest).inDays < _coldStartMinDays;
}

InsightResult evaluateInsights(List<Entry> entries, DateTime now) {
  if (_isColdStart(entries, now)) {
    final index = _dayOfYear(now) % msg.coldStartHeadlines.length;
    return InsightResult(
      headline: Insight(
        rule: InsightRule.coldStart,
        priority: 0,
        headline: msg.coldStartHeadlines[index],
      ),
      senses: const [],
    );
  }

  final thisWeekStart = weekStartOf(now);
  final week = WeekStats.of(entries, thisWeekStart);
  final base = Baseline.over4Weeks(entries, thisWeekStart);
  final candidates = <Insight>[];

  // 룰 1·2 — 카테고리 증감
  for (final c in Category.of(EntryKind.expense)) {
    final baseWon = base.avgWonByCategory[c] ?? 0;
    if (baseWon < _minBaselineWon) continue;
    final weekWon = week.wonByCategory[c] ?? 0;
    final ratio = weekWon / baseWon;
    if (weekWon >= _minThisWeekWon && ratio >= _upRatio) {
      candidates.add(Insight(
        rule: InsightRule.categoryDeltaUp,
        priority: 3.0 + min(ratio - _upRatio, 2.0),
        headline: msg.headlineDeltaUp(c),
        evidence: msg.evidenceWonDelta(baseWon, weekWon),
        category: c,
      ));
    } else if (ratio <= _downRatio) {
      candidates.add(Insight(
        rule: InsightRule.categoryDeltaDown,
        priority: 2.5 + (_downRatio - ratio),
        headline: msg.headlineDeltaDown(c),
        evidence: msg.evidenceWonDelta(baseWon, weekWon),
        category: c,
      ));
    }
  }

  // 룰 3 — 빈도
  for (final c in Category.of(EntryKind.expense)) {
    final baseCount = base.avgCountByCategory[c] ?? 0;
    final weekCount = week.countByCategory[c] ?? 0;
    if (weekCount >= 3 && weekCount >= 2 * baseCount) {
      candidates.add(Insight(
        rule: InsightRule.frequency,
        priority: 2.8 + min(weekCount * 0.01, 0.19),
        headline: msg.headlineFrequency(c),
        evidence: msg.evidenceCountDelta(baseCount, weekCount),
        category: c,
      ));
    }
  }

  // 룰 4 — 차분한 주 (주 3일차인 수요일부터)
  if (now.weekday >= DateTime.wednesday &&
      base.avgTotalWon >= _quietMinBaselineWon &&
      week.totalWon <= _quietRatio * base.avgTotalWon) {
    candidates.add(Insight(
      rule: InsightRule.quietWeek,
      priority: 2.0,
      headline: msg.headlineQuietWeek(),
      evidence: msg.evidenceQuietWeek(base.avgTotalWon, week.totalWon),
    ));
  }

  // 룰 5 — 요일 집중 (저순위)
  if (base.totalCount4w >= 8 && base.totalWon4w > 0) {
    var topWeekday = 0;
    var topWon = 0;
    for (var d = DateTime.monday; d <= DateTime.sunday; d++) {
      final w = base.wonByWeekday4w[d] ?? 0;
      if (w > topWon) {
        topWon = w;
        topWeekday = d;
      }
    }
    final share = topWon / base.totalWon4w;
    if (share >= _weekdayShare) {
      final dayName = weekdaysKo[topWeekday - 1];
      candidates.add(Insight(
        rule: InsightRule.weekdayPattern,
        priority: 1.0,
        headline: msg.headlineWeekdayPattern(dayName),
        evidence: msg.evidenceWeekday((share * 100).round(), dayName),
      ));
    }
  }

  // 폴백 — 아무 룰도 울리지 않은 평범한 주
  candidates.add(Insight(
    rule: InsightRule.steady,
    priority: 0,
    headline: msg.headlineSteady(),
    evidence: base.avgTotalWon > 0
        ? msg.evidenceWonDelta(base.avgTotalWon, week.totalWon)
        : null,
  ));

  // 결정적 선택: 우선순위 → 룰 순서 → 카테고리 순서
  candidates.sort((a, b) {
    final byPriority = b.priority.compareTo(a.priority);
    if (byPriority != 0) return byPriority;
    final byRule = a.rule.index.compareTo(b.rule.index);
    if (byRule != 0) return byRule;
    return (a.category?.index ?? -1).compareTo(b.category?.index ?? -1);
  });

  final headline = candidates.first;
  final senses = <Insight>[];
  for (final c in candidates.skip(1)) {
    if (senses.length == 2) break;
    if (c.rule == InsightRule.steady) continue;
    if (c.rule == headline.rule) continue;
    if (senses.any((s) => s.rule == c.rule)) continue;
    if (c.category != null && c.category == headline.category) continue;
    senses.add(c);
  }
  return InsightResult(headline: headline, senses: senses);
}
