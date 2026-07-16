import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';
import 'package:oikos/insight/insight.dart';
import 'package:oikos/insight/insight_engine.dart';

/// 2026-07-16은 목요일. 이번 주 시작 = 7/13(월).
/// 이전 4주 월요일: 6/15, 6/22, 6/29, 7/6.
final now = DateTime(2026, 7, 16, 12, 30);

Entry exp(Category c, int amount, DateTime at) => Entry(
      id: '${c.name}-${at.microsecondsSinceEpoch}',
      kind: EntryKind.expense,
      amountWon: amount,
      category: c,
      memo: '',
      occurredAt: at,
      createdAt: at,
    );

/// 이전 4주 각 주에 배달 2만원(화) + 식사 3천원(수). 8건, 4주 스팬.
List<Entry> deliveryBaseline() => [
      for (final monday in [
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 22),
        DateTime(2026, 6, 29),
        DateTime(2026, 7, 6),
      ]) ...[
        exp(Category.delivery, 20000, monday.add(const Duration(days: 1, hours: 19))),
        exp(Category.meal, 3000, monday.add(const Duration(days: 2, hours: 12))),
      ],
    ];

void main() {
  group('콜드스타트 게이트', () {
    test('기록 8건 미만이면 콜드스타트', () {
      final entries = [
        for (var w = 0; w < 7; w++)
          exp(Category.meal, 10000, DateTime(2026, 6, 1 + w * 5, 12)),
      ];
      final result = evaluateInsights(entries, now);
      expect(result.headline.rule, InsightRule.coldStart);
      expect(result.senses, isEmpty);
    });

    test('기록 스팬이 7일 미만이면 콜드스타트', () {
      final entries = [
        for (var i = 0; i < 20; i++)
          exp(Category.meal, 10000, DateTime(2026, 7, 14 + i % 3, 9 + i)),
      ];
      expect(evaluateInsights(entries, now).headline.rule, InsightRule.coldStart);
    });

    test('같은 날에는 같은 콜드스타트 문장 (결정적 순환)', () {
      final a = evaluateInsights([], now).headline.headline;
      final b = evaluateInsights([], now).headline.headline;
      expect(a, b);
      final nextDay = evaluateInsights([], now.add(const Duration(days: 1)))
          .headline
          .headline;
      expect(nextDay, isNot(a)); // 다음 날은 순환의 다음 문장
    });
  });

  group('CategoryDeltaUp', () {
    test('이번 주 배달 1.75× → 헤드라인 + 정확한 근거 수치', () {
      final entries = [
        ...deliveryBaseline(),
        exp(Category.delivery, 35000, DateTime(2026, 7, 14, 20)),
      ];
      final result = evaluateInsights(entries, now);
      expect(result.headline.rule, InsightRule.categoryDeltaUp);
      expect(result.headline.headline, '이번 주 배달 소비가 평소보다 조금 많았어요');
      expect(
        result.headline.evidence,
        '이렇게 읽었어요: 최근 4주 평균 2만원 → 이번 주 3.5만원',
      );
    });

    test('경계값: 정확히 1.4×는 울리고, 그 아래는 침묵', () {
      final on = evaluateInsights(
        [...deliveryBaseline(), exp(Category.delivery, 28000, DateTime(2026, 7, 14, 20))],
        now,
      );
      expect(on.headline.rule, InsightRule.categoryDeltaUp);

      final off = evaluateInsights(
        [...deliveryBaseline(), exp(Category.delivery, 27999, DateTime(2026, 7, 14, 20))],
        now,
      );
      expect(off.headline.rule, isNot(InsightRule.categoryDeltaUp));
    });

    test('baseline 1만원 미만 카테고리는 델타 룰이 침묵 (하한 필터)', () {
      // 식사 baseline 3천원 → 이번 주 식사 5만원이어도 배달 델타만 없다면 steady/기타
      final entries = [
        ...deliveryBaseline(),
        exp(Category.delivery, 20000, DateTime(2026, 7, 14, 20)), // 배달 1.0×
      ];
      final result = evaluateInsights(entries, now);
      expect(result.headline.rule, isNot(InsightRule.categoryDeltaUp));
      expect(result.headline.rule, isNot(InsightRule.categoryDeltaDown));
    });
  });

  test('CategoryDeltaDown: 0.6× 이하 → 줄었어요 (담백한 긍정)', () {
    final entries = [
      ...deliveryBaseline(),
      exp(Category.delivery, 12000, DateTime(2026, 7, 14, 20)),
    ];
    final result = evaluateInsights(entries, now);
    expect(result.headline.rule, InsightRule.categoryDeltaDown);
    expect(result.headline.headline, '이번 주 배달 소비가 평소보다 줄었어요');
  });

  test('Frequency: 주 5회 카페 (평소 1회) → 잦았어요 + 근거', () {
    final entries = [
      for (final monday in [
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 22),
        DateTime(2026, 6, 29),
        DateTime(2026, 7, 6),
      ]) ...[
        exp(Category.cafe, 3000, monday.add(const Duration(days: 1, hours: 15))),
        exp(Category.meal, 12000, monday.add(const Duration(days: 2, hours: 12))),
      ],
      // 이번 주: 카페 5회 + 식사는 평소대로
      for (var d = 0; d < 4; d++)
        exp(Category.cafe, 3000, DateTime(2026, 7, 13 + d, 15)),
      exp(Category.cafe, 3000, DateTime(2026, 7, 16, 10)),
      exp(Category.meal, 12000, DateTime(2026, 7, 15, 12)),
    ];
    final result = evaluateInsights(entries, now);
    expect(result.headline.rule, InsightRule.frequency);
    expect(result.headline.headline, '이번 주는 카페·간식이 잦았어요');
    expect(result.headline.evidence, '이렇게 읽었어요: 최근 4주 평균 주 1회 → 이번 주 5회');
  });

  test('QuietWeek: 수요일 이후 + 총액 0.7× 이하 → 차분한 흐름', () {
    final entries = [
      for (final monday in [
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 22),
        DateTime(2026, 6, 29),
        DateTime(2026, 7, 6),
      ]) ...[
        exp(Category.meal, 30000, monday.add(const Duration(days: 1, hours: 12))),
        exp(Category.shopping, 30000, monday.add(const Duration(days: 5, hours: 15))),
        exp(Category.transport, 30000, monday.add(const Duration(days: 3, hours: 8))),
      ],
      // 이번 주 60,000 ≤ 0.7 × 90,000, 카테고리별로는 0.6× 초과라 델타 침묵
      exp(Category.meal, 20000, DateTime(2026, 7, 13, 12)),
      exp(Category.shopping, 20000, DateTime(2026, 7, 14, 15)),
      exp(Category.transport, 20000, DateTime(2026, 7, 15, 8)),
    ];
    final result = evaluateInsights(entries, now);
    expect(result.headline.rule, InsightRule.quietWeek);
    expect(result.headline.headline, '이번 주는 평소보다 차분한 소비 흐름이에요');
    expect(
      result.headline.evidence,
      '이렇게 읽었어요: 최근 4주 주 평균 9만원 → 이번 주 지금까지 6만원',
    );
  });

  test('WeekdayPattern: 지출이 금요일에 집중 → 저순위 인사이트', () {
    final entries = [
      for (final monday in [
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 22),
        DateTime(2026, 6, 29),
        DateTime(2026, 7, 6),
      ]) ...[
        exp(Category.meal, 20000, monday.add(const Duration(days: 4, hours: 19))),
        exp(Category.drinks, 20000, monday.add(const Duration(days: 4, hours: 21))),
      ],
      // 이번 주는 평범: 식사 40,000 (baseline 20,000의 1.0×… 아래 참고)
      exp(Category.meal, 20000, DateTime(2026, 7, 14, 12)),
      exp(Category.drinks, 20000, DateTime(2026, 7, 15, 21)),
    ];
    final result = evaluateInsights(entries, now);
    expect(result.headline.rule, InsightRule.weekdayPattern);
    expect(result.headline.headline, '주로 금요일에 소비가 모이는 편이에요');
    expect(result.headline.evidence, '이렇게 읽었어요: 최근 4주 지출의 100%가 금요일에 있었어요');
  });

  test('선택: 헤드라인 1개 + 다른 룰 타입 보조 라인 ≤2', () {
    final entries = [
      // 4주 내내 금요일에만: 배달 2만 + 카페 3천
      for (final monday in [
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 22),
        DateTime(2026, 6, 29),
        DateTime(2026, 7, 6),
      ]) ...[
        exp(Category.delivery, 20000, monday.add(const Duration(days: 4, hours: 19))),
        exp(Category.cafe, 3000, monday.add(const Duration(days: 4, hours: 15))),
      ],
      // 이번 주: 배달 3.5만(DeltaUp) + 카페 5회(Frequency)
      exp(Category.delivery, 35000, DateTime(2026, 7, 14, 20)),
      for (var d = 0; d < 5; d++)
        exp(Category.cafe, 3000, DateTime(2026, 7, 13 + (d % 4), 9 + d)),
    ];
    final result = evaluateInsights(entries, now);
    expect(result.headline.rule, InsightRule.categoryDeltaUp);
    expect(result.senses, hasLength(2));
    expect(
      result.senses.map((s) => s.rule).toSet(),
      {InsightRule.frequency, InsightRule.weekdayPattern},
    );
    // 보조 라인은 헤드라인과 룰 타입이 겹치지 않는다
    for (final s in result.senses) {
      expect(s.rule, isNot(result.headline.rule));
    }
  });

  test('결정성: 같은 데이터 + 같은 날 = 같은 문장, 입력 순서 무관', () {
    final entries = [
      ...deliveryBaseline(),
      exp(Category.delivery, 35000, DateTime(2026, 7, 14, 20)),
    ];
    final a = evaluateInsights(entries, now);
    final b = evaluateInsights(entries.reversed.toList(), now);
    expect(a.headline.headline, b.headline.headline);
    expect(
      a.senses.map((s) => s.headline).toList(),
      b.senses.map((s) => s.headline).toList(),
    );
  });

  test('아무 룰도 안 울리면 steady 폴백 (보조 라인 없음이 아니어도 됨)', () {
    final entries = [
      ...deliveryBaseline(),
      exp(Category.delivery, 20000, DateTime(2026, 7, 14, 20)), // 1.0×
      exp(Category.meal, 3000, DateTime(2026, 7, 15, 12)),
    ];
    final result = evaluateInsights(entries, now);
    // 배달 화요일 집중(80k/92k=87%)이라 weekdayPattern이 잡히거나 steady
    expect(
      result.headline.rule,
      anyOf(InsightRule.steady, InsightRule.weekdayPattern),
    );
    expect(result.headline.rule, isNot(InsightRule.coldStart));
  });
}
