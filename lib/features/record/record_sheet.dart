import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/formats.dart';
import '../../data/entry.dart';
import '../../data/entry_store.dart';
import '../../insight/category_suggester.dart';

/// 기록 해피패스 = 금액 입력 → (추천 1위 칩 자동 선택) → 저장, 약 3초.
Future<void> showRecordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const RecordSheet(),
  );
}

class RecordSheet extends ConsumerStatefulWidget {
  const RecordSheet({super.key});

  @override
  ConsumerState<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<RecordSheet> {
  EntryKind _kind = EntryKind.expense;

  /// 사용자가 직접 고른 칩. null이면 추천 1위가 자동 선택된다.
  Category? _picked;
  DateTime? _pickedDay; // null = 오늘
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  /// 추천순 카테고리. 금액·시각이 바뀔 때마다 실시간 재정렬.
  List<Category> _ranked() {
    if (_kind == EntryKind.income) return Category.of(EntryKind.income);
    return rankCategories(
      now: ref.read(clockProvider)(),
      amountWon: _amount,
      history: ref.read(entryStoreProvider),
    );
  }

  Category _effectiveCategory(List<Category> ranked) {
    final picked = _picked;
    if (picked != null && picked.kind == _kind) return picked;
    return ranked.first;
  }

  Future<void> _save() async {
    final now = ref.read(clockProvider)();
    final day = _pickedDay;
    final occurredAt = day == null
        ? now
        : DateTime(day.year, day.month, day.day, now.hour, now.minute);
    final entry = Entry(
      id: newEntryId(now),
      kind: _kind,
      amountWon: _amount,
      category: _effectiveCategory(_ranked()),
      memo: _memoController.text.trim(),
      occurredAt: occurredAt,
      createdAt: now,
    );
    await ref.read(entryStoreProvider.notifier).add(entry);
    if (!mounted) return;
    Navigator.of(context).pop(); // 저장 후 팡파레 없음 — 조용히 닫는다.
  }

  Future<void> _pickDay() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDay ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _pickedDay = picked);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    ref.watch(entryStoreProvider); // 이력 변경 시 추천 재계산
    final categories = _ranked();
    final selected = _effectiveCategory(categories);
    final dayText = _pickedDay == null ? '오늘' : dayLabel(_pickedDay!, now);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SegmentedButton<EntryKind>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: EntryKind.expense,
                      label: Text('지출'),
                    ),
                    ButtonSegment(value: EntryKind.income, label: Text('수입')),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (selection) => setState(() {
                    _kind = selection.single;
                    _picked = null; // 새 kind의 추천 1위로 되돌린다
                  }),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickDay,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(dayText),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('amount-field'),
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: '원',
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  ChoiceChip(
                    label: Text(category.label),
                    avatar: Icon(category.icon, size: 18),
                    selected: selected == category,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _picked = category),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('memo-field'),
              controller: _memoController,
              decoration: const InputDecoration(
                hintText: '어떤 순간이었나요? (선택)',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _amount > 0 ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
