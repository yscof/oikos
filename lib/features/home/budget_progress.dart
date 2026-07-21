import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formats.dart';
import '../../data/budget_store.dart';
import '../../insight/insight_engine.dart';

/// 이번 달 예산 대비 지출 현황(FR-502) + 80%/100% 인앱 알림(FR-504).
/// 예산이 0(미설정)이면 감춘다. 편안함 원칙 — 초과해도 빨간 경보 대신 담백한 톤.
class BudgetProgress extends ConsumerWidget {
  const BudgetProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(monthBudgetProvider);
    if (budget <= 0) return const SizedBox.shrink();
    final spent = ref.watch(monthExpenseWonProvider);

    final ratio = spent / budget;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    // 초과 시에도 알람 레드 대신 tertiary(차분한 강조)로.
    final barColor = ratio >= 1.0 ? scheme.tertiary : scheme.primary;

    String? note;
    if (ratio >= 1.0) {
      note = '이번 달 예산을 넘었어요';
    } else if (ratio >= 0.8) {
      note = '예산의 ${(ratio * 100).floor()}%를 지났어요';
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('이번 달 예산',
                  style: textTheme.labelLarge?.copyWith(color: muted)),
              Text('${wonCompact(spent)} / ${wonCompact(budget)}',
                  style: textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(note, style: textTheme.bodyMedium?.copyWith(color: muted)),
          ],
        ],
      ),
    );
  }
}
