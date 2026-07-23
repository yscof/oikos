import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/core/clock.dart';
import 'package:oikos/core/prefs.dart';
import 'package:oikos/data/entry.dart';
import 'package:oikos/data/entry_store.dart';
import 'package:oikos/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-07-16(목) 12:30 — 위젯 테스트 공용 고정 시계.
final testNow = DateTime(2026, 7, 16, 12, 30);

/// mock prefs(+선주입 기록) + 고정 시계로 앱 전체를 띄운다.
Future<void> pumpApp(
  WidgetTester tester, {
  DateTime? now,
  List<Entry>? entries,
  Map<String, Object>? extraPrefs,
}) async {
  SharedPreferences.setMockInitialValues({
    if (entries != null)
      entriesPrefsKey: jsonEncode([for (final e in entries) e.toJson()]),
    ...?extraPrefs,
  });
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

/// 하단 탭(가계부/통계/더보기)으로 이동한다.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}

/// 더보기 탭을 거쳐 설정 화면을 연다.
Future<void> openSettings(WidgetTester tester) async {
  await openTab(tester, '더보기');
  await tester.tap(find.text('설정'));
  await tester.pumpAndSettle();
}
