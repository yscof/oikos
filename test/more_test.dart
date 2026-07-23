import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/theme_mode_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pump_app.dart';

void main() {
  testWidgets('하단 탭은 가계부·통계·더보기 순서, 첫 화면은 가계부', (tester) async {
    await pumpApp(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final labels = [
      for (final d in bar.destinations) (d as NavigationDestination).label,
    ];
    expect(labels, ['가계부', '통계', '더보기']);
    expect(bar.selectedIndex, 0);
    expect(find.text('기록하기'), findsOneWidget);
  });

  testWidgets('더보기 → 설정 항목이 있다', (tester) async {
    await pumpApp(tester);
    await openTab(tester, '더보기');

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('화면 모드'), findsOneWidget);
  });

  testWidgets('화면 모드: 다크 선택 → 적용되고 저장된다', (tester) async {
    await pumpApp(tester);
    await openTab(tester, '더보기');

    await tester.tap(find.text('화면 모드'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    // 타일 subtitle이 현재 모드를 보여준다.
    expect(find.text('다크'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(themeModeKey), 'dark');
  });

  testWidgets('저장된 화면 모드로 시작한다', (tester) async {
    await pumpApp(tester, extraPrefs: {themeModeKey: 'light'});
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });
}
