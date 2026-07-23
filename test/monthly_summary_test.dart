import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/core/clock.dart';
import 'package:oikos/core/prefs.dart';
import 'package:oikos/data/entry.dart';
import 'package:oikos/data/entry_store.dart';
import 'package:oikos/data/month_start_store.dart';
import 'package:oikos/insight/insight_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pump_app.dart';

Entry _e(EntryKind kind, int won, Category c) => Entry(
      id: 'e$won',
      kind: kind,
      amountWon: won,
      category: c,
      memo: '',
      occurredAt: testNow, // 2026-07-16
      createdAt: testNow,
    );

void main() {
  testWidgets('수입이 있으면 이번 달 지출/수입/남은 금액을 보여준다', (tester) async {
    await pumpApp(tester, entries: [
      _e(EntryKind.expense, 30000, Category.meal),
      _e(EntryKind.expense, 20000, Category.cafe),
      _e(EntryKind.income, 3000000, Category.salary),
    ]);

    expect(find.text('7월'), findsOneWidget);
    expect(find.text('지출'), findsOneWidget);
    expect(find.text('수입'), findsOneWidget);
    expect(find.text('남은 금액'), findsOneWidget);
    expect(find.text('50,000원'), findsOneWidget); // 지출 30000+20000
    expect(find.text('2,950,000원'), findsOneWidget); // 남은 300만-5만
  });

  testWidgets('수입이 없으면 지출만 담백하게', (tester) async {
    await pumpApp(tester, entries: [
      _e(EntryKind.expense, 50000, Category.meal),
    ]);

    expect(find.text('지출'), findsOneWidget);
    expect(find.text('수입'), findsNothing);
    expect(find.text('남은 금액'), findsNothing);
  });

  testWidgets('이번 달 활동이 없으면 요약을 감춘다', (tester) async {
    await pumpApp(tester);
    expect(find.text('지출'), findsNothing);
    expect(find.text('남은 금액'), findsNothing);
  });

  test('시작일을 25일로 두면 정산월 합계가 달라진다 (FR-601)', () async {
    SharedPreferences.setMockInitialValues({monthStartDayKey: 25});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => DateTime(2026, 7, 28)),
    ]);
    addTearDown(container.dispose);

    // 7/24 지출은 지난 정산월, 7/26 지출은 이번 정산월(7/25~8/25)
    await container.read(entryStoreProvider.notifier).add(_e(
          EntryKind.expense,
          10000,
          Category.meal,
        ).copyWith(occurredAt: DateTime(2026, 7, 24)));
    await container.read(entryStoreProvider.notifier).add(_e(
          EntryKind.expense,
          30000,
          Category.meal,
        ).copyWith(occurredAt: DateTime(2026, 7, 26)));

    expect(container.read(monthExpenseWonProvider), 30000);
  });
}
