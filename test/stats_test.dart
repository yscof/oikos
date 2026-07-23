import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';

import 'pump_app.dart';

Entry _e(int won, Category c) => Entry(
      id: 'e$won${c.name}',
      kind: EntryKind.expense,
      amountWon: won,
      category: c,
      memo: '',
      occurredAt: testNow,
      createdAt: testNow,
    );

void main() {
  testWidgets('통계: 카테고리별 지출 비율을 보여준다', (tester) async {
    await pumpApp(tester, entries: [
      _e(60000, Category.meal), // 60%
      _e(40000, Category.cafe), // 40%
    ]);

    await openTab(tester, '통계');

    expect(find.text('이번 달 지출 100,000원'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('식사'), findsOneWidget);
    expect(find.text('카페·간식'), findsOneWidget);
  });

  testWidgets('통계: 지출이 없으면 안내 문구', (tester) async {
    await pumpApp(tester);
    await openTab(tester, '통계');
    expect(find.text('이번 달 지출 기록이 없어요'), findsOneWidget);
  });
}
