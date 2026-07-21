import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('기록 플로: 시트 → 금액 입력 → 저장 → 홈 반영', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();

    // 금액이 없으면 저장 비활성
    final saveButton = find.widgetWithText(FilledButton, '저장');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('amount-field')), '12000');
    await tester.pump();

    // 첫 카테고리(식사)가 기본 선택되어 있다 — 해피패스 = 입력 2번
    final mealChip =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '식사'));
    expect(mealChip.selected, isTrue);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // 시트가 조용히 닫히고 홈 최근 기록에 반영
    expect(find.byKey(const Key('amount-field')), findsNothing);
    expect(find.text('식사'), findsOneWidget);
    expect(find.text('12,000원'), findsOneWidget);
  });

  testWidgets('수입 전환 시 수입 카테고리로 바뀐다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('수입'));
    await tester.pump();

    expect(find.widgetWithText(ChoiceChip, '월급'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '식사'), findsNothing);
  });

  testWidgets('내역 반영과 롱프레스 삭제', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount-field')), '8500');
    await tester.tap(find.widgetWithText(ChoiceChip, '카페·간식'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('내역'));
    await tester.pumpAndSettle();

    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('카페·간식'), findsOneWidget);
    expect(find.text('7월 · 지출 8,500원'), findsOneWidget);

    await tester.longPress(find.text('카페·간식'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('아직 기록이 없어요'), findsOneWidget);
  });

  testWidgets('감정 태그(선택)를 남기면 기록에 함께 보인다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount-field')), '9000');
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '아쉬움'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    // 시트가 닫힌 뒤 홈 최근 기록의 부제로 감정이 보인다.
    expect(find.text('아쉬움'), findsOneWidget);
  });

  testWidgets('금액 입력에 천 단위 콤마가 실시간으로 붙는다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount-field')), '1500000');
    await tester.pump();
    expect(find.text('1,500,000'), findsOneWidget); // 입력 필드 표시

    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    expect(find.text('1,500,000원'), findsOneWidget); // 저장된 금액
  });

  testWidgets('수입에는 감정 칩이 없다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, '아쉬움'), findsOneWidget);
    await tester.tap(find.text('수입'));
    await tester.pump();
    expect(find.widgetWithText(ChoiceChip, '아쉬움'), findsNothing);
  });
}
