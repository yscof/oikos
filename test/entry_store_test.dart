import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/core/prefs.dart';
import 'package:oikos/data/entry.dart';
import 'package:oikos/data/entry_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> containerWithPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

Entry entry({
  String id = 'e1',
  int amount = 12000,
  Category category = Category.meal,
  DateTime? occurredAt,
  DateTime? createdAt,
}) {
  final at = occurredAt ?? DateTime(2026, 7, 15, 12, 30);
  return Entry(
    id: id,
    kind: EntryKind.expense,
    amountWon: amount,
    category: category,
    memo: '',
    occurredAt: at,
    createdAt: createdAt ?? at,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('추가 → 새 컨테이너에서 영속 왕복', () async {
    SharedPreferences.setMockInitialValues({});

    final c1 = await containerWithPrefs();
    await c1.read(entryStoreProvider.notifier).add(entry());
    expect(c1.read(entryStoreProvider), hasLength(1));

    final c2 = await containerWithPrefs();
    final restored = c2.read(entryStoreProvider);
    expect(restored, hasLength(1));
    expect(restored.single.id, 'e1');
    expect(restored.single.amountWon, 12000);
    expect(restored.single.category, Category.meal);
    expect(restored.single.occurredAt, DateTime(2026, 7, 15, 12, 30));
  });

  test('손상된 JSON → 빈 목록', () async {
    SharedPreferences.setMockInitialValues({entriesPrefsKey: '{이건 json이 아님'});
    final c = await containerWithPrefs();
    expect(c.read(entryStoreProvider), isEmpty);
  });

  test('리스트가 아닌 JSON → 빈 목록', () async {
    SharedPreferences.setMockInitialValues({entriesPrefsKey: '{"a":1}'});
    final c = await containerWithPrefs();
    expect(c.read(entryStoreProvider), isEmpty);
  });

  test('미지 카테고리 → 기타로 관용 처리', () async {
    SharedPreferences.setMockInitialValues({
      entriesPrefsKey: jsonEncode([
        entry().toJson()..['category'] = 'metaverse',
        entry(id: 'e2').toJson()
          ..['category'] = 'salary', // 지출인데 수입 카테고리 → 기타
      ]),
    });
    final c = await containerWithPrefs();
    final loaded = c.read(entryStoreProvider);
    expect(loaded, hasLength(2));
    expect(loaded.every((e) => e.category == Category.etc), isTrue);
  });

  test('정렬 불변식: occurredAt 내림차순', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await containerWithPrefs();
    final store = c.read(entryStoreProvider.notifier);
    await store.add(entry(id: 'old', occurredAt: DateTime(2026, 7, 1)));
    await store.add(entry(id: 'new', occurredAt: DateTime(2026, 7, 15)));
    await store.add(entry(id: 'mid', occurredAt: DateTime(2026, 7, 10)));
    expect(
      c.read(entryStoreProvider).map((e) => e.id).toList(),
      ['new', 'mid', 'old'],
    );
  });

  test('update: 같은 id 교체 + 재정렬', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await containerWithPrefs();
    final store = c.read(entryStoreProvider.notifier);
    await store.add(entry());
    await store.update(
      entry().copyWith(amountWon: 99000, category: Category.delivery),
    );
    final updated = c.read(entryStoreProvider).single;
    expect(updated.amountWon, 99000);
    expect(updated.category, Category.delivery);
  });

  test('remove와 clearAll이 저장까지 반영된다', () async {
    SharedPreferences.setMockInitialValues({});
    final c1 = await containerWithPrefs();
    final store = c1.read(entryStoreProvider.notifier);
    await store.add(entry(id: 'a'));
    await store.add(entry(id: 'b'));
    await store.remove('a');

    final c2 = await containerWithPrefs();
    expect(c2.read(entryStoreProvider).single.id, 'b');

    await c2.read(entryStoreProvider.notifier).clearAll();
    final c3 = await containerWithPrefs();
    expect(c3.read(entryStoreProvider), isEmpty);
  });

  test('copyWith에서 kind가 바뀌면 카테고리를 kind에 맞춘다', () {
    final e = entry().copyWith(kind: EntryKind.income);
    expect(e.category, Category.incomeEtc);
  });
}
