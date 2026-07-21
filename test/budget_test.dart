import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/core/prefs.dart';
import 'package:oikos/data/budget_store.dart';
import 'package:oikos/data/entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pump_app.dart';

Entry _e(int won) => Entry(
      id: 'e$won',
      kind: EntryKind.expense,
      amountWon: won,
      category: Category.meal,
      memo: '',
      occurredAt: testNow,
      createdAt: testNow,
    );

void main() {
  test('예산 저장 왕복', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c1 = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c1.dispose);
    await c1.read(monthBudgetProvider.notifier).set(500000);

    final c2 = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c2.dispose);
    expect(c2.read(monthBudgetProvider), 500000);
  });

  testWidgets('예산 미설정이면 홈에 예산 현황을 감춘다', (tester) async {
    await pumpApp(tester, entries: [_e(30000)]);
    expect(find.text('이번 달 예산'), findsNothing);
  });

  testWidgets('예산 설정 시 진행률과 사용액을 보여준다', (tester) async {
    await pumpApp(tester,
        entries: [_e(60000)], extraPrefs: {monthBudgetKey: 300000});

    expect(find.text('이번 달 예산'), findsOneWidget);
    expect(find.text('6만원 / 30만원'), findsOneWidget);
  });

  testWidgets('80% 넘으면 담백한 인앱 알림', (tester) async {
    await pumpApp(tester,
        entries: [_e(90000)], extraPrefs: {monthBudgetKey: 100000});
    expect(find.text('예산의 90%를 지났어요'), findsOneWidget);
  });

  testWidgets('100% 넘으면 초과 알림', (tester) async {
    await pumpApp(tester,
        entries: [_e(60000)], extraPrefs: {monthBudgetKey: 50000});
    expect(find.text('이번 달 예산을 넘었어요'), findsOneWidget);
  });
}
