import 'package:flutter/material.dart';

/// M2 플레이스홀더 — M5에서 내보내기/삭제/라이선스/버전이 들어온다.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Center(
        child: Text(
          '모든 데이터는 이 기기에만 저장됩니다',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ),
    );
  }
}
