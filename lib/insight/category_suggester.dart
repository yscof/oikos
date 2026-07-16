/// 스마트 카테고리 추천 — pure Dart, 결정적.
/// 점수 = 2.0 × 과거 이력 매칭(지수 감쇠) + 1.0 × 콜드스타트 prior.
/// 정본 케이스: 평일 12:30 + 12,000원 → 식사 1위.
library;

import 'dart:math';

import '../data/entry.dart';

enum TimeBucket { dawn, morning, lunch, afternoon, evening, night }

TimeBucket timeBucketOf(DateTime t) {
  final h = t.hour;
  if (h < 6) return TimeBucket.dawn;
  if (h < 11) return TimeBucket.morning;
  if (h < 14) return TimeBucket.lunch;
  if (h < 18) return TimeBucket.afternoon;
  if (h < 21) return TimeBucket.evening;
  return TimeBucket.night;
}

/// ≤5천 / ≤1.5만 / ≤5만 / ≤15만 / 초과
enum AmountBand { tiny, small, medium, large, huge }

AmountBand amountBandOf(int won) {
  if (won <= 5000) return AmountBand.tiny;
  if (won <= 15000) return AmountBand.small;
  if (won <= 50000) return AmountBand.medium;
  if (won <= 150000) return AmountBand.large;
  return AmountBand.huge;
}

bool _isWeekend(DateTime t) =>
    t.weekday == DateTime.saturday || t.weekday == DateTime.sunday;

const double _halfLifeDays = 30;
const double _historyWeight = 2.0;
const double _priorWeight = 1.0;

double _decay(DateTime now, DateTime past) {
  final days = now.difference(past).inMinutes / (60 * 24);
  if (days <= 0) return 1;
  return pow(0.5, days / _halfLifeDays).toDouble();
}

/// 기록이 없을 때의 상식 prior. 20-30대 소비 패턴 하드코딩 표.
Map<Category, double> _prior(TimeBucket bucket, AmountBand band, bool weekend) {
  final p = <Category, double>{};
  void bump(Category c, double w) => p[c] = (p[c] ?? 0) + w;
  final smallish = band == AmountBand.tiny || band == AmountBand.small;

  switch (bucket) {
    case TimeBucket.morning:
      bump(Category.cafe, 0.8);
      bump(Category.transport, weekend ? 0.2 : 0.6);
      bump(Category.mart, 0.4);
      if (band == AmountBand.small) bump(Category.meal, 0.5);
    case TimeBucket.lunch:
      if (band == AmountBand.small) bump(Category.meal, 1.0);
      if (band == AmountBand.medium) bump(Category.meal, 0.7);
      if (band == AmountBand.tiny) bump(Category.cafe, 0.8);
      bump(Category.cafe, 0.3);
    case TimeBucket.afternoon:
      if (smallish) bump(Category.cafe, 0.8);
      if (band == AmountBand.tiny) bump(Category.mart, 0.5);
      if (weekend) {
        bump(Category.shopping, smallish ? 0.5 : 1.0);
        bump(Category.leisure, 0.5);
      }
    case TimeBucket.evening:
      if (smallish) bump(Category.meal, 0.8);
      if (band == AmountBand.medium) {
        bump(Category.meal, 0.6);
        bump(Category.drinks, 0.5);
        bump(Category.delivery, 0.5);
      }
      bump(Category.mart, 0.3);
    case TimeBucket.night:
      if (band == AmountBand.small || band == AmountBand.medium) {
        bump(Category.delivery, 0.9);
        bump(Category.drinks, 0.7);
      }
      if (band == AmountBand.tiny) bump(Category.mart, 0.8);
      bump(Category.shopping, 0.3);
    case TimeBucket.dawn:
      if (band == AmountBand.tiny) bump(Category.mart, 0.7);
      bump(Category.delivery, 0.3);
      bump(Category.drinks, 0.3);
      bump(Category.transport, 0.3);
  }

  // 큰 금액은 시간대보다 금액대가 품목을 말해준다.
  switch (band) {
    case AmountBand.large:
      bump(Category.shopping, 0.6);
      bump(Category.fashion, 0.5);
      bump(Category.medical, 0.3);
    case AmountBand.huge:
      bump(Category.housing, 0.7);
      bump(Category.shopping, 0.4);
      bump(Category.medical, 0.3);
    case AmountBand.tiny:
    case AmountBand.small:
    case AmountBand.medium:
      break;
  }
  return p;
}

/// 지출 카테고리 전체를 점수순으로 돌려준다 (동점은 enum 선언 순).
/// 수입 기록은 입력에서 제외된다.
List<Category> rankCategories({
  required DateTime now,
  required int amountWon,
  required List<Entry> history,
}) {
  final bucket = timeBucketOf(now);
  final band = amountBandOf(amountWon);
  final weekend = _isWeekend(now);

  final scores = <Category, double>{
    for (final c in Category.of(EntryKind.expense)) c: 0,
  };

  _prior(bucket, band, weekend).forEach((c, w) {
    scores[c] = scores[c]! + _priorWeight * w;
  });

  for (final e in history) {
    if (e.kind != EntryKind.expense) continue;
    if (!scores.containsKey(e.category)) continue;
    final timeMatch = timeBucketOf(e.occurredAt) == bucket;
    final bandMatch = amountBandOf(e.amountWon) == band;
    if (!timeMatch && !bandMatch) continue;
    var match = (timeMatch ? 1.0 : 0.0) + (bandMatch ? 1.0 : 0.0);
    if (_isWeekend(e.occurredAt) == weekend) match += 0.5;
    scores[e.category] =
        scores[e.category]! + _historyWeight * match * _decay(now, e.occurredAt);
  }

  final ranked = Category.of(EntryKind.expense).toList();
  ranked.sort((a, b) {
    final byScore = scores[b]!.compareTo(scores[a]!);
    if (byScore != 0) return byScore;
    return a.index.compareTo(b.index);
  });
  return ranked;
}
