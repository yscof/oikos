import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/formats.dart';
import '../../data/entry.dart';
import '../../data/entry_store.dart';
import '../home/recent_entries.dart' show EntryTile;
import '../record/record_sheet.dart';
import 'calendar_view.dart';

/// 날짜 그룹 타임라인 + 검색·필터(FR-406). 의미(인사이트)는 홈에, 여기는 사실만.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  Category? _categoryFilter; // null = 전체
  bool _calendar = false; // 목록 ↔ 캘린더 뷰 (FR-402/405)

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Entry entry) async {
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

  bool _matches(Entry e) {
    if (_categoryFilter != null && e.category != _categoryFilter) return false;
    if (_query.isNotEmpty) {
      final hay = '${e.category.label} ${e.memo}'.toLowerCase();
      if (!hay.contains(_query.toLowerCase())) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
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

    final filtered = entries.where(_matches).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내역'),
        actions: [
          IconButton(
            tooltip: _calendar ? '목록 보기' : '캘린더 보기',
            icon: Icon(_calendar
                ? Icons.view_list_outlined
                : Icons.calendar_month_outlined),
            onPressed: () => setState(() => _calendar = !_calendar),
          ),
        ],
      ),
      body: _calendar
          ? const CalendarView()
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('history-search'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: '메모·카테고리 검색',
                      border: const OutlineInputBorder(),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<Category?>(
                  value: _categoryFilter,
                  hint: const Text('전체'),
                  underline: const SizedBox.shrink(),
                  onChanged: (c) => setState(() => _categoryFilter = c),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('전체')),
                    for (final c in Category.values)
                      DropdownMenuItem(value: c, child: Text(c.label)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      '조건에 맞는 기록이 없어요',
                      style: textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: _timeline(filtered, now, textTheme, muted),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _timeline(
    List<Entry> entries,
    DateTime now,
    TextTheme textTheme,
    Color muted,
  ) {
    // 월별 지출 합계 (월 구분선용) — 표시 중인(필터된) 기록 기준.
    final monthExpense = <(int, int), int>{};
    for (final e in entries) {
      if (e.kind != EntryKind.expense) continue;
      final key = (e.occurredAt.year, e.occurredAt.month);
      monthExpense[key] = (monthExpense[key] ?? 0) + e.amountWon;
    }

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
              '$yearPrefix${month.$2}월 · 지출 ${won(monthExpense[month] ?? 0)}',
              style: textTheme.labelLarge?.copyWith(color: muted),
            ),
          ),
        );
      }
      final day = DateTime(e.occurredAt.year, e.occurredAt.month, e.occurredAt.day);
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
          onLongPress: () => _confirmDelete(e),
        ),
      );
    }
    return children;
  }
}
