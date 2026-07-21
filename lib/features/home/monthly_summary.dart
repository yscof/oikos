import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/formats.dart';
import '../../data/month_start_store.dart';
import '../../insight/insight_engine.dart';

/// 홈의 이번 달 요약 — 지출/수입/남은 금액 (FR-403). 차트 아님, 무채색.
/// 수입을 기록하지 않는 사용자가 많으므로 수입이 0이면 지출만 담백하게 보여준다.
/// 이번 달 활동이 전혀 없으면 감춘다(첫 화면의 '0원' 방지).
class MonthlySummary extends ConsumerWidget {
  const MonthlySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expense = ref.watch(monthExpenseWonProvider);
    final income = ref.watch(monthIncomeWonProvider);
    final now = ref.watch(clockProvider)();
    final startDay = ref.watch(monthStartDayProvider);
    if (expense == 0 && income == 0) return const SizedBox.shrink();

    // 시작일이 1일이면 달력 월(‘7월’), 아니면 정산월이라 ‘이번 달’로 담백하게.
    final periodLabel = startDay == 1 ? '${now.month}월' : '이번 달';

    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget stat(String label, int amount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          // 남은 금액이 마이너스여도 빨간색을 쓰지 않는다 — 편안함이 기본값.
          Text(wonCompact(amount), style: textTheme.titleMedium),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodLabel,
            style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          if (income == 0)
            stat('지출', expense)
          else
            Row(
              children: [
                Expanded(child: stat('지출', expense)),
                Expanded(child: stat('수입', income)),
                Expanded(child: stat('남은 금액', income - expense)),
              ],
            ),
        ],
      ),
    );
  }
}
