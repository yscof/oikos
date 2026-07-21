import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/formats.dart';
import '../../data/entry.dart';
import '../../data/entry_store.dart';
import '../../insight/category_suggester.dart';

/// 기록 해피패스 = 금액 입력 → (추천 1위 칩 자동 선택) → 저장, 약 3초.
/// [editing]을 주면 그 항목을 수정한다.
Future<void> showRecordSheet(BuildContext context, {Entry? editing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => RecordSheet(editing: editing),
  );
}

/// 금액 입력 중 천 단위 콤마를 실시간으로 넣는다(FR-208). 숫자만 남기고 재그룹.
class _ThousandsInputFormatter extends TextInputFormatter {
  const _ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = groupThousands(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class RecordSheet extends ConsumerStatefulWidget {
  const RecordSheet({super.key, this.editing});

  final Entry? editing;

  @override
  ConsumerState<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<RecordSheet> {
  EntryKind _kind = EntryKind.expense;

  /// 사용자가 직접 고른 칩. null이면 추천 1위가 자동 선택된다.
  Category? _picked;

  /// 지출의 느낌 (선택). null이면 남기지 않은 것.
  Emotion? _emotion;
  DateTime? _pickedDay; // null = 오늘
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _kind = editing.kind;
      _picked = editing.category;
      _emotion = editing.emotion;
      _pickedDay = DateTime(
        editing.occurredAt.year,
        editing.occurredAt.month,
        editing.occurredAt.day,
      );
      _amountController.text = groupThousands(editing.amountWon.toString());
      _memoController.text = editing.memo;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

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
    final editing = widget.editing;
    final store = ref.read(entryStoreProvider.notifier);
    final emotion = _kind == EntryKind.expense ? _emotion : null;
    if (editing != null) {
      final day = _pickedDay!;
      await store.update(editing.copyWith(
        kind: _kind,
        amountWon: _amount,
        category: _effectiveCategory(_ranked()),
        memo: _memoController.text.trim(),
        emotion: emotion,
        occurredAt: DateTime(day.year, day.month, day.day,
            editing.occurredAt.hour, editing.occurredAt.minute),
      ));
    } else {
      final day = _pickedDay;
      final occurredAt = day == null
          ? now
          : DateTime(day.year, day.month, day.day, now.hour, now.minute);
      await store.add(Entry(
        id: newEntryId(now),
        kind: _kind,
        amountWon: _amount,
        category: _effectiveCategory(_ranked()),
        memo: _memoController.text.trim(),
        emotion: emotion,
        occurredAt: occurredAt,
        createdAt: now,
      ));
    }
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
                    if (_kind == EntryKind.income) _emotion = null;
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
              inputFormatters: const [_ThousandsInputFormatter()],
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
            if (_kind == EntryKind.expense) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final e in Emotion.values)
                    ChoiceChip(
                      label: Text(e.label),
                      avatar: Icon(e.icon, size: 18),
                      selected: _emotion == e,
                      showCheckmark: false,
                      // 다시 누르면 해제 — 남길지 말지는 온전히 선택.
                      onSelected: (on) =>
                          setState(() => _emotion = on ? e : null),
                    ),
                ],
              ),
            ],
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
