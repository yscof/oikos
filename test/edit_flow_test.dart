import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';

import 'pump_app.dart';

void main() {
  testWidgets('내역 탭 → 수정 시트 프리필 → 저장 → 반영', (tester) async {
    final original = Entry(
      id: 'e1',
      kind: EntryKind.expense,
      amountWon: 12000,
      category: Category.meal,
      memo: '점심',
      occurredAt: DateTime(2026, 7, 16, 9, 0),
      createdAt: DateTime(2026, 7, 16, 9, 0),
    );
    await pumpApp(tester, entries: [original]);

    await tester.tap(find.byTooltip('내역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('식사'));
    await tester.pumpAndSettle();

    // 기존 값 프리필
    final amountField =
        tester.widget<TextField>(find.byKey(const Key('amount-field')));
    expect(amountField.controller!.text, '12000');
    final memoField =
        tester.widget<TextField>(find.byKey(const Key('memo-field')));
    expect(memoField.controller!.text, '점심');
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '식사'))
          .selected,
      isTrue,
    );

    await tester.enterText(find.byKey(const Key('amount-field')), '15000');
    await tester.tap(find.widgetWithText(ChoiceChip, '배달'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    // 같은 항목이 교체됐다 (추가 아님)
    expect(find.text('배달'), findsOneWidget);
    expect(find.text('15,000원'), findsOneWidget);
    expect(find.text('식사'), findsNothing);
    expect(find.text('12,000원'), findsNothing);
    expect(find.text('7월 · 지출 1만 5천원'), findsOneWidget);
  });

  testWidgets('수정 시트에서 날짜 라벨은 기록의 날짜를 보여준다', (tester) async {
    final old = Entry(
      id: 'e2',
      kind: EntryKind.expense,
      amountWon: 8000,
      category: Category.cafe,
      memo: '',
      occurredAt: DateTime(2026, 7, 3, 15, 0),
      createdAt: DateTime(2026, 7, 3, 15, 0),
    );
    await pumpApp(tester, entries: [old]);

    await tester.tap(find.byTooltip('내역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('카페·간식'));
    await tester.pumpAndSettle();

    expect(find.text('7월 3일'), findsWidgets); // 시트의 날짜 버튼
  });
}
