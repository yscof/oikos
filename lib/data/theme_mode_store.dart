import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/prefs.dart';

/// 화면 모드 저장 키. 'system' | 'light' | 'dark'.
const String themeModeKey = 'oikos_theme_mode_v1';

/// 라이트/다크 화면 모드. 기본은 시스템 설정을 따른다.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(themeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(themeModeKey, mode.name);
  }
}

/// 사용자 노출 라벨.
String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => '시스템 기본',
      ThemeMode.light => '라이트',
      ThemeMode.dark => '다크',
    };
