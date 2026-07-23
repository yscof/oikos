import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/formats.dart';
import '../../data/entry.dart';
import '../../data/entry_store.dart';
import '../home/recent_entries.dart' show EntryTile;
import '../record/record_sheet.dart';

/// 캘린더 뷰(FR-402) — 외부 패키지 없이 가벼운 월 그리드.
/// 지출이 있는 날엔 점을 찍고, 날짜를 고르면 그날의 지출/수입 요약과 기록을 편다.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _focusedMonth; // 그 달 1일
  late DateTime _selectedDay;
  bool _init = false;

  void _shiftMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entryStoreProvider);
    final now = ref.watch(clockProvider)();
    if (!_init) {
      _focusedMonth = DateTime(now.year, now.month);
      _selectedDay = DateTime(now.year, now.month, now.day);
      _init = true;
    }
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // 이 달 각 날짜의 지출 합계 (점 표시용)
    final dayExpense = <int, int>{};
    for (final e in entries) {
      if (e.kind != EntryKind.expense) continue;
      if (e.occurredAt.year != _focusedMonth.year ||
          e.occurredAt.month != _focusedMonth.month) {
        continue;
      }
      dayExpense[e.occurredAt.day] = (dayExpense[e.occurredAt.day] ?? 0) + e.amountWon;
    }

    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingBlanks = _focusedMonth.weekday - 1; // 월요일 시작
    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final isSelected = date == _selectedDay;
      final hasSpending = (dayExpense[d] ?? 0) > 0;
      cells.add(
        InkWell(
          onTap: () => setState(() => _selectedDay = date),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: isSelected
                    ? BoxDecoration(color: scheme.primary, shape: BoxShape.circle)
                    : null,
                child: Text(
                  '$d',
                  style: textTheme.bodyMedium?.copyWith(
                    color: isSelected ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: hasSpending ? scheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shiftMonth(-1),
            ),
            Text(
              '${_focusedMonth.year}년 ${_focusedMonth.month}월',
              style: textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _shiftMonth(1),
            ),
          ],
        ),
        Row(
          children: [
            for (final w in weekdaysKo)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.72,
          children: cells,
        ),
        const Divider(height: 32),
        _DaySummary(day: _selectedDay),
      ],
    );
  }
}

/// 선택한 날짜의 지출/수입 요약과 기록 목록.
class _DaySummary extends ConsumerWidget {
  const _DaySummary({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final entries = ref.watch(entryStoreProvider).where((e) {
      return e.occurredAt.year == day.year &&
          e.occurredAt.month == day.month &&
          e.occurredAt.day == day.day;
    }).toList(growable: false);

    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    var expense = 0;
    var income = 0;
    for (final e in entries) {
      if (e.kind == EntryKind.expense) {
        expense += e.amountWon;
      } else {
        income += e.amountWon;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dayLabel(day, now), style: textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          income > 0
              ? '지출 ${won(expense)} · 수입 ${won(income)}'
              : '지출 ${won(expense)}',
          style: textTheme.labelLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '이 날은 기록이 없어요',
              style: textTheme.bodyMedium?.copyWith(color: muted),
            ),
          )
        else
          for (final e in entries)
            EntryTile(
              entry: e,
              onTap: () => showRecordSheet(context, editing: e),
            ),
      ],
    );
  }
}
