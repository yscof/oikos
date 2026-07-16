import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/core/prefs.dart';
import 'package:oikos/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('앱이 뜨고 홈이 렌더링된다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const OikosApp(),
      ),
    );

    expect(find.text('오이코스'), findsOneWidget);
  });
}
