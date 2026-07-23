import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';
import 'package:oikos/insight/insight_engine.dart';

import 'pump_app.dart';

Entry _expense(int won, {DateTime? at}) {
  final when = at ?? testNow;
  return Entry(
    id: 'e${when.microsecondsSinceEpoch}$won',
    kind: EntryKind.expense,
    amountWon: won,
    category: Category.meal,
    memo: '',
    occurredAt: when,
    createdAt: when,
  );
}

void main() {
  testWidgets('빈 상태 홈: 콜드스타트 문장 + 빈 최근 기록 + 기록 버튼', (tester) async {
    await pumpApp(tester);

    final coldStart = evaluateInsights([], testNow).headline.headline;
    expect(find.text(coldStart), findsOneWidget);
    expect(find.text('첫 기록을 남기면 여기에 하나씩 쌓여요'), findsOneWidget);
    expect(find.text('기록하기'), findsOneWidget);
    expect(find.text('7월 16일 목요일'), findsOneWidget);
    // 첫 화면엔 차가운 '0원' 소문을 띄우지 않는다.
    expect(find.text('이번 주 지출 0원'), findsNothing);
  });

  testWidgets('오늘 지출이 있으면 오늘 소문을 먼저 보여준다', (tester) async {
    await pumpApp(tester, entries: [
      _expense(23000), // 오늘
      _expense(40000, at: testNow.subtract(const Duration(days: 2))), // 이번 주, 오늘 아님
    ]);

    expect(find.text('오늘 지출 23,000원'), findsOneWidget);
    expect(find.text('이번 주 지출 63,000원'), findsOneWidget);
  });

  testWidgets('오늘 지출이 없으면 오늘 소문은 감춘다', (tester) async {
    await pumpApp(tester, entries: [
      _expense(40000, at: testNow.subtract(const Duration(days: 2))),
    ]);

    expect(find.textContaining('오늘 지출'), findsNothing);
    expect(find.text('이번 주 지출 40,000원'), findsOneWidget);
  });

  testWidgets('누적 기록 수를 조용히 되비춘다', (tester) async {
    await pumpApp(tester, entries: [
      _expense(1000),
      _expense(2000),
      _expense(3000),
    ]);
    // 월 요약·최근 기록 아래라 뷰포트 밖일 수 있어 스크롤해서 확인.
    await tester.scrollUntilVisible(
      find.text('지금까지 3번 기록했어요'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('지금까지 3번 기록했어요'), findsOneWidget);
  });

  testWidgets('기록이 없으면 누적 기록 줄은 감춘다', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('지금까지'), findsNothing);
  });

  testWidgets('설정으로 이동', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    expect(find.text('모든 데이터는 이 기기에만 저장됩니다'), findsOneWidget);
  });

  testWidgets('내역으로 이동 — 빈 상태', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('내역'));
    await tester.pumpAndSettle();
    expect(find.text('내역'), findsOneWidget);
    expect(find.text('아직 기록이 없어요'), findsOneWidget);
  });
}
