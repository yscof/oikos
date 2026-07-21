import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../insight/insight.dart';
import '../../insight/insight_engine.dart';
import '../../insight/insight_messages.dart' as msg;

/// 홈 헤드라인 = 날씨앱의 날씨 한 문장. 탭하면 『이렇게 읽었어요』 근거 시트.
/// 차트 없음 — 문장이 차트를 대체한다.
class InsightCard extends ConsumerWidget {
  const InsightCard({super.key});

  void _showEvidence(BuildContext context, Insight insight) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.evidence!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(insightResultProvider);
    final todayWon = ref.watch(todayExpenseWonProvider);
    final weekWon = ref.watch(weekExpenseWonProvider);
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final headline = result.headline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: headline.evidence == null
              ? null
              : () => _showEvidence(context, headline),
          borderRadius: BorderRadius.circular(8),
          child: Text(
            headline.headline,
            style: textTheme.headlineSmall?.copyWith(height: 1.4),
          ),
        ),
        for (final sense in result.senses)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: InkWell(
              onTap: sense.evidence == null
                  ? null
                  : () => _showEvidence(context, sense),
              borderRadius: BorderRadius.circular(8),
              child: Text(
                sense.headline,
                style: textTheme.bodyLarge?.copyWith(color: muted),
              ),
            ),
          ),
        // 지출이 있을 때만 소문을 띄운다 — 첫 화면의 '0원'은 보여주지 않는다.
        // 오늘을 먼저, 이번 주는 그 아래. 습관의 단위는 '하루'다. 차트 아님.
        if (weekWon > 0) ...[
          const SizedBox(height: 20),
          if (todayWon > 0) ...[
            Text(msg.todayMurmur(todayWon), style: textTheme.bodyLarge),
            const SizedBox(height: 4),
          ],
          Text(
            msg.weekMurmur(weekWon),
            style: textTheme.labelLarge?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }
}
