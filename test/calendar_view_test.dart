import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';

import 'pump_app.dart';

Entry _e(int won, DateTime at, {EntryKind kind = EntryKind.expense}) => Entry(
      id: 'e${at.day}$won',
      kind: kind,
      amountWon: won,
      category: kind == EntryKind.income ? Category.salary : Category.meal,
      memo: '',
      occurredAt: at,
      createdAt: at,
    );

void main() {
  // 캘린더 그리드 + 날짜 요약이 한 화면에 들어오도록 세로로 큰 창.
  void tallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('내역에서 캘린더로 토글하고 선택한 날 요약을 본다', (tester) async {
    tallSurface(tester);
    await pumpApp(tester, entries: [
      _e(12000, DateTime(2026, 7, 16, 12)), // 오늘(testNow)
      _e(5000, DateTime(2026, 7, 10, 9)),
    ]);

    await tester.tap(find.byTooltip('내역'));
    await tester.pumpAndSettle();

    // 캘린더 보기로 전환
    await tester.tap(find.byTooltip('캘린더 보기'));
    await tester.pumpAndSettle();

    expect(find.text('2026년 7월'), findsOneWidget);
    // 기본 선택일 = 오늘 → 그날 지출 요약
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('지출 1만 2천원'), findsOneWidget);

    // 10일을 고르면 그날 요약으로 바뀐다
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('지출 5,000원'), findsOneWidget);
  });

  testWidgets('기록 없는 날은 안내 문구', (tester) async {
    tallSurface(tester);
    await pumpApp(tester, entries: [
      _e(12000, DateTime(2026, 7, 16, 12)),
    ]);
    await tester.tap(find.byTooltip('내역'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('캘린더 보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5')); // 기록 없는 날
    await tester.pumpAndSettle();
    expect(find.text('이 날은 기록이 없어요'), findsOneWidget);
  });
}
