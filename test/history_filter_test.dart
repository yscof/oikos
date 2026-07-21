import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';

import 'pump_app.dart';

Entry _e(int won, Category c, {String memo = ''}) => Entry(
      id: 'e$won${c.name}',
      kind: EntryKind.expense,
      amountWon: won,
      category: c,
      memo: memo,
      occurredAt: testNow,
      createdAt: testNow,
    );

Future<void> _openHistory(WidgetTester tester) async {
  await tester.tap(find.byTooltip('내역'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('키워드 검색: 메모/카테고리로 거른다', (tester) async {
    await pumpApp(tester, entries: [
      _e(12000, Category.meal, memo: '회사 근처 국밥'),
      _e(5000, Category.cafe, memo: '아메리카노'),
    ]);
    await _openHistory(tester);

    expect(find.text('식사'), findsOneWidget);
    expect(find.text('카페·간식'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('history-search')), '국밥');
    await tester.pumpAndSettle();

    expect(find.text('식사'), findsOneWidget);
    expect(find.text('카페·간식'), findsNothing);
  });

  testWidgets('검색 결과가 없으면 안내 문구', (tester) async {
    await pumpApp(tester, entries: [_e(12000, Category.meal, memo: '국밥')]);
    await _openHistory(tester);

    await tester.enterText(find.byKey(const Key('history-search')), '없는단어');
    await tester.pumpAndSettle();

    expect(find.text('조건에 맞는 기록이 없어요'), findsOneWidget);
  });

  testWidgets('카테고리 필터로 거른다', (tester) async {
    await pumpApp(tester, entries: [
      _e(12000, Category.meal),
      _e(5000, Category.cafe),
    ]);
    await _openHistory(tester);

    await tester.tap(find.byType(DropdownButton<Category?>));
    await tester.pumpAndSettle();
    // 드롭다운 메뉴의 '카페·간식' 항목(마지막)을 고른다.
    await tester.tap(find.text('카페·간식').last);
    await tester.pumpAndSettle();

    // 선택 후엔 드롭다운 버튼에도 라벨이 떠서 금액으로 확인한다.
    expect(find.text('5,000원'), findsOneWidget); // 카페 타일만 남음
    expect(find.text('12,000원'), findsNothing); // 식사 걸러짐
    expect(find.text('식사'), findsNothing);
  });
}
