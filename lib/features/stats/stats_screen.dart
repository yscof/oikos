import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/formats.dart';
import '../../core/month.dart';
import '../../data/entry.dart';
import '../../data/entry_store.dart';
import '../../data/month_start_store.dart';

/// 통계(FR-404) — 이번 달 카테고리별 지출 비율을 가로 막대로.
/// 차트 패키지 없이 순수 위젯. 빨간색 없이 세이지 그린 강조만.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entryStoreProvider);
    final now = ref.watch(clockProvider)();
    final startDay = ref.watch(monthStartDayProvider);
    final range = financialMonthRange(now, startDay);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    final byCategory = <Category, int>{};
    var total = 0;
    for (final e in entries) {
      if (e.kind != EntryKind.expense) continue;
      if (e.occurredAt.isBefore(range.start) ||
          !e.occurredAt.isBefore(range.end)) {
        continue;
      }
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amountWon;
      total += e.amountWon;
    }

    final rows = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = rows.isEmpty ? 1 : rows.first.value;

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: total == 0
          ? Center(
              child: Text(
                '이번 달 지출 기록이 없어요',
                style: textTheme.bodyMedium?.copyWith(color: muted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text('이번 달 지출 ${won(total)}',
                    style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('카테고리별 비율', style: textTheme.labelLarge?.copyWith(color: muted)),
                const SizedBox(height: 12),
                for (final row in rows)
                  _CategoryBar(
                    category: row.key,
                    amount: row.value,
                    percent: (row.value / total * 100).round(),
                    widthFactor: row.value / maxValue,
                  ),
              ],
            ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.percent,
    required this.widthFactor,
  });

  final Category category;
  final int amount;
  final int percent;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(category.label, style: textTheme.bodyMedium),
              const Spacer(),
              Text('$percent%',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              Text(won(amount), style: textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              color: scheme.surfaceContainerHighest,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widthFactor.clamp(0.02, 1.0),
                child: Container(color: scheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
