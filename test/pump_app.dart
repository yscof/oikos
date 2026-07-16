import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/core/clock.dart';
import 'package:oikos/core/prefs.dart';
import 'package:oikos/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-07-16(목) 12:30 — 위젯 테스트 공용 고정 시계.
final testNow = DateTime(2026, 7, 16, 12, 30);

/// 빈 mock prefs + 고정 시계로 앱 전체를 띄운다.
Future<void> pumpApp(WidgetTester tester, {DateTime? now}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now ?? testNow),
      ],
      child: const OikosApp(),
    ),
  );
}
