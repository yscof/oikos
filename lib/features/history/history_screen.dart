import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/formats.dart';
import '../../data/entry.dart';
import '../../data/entry_store.dart';
import '../home/recent_entries.dart' show EntryTile;
import '../record/record_sheet.dart';

/// 날짜 그룹 타임라인. 의미(인사이트)는 홈에, 여기는 사실만.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Entry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 기록을 삭제할까요?'),
        content: Text('${entry.category.label} · ${won(entry.amountWon)}'),
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
      await ref.read(entryStoreProvider.notifier).remove(entry.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entryStoreProvider);
    final now = ref.watch(clockProvider)();
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    if (entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('내역')),
        body: Center(
          child: Text(
            '아직 기록이 없어요',
            style: textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ),
      );
    }

    // 월별 지출 합계 (월 구분선용)
    final monthExpense = <(int, int), int>{};
    for (final e in entries) {
      if (e.kind != EntryKind.expense) continue;
      final key = (e.occurredAt.year, e.occurredAt.month);
      monthExpense[key] = (monthExpense[key] ?? 0) + e.amountWon;
    }

    // entries는 최신순 정렬 불변식이 있으므로 순회하며 헤더를 끼워 넣는다.
    final children = <Widget>[];
    (int, int)? currentMonth;
    DateTime? currentDay;
    for (final e in entries) {
      final month = (e.occurredAt.year, e.occurredAt.month);
      if (month != currentMonth) {
        currentMonth = month;
        currentDay = null;
        final yearPrefix = month.$1 == now.year ? '' : '${month.$1}년 ';
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 4),
            child: Text(
              '$yearPrefix${month.$2}월 · 지출 ${wonCompact(monthExpense[month] ?? 0)}',
              style: textTheme.labelLarge?.copyWith(color: muted),
            ),
          ),
        );
      }
      final day = DateTime(
        e.occurredAt.year,
        e.occurredAt.month,
        e.occurredAt.day,
      );
      if (day != currentDay) {
        currentDay = day;
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 2),
            child: Text(
              dayLabel(day, now),
              style: textTheme.titleSmall?.copyWith(color: muted),
            ),
          ),
        );
      }
      children.add(
        EntryTile(
          entry: e,
          onTap: () => showRecordSheet(context, editing: e),
          onLongPress: () => _confirmDelete(context, ref, e),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('내역')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: children,
      ),
    );
  }
}
