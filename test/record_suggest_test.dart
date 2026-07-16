import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

String firstChipLabel(WidgetTester tester) {
  final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip).first);
  return (chip.label as Text).data!;
}

bool chipSelected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;

void main() {
  testWidgets('금액대가 바뀌면 칩이 재정렬되고 추천 1위가 자동 선택된다', (tester) async {
    await pumpApp(tester); // 목요일 12:30
    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount-field')), '12000');
    await tester.pump();
    expect(firstChipLabel(tester), '식사');
    expect(chipSelected(tester, '식사'), isTrue);

    // 15만원 초과 → 주거·통신이 1위로
    await tester.enterText(find.byKey(const Key('amount-field')), '300000');
    await tester.pump();
    expect(firstChipLabel(tester), '주거·통신');
    expect(chipSelected(tester, '주거·통신'), isTrue);
    expect(chipSelected(tester, '식사'), isFalse);
  });

  testWidgets('사용자가 고른 칩은 재정렬 후에도 유지된다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount-field')), '12000');
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '문화·여가'));
    await tester.pump();
    expect(chipSelected(tester, '문화·여가'), isTrue);

    await tester.enterText(find.byKey(const Key('amount-field')), '300000');
    await tester.pump();
    expect(chipSelected(tester, '문화·여가'), isTrue);
    expect(chipSelected(tester, '주거·통신'), isFalse);
  });
}
