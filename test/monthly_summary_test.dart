import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';

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
    expect(find.text('5만원'), findsOneWidget); // 지출 30000+20000
    expect(find.text('295만원'), findsOneWidget); // 남은 300만-5만
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
}
