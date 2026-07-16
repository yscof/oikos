/// 주간 통계와 4주 baseline — pure Dart.
library;

import 'dart:math';

import '../data/entry.dart';

/// 그 날이 속한 주의 월요일 00:00.
DateTime weekStartOf(DateTime t) {
  final day = DateTime(t.year, t.month, t.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// [weekStart, weekStart+7일) 구간의 지출 통계. 수입은 세지 않는다.
class WeekStats {
  const WeekStats._({
    required this.totalWon,
    required this.count,
    required this.wonByCategory,
    required this.countByCategory,
    required this.wonByWeekday,
  });

  final int totalWon;
  final int count;
  final Map<Category, int> wonByCategory;
  final Map<Category, int> countByCategory;

  /// DateTime.weekday(월=1…일=7) → 지출 원
  final Map<int, int> wonByWeekday;

  factory WeekStats.of(List<Entry> entries, DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7));
    var total = 0;
    var count = 0;
    final wonBy = <Category, int>{};
    final countBy = <Category, int>{};
    final byWeekday = <int, int>{};
    for (final e in entries) {
      if (e.kind != EntryKind.expense) continue;
      if (e.occurredAt.isBefore(weekStart) || !e.occurredAt.isBefore(end)) {
        continue;
      }
      total += e.amountWon;
      count += 1;
      wonBy[e.category] = (wonBy[e.category] ?? 0) + e.amountWon;
      countBy[e.category] = (countBy[e.category] ?? 0) + 1;
      byWeekday[e.occurredAt.weekday] =
          (byWeekday[e.occurredAt.weekday] ?? 0) + e.amountWon;
    }
    return WeekStats._(
      totalWon: total,
      count: count,
      wonByCategory: wonBy,
      countByCategory: countBy,
      wonByWeekday: byWeekday,
    );
  }
}

/// 이번 주 이전 4주의 평균. 지출이 있던 주 수로 나눠
/// 기록을 늦게 시작한 사용자의 baseline이 눌리지 않게 한다.
class Baseline {
  const Baseline._({
    required this.weeksWithData,
    required this.avgTotalWon,
    required this.avgCount,
    required this.avgWonByCategory,
    required this.avgCountByCategory,
    required this.wonByWeekday4w,
    required this.totalWon4w,
    required this.totalCount4w,
  });

  final int weeksWithData; // 0~4
  final double avgTotalWon;
  final double avgCount;
  final Map<Category, double> avgWonByCategory;
  final Map<Category, double> avgCountByCategory;
  final Map<int, int> wonByWeekday4w; // 4주 합
  final int totalWon4w;
  final int totalCount4w;

  factory Baseline.over4Weeks(List<Entry> entries, DateTime thisWeekStart) {
    final stats = [
      for (var i = 4; i >= 1; i--)
        WeekStats.of(entries, thisWeekStart.subtract(Duration(days: 7 * i))),
    ];
    final weeksWithData = stats.where((s) => s.count > 0).length;
    final divisor = max(weeksWithData, 1);

    var totalWon = 0;
    var totalCount = 0;
    final wonBy = <Category, int>{};
    final countBy = <Category, int>{};
    final byWeekday = <int, int>{};
    for (final s in stats) {
      totalWon += s.totalWon;
      totalCount += s.count;
      s.wonByCategory.forEach((c, w) => wonBy[c] = (wonBy[c] ?? 0) + w);
      s.countByCategory.forEach((c, n) => countBy[c] = (countBy[c] ?? 0) + n);
      s.wonByWeekday.forEach((d, w) => byWeekday[d] = (byWeekday[d] ?? 0) + w);
    }
    return Baseline._(
      weeksWithData: weeksWithData,
      avgTotalWon: totalWon / divisor,
      avgCount: totalCount / divisor,
      avgWonByCategory: wonBy.map((c, w) => MapEntry(c, w / divisor)),
      avgCountByCategory: countBy.map((c, n) => MapEntry(c, n / divisor)),
      wonByWeekday4w: byWeekday,
      totalWon4w: totalWon,
      totalCount4w: totalCount,
    );
  }
}
