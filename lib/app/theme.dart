import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// 오이코스 시드 컬러 — 차분한 세이지 그린. "편안함이 기본값" 원칙.
/// 지출 금액에 빨간색을 쓰지 않는다.
const Color oikosSeed = Color(0xFF5E7A66);

ThemeData oikosTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: oikosSeed,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    // 전 플랫폼에 Cupertino 전환 — 홈/내역/설정 사이 이동이 부드럽도록.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
