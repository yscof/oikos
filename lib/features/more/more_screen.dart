import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/theme_mode_store.dart';

/// 더보기 탭 — 화면 모드, 설정 등 부가 메뉴 모음.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _pickThemeMode(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                '화면 모드',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final mode in ThemeMode.values)
              ListTile(
                title: Text(themeModeLabel(mode)),
                trailing: mode == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(mode),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(themeModeProvider.notifier).set(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('더보기')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('화면 모드'),
            subtitle: Text(themeModeLabel(mode)),
            onTap: () => _pickThemeMode(context, ref, mode),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('설정'),
            subtitle: const Text('가계부 시작일, 예산, 데이터 관리'),
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}
