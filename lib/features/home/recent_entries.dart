import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formats.dart';
import '../../data/entry.dart';
import '../../data/entry_store.dart';
import '../../insight/insight_messages.dart' as msg;

/// 홈에 보여줄 최근 기록 3건.
final recentEntriesProvider = Provider<List<Entry>>((ref) {
  return ref.watch(entryStoreProvider).take(3).toList(growable: false);
});

/// 기록 한 줄. 홈 최근 기록과 내역 타임라인이 공유한다.
/// 지출 금액은 무채색(onSurface) — 빨간색 금지 원칙.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.onTap, this.onLongPress});

  final Entry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIncome = entry.kind == EntryKind.income;
    final amountText =
        isIncome ? '+${won(entry.amountWon)}' : won(entry.amountWon);
    // 감정 라벨 · 메모를 한 줄로 — 둘 다 없으면 부제 없음.
    final subtitleParts = [
      if (entry.emotion != null) entry.emotion!.label,
      if (entry.memo.isNotEmpty) entry.memo,
    ];
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurfaceVariant,
        child: Icon(entry.category.icon, size: 20),
      ),
      title: Text(entry.category.label),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(subtitleParts.join(' · '),
              maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        amountText,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isIncome ? scheme.primary : scheme.onSurface,
            ),
      ),
    );
  }
}

class RecentEntries extends ConsumerWidget {
  const RecentEntries({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentEntriesProvider);
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('최근 기록', style: textTheme.labelLarge?.copyWith(color: muted)),
        const SizedBox(height: 4),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '첫 기록을 남기면 여기에 하나씩 쌓여요',
              style: textTheme.bodyMedium?.copyWith(color: muted),
            ),
          )
        else
          for (final entry in recent) EntryTile(entry: entry),
      ],
    );
  }
}

/// 누적 기록 수를 조용히 되비추는 한 줄. 스트릭·배지가 아니라 데이터 반영.
/// 기록이 하나도 없으면 감춘다.
class RecordCountMurmur extends ConsumerWidget {
  const RecordCountMurmur({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(entryStoreProvider).length;
    if (count == 0) return const SizedBox.shrink();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Text(
        msg.recordCountMurmur(count),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: muted),
      ),
    );
  }
}
