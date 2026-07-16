import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/formats.dart';
import '../record/record_sheet.dart';
import 'insight_card.dart';
import 'recent_entries.dart';

/// 홈 = 인사이트 공간. 거래내역 표가 아니라 "내 금융 상태" 한 문장이 주인공.
/// 포인트/배지/스트릭 없음.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '${now.month}월 ${now.day}일 ${weekdayKo(now)}요일',
                    style: textTheme.labelLarge?.copyWith(color: muted),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '내역',
                    icon: const Icon(Icons.receipt_long_outlined),
                    onPressed: () => context.push('/history'),
                  ),
                  IconButton(
                    tooltip: '설정',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 24),
                    const InsightCard(),
                    const SizedBox(height: 36),
                    const RecentEntries(),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => showRecordSheet(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('기록하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
