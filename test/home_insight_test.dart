import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';
import 'package:oikos/insight/insight_engine.dart';

import 'pump_app.dart';

Entry exp(Category c, int amount, DateTime at) => Entry(
      id: '${c.name}-${at.microsecondsSinceEpoch}',
      kind: EntryKind.expense,
      amountWon: amount,
      category: c,
      memo: '',
      occurredAt: at,
      createdAt: at,
    );

List<Entry> deliveryHeavyHistory() => [
      for (final monday in [
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 22),
        DateTime(2026, 6, 29),
        DateTime(2026, 7, 6),
      ]) ...[
        exp(Category.delivery, 20000,
            monday.add(const Duration(days: 1, hours: 19))),
        exp(Category.meal, 3000, monday.add(const Duration(days: 2, hours: 12))),
      ],
      exp(Category.delivery, 35000, DateTime(2026, 7, 14, 20)),
    ];

void main() {
  testWidgets('홈 헤드라인: 인사이트 문장 + 탭하면 근거 시트', (tester) async {
    await pumpApp(tester, entries: deliveryHeavyHistory());

    const headline = '이번 주 배달 소비가 평소보다 조금 많았어요';
    expect(find.text(headline), findsOneWidget);
    expect(find.text('이번 주 지출 3만 5천원'), findsOneWidget); // 무채색 소문

    await tester.tap(find.text(headline));
    await tester.pumpAndSettle();
    expect(
      find.text('이렇게 읽었어요: 최근 4주 평균 2만원 → 이번 주 3.5만원'),
      findsOneWidget,
    );
  });

  testWidgets('콜드스타트: 그날의 순환 문장이 헤드라인', (tester) async {
    await pumpApp(tester);
    final expected = evaluateInsights([], testNow).headline.headline;
    expect(find.text(expected), findsOneWidget);
    expect(find.text('이번 주 지출 0원'), findsOneWidget);
  });
}
