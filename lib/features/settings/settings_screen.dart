import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entry_store.dart';

/// pubspec.yaml의 version과 함께 올린다.
const String appVersion = '0.1.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _exportToClipboard(BuildContext context, WidgetRef ref) async {
    final entries = ref.read(entryStoreProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (entries.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('아직 내보낼 기록이 없어요')),
      );
      return;
    }
    final json = const JsonEncoder.withIndent('  ')
        .convert([for (final e in entries) e.toJson()]);
    await Clipboard.setData(ClipboardData(text: json));
    messenger.showSnackBar(
      SnackBar(content: Text('기록 ${entries.length}건을 클립보드에 복사했어요')),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 기록을 삭제할까요?'),
        content: const Text('되돌릴 수 없어요. 필요하면 먼저 내보내기로 남겨둘 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(entryStoreProvider.notifier).clearAll();
      messenger.showSnackBar(
        const SnackBar(content: Text('모든 기록을 삭제했어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: const Text('데이터 내보내기'),
            subtitle: const Text('모든 기록을 JSON으로 클립보드에 복사'),
            onTap: () => _exportToClipboard(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('모든 데이터 삭제'),
            onTap: () => _confirmClearAll(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('오픈소스 라이선스'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: '오이코스',
              applicationVersion: appVersion,
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('버전'),
            trailing: Text(appVersion),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '모든 데이터는 이 기기에만 저장됩니다',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
