import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('앱이 뜨고 홈이 렌더링된다', (tester) async {
    await pumpApp(tester);
    expect(find.text('기록하기'), findsOneWidget);
  });
}
