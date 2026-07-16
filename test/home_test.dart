import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('빈 상태 홈: 콜드스타트 문장 + 빈 최근 기록 + 기록 버튼', (tester) async {
    await pumpApp(tester);

    expect(find.text('기록이 쌓이면 소비의 흐름을 읽어드릴게요'), findsOneWidget);
    expect(find.text('아직 기록이 없어요'), findsOneWidget);
    expect(find.text('기록하기'), findsOneWidget);
    expect(find.text('7월 16일 목요일'), findsOneWidget);
  });

  testWidgets('설정으로 이동', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
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
