import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs.dart';
import 'entry.dart';

/// 저장 키. 포맷이 바뀌면 v2로 올리고 마이그레이션을 둔다.
const String entriesPrefsKey = 'oikos_entries_v1';

/// 전체 기록. 상태 불변식: occurredAt 내림차순(최신 먼저), 동률이면 createdAt 내림차순.
/// SharedPreferences JSON 저장 — 1만 건 초과 시 sqflite 전환은 이 파일 교체로 끝난다.
final entryStoreProvider =
    NotifierProvider<EntryNotifier, List<Entry>>(EntryNotifier.new);

class EntryNotifier extends Notifier<List<Entry>> {
  @override
  List<Entry> build() => _load(ref.watch(sharedPreferencesProvider));

  static List<Entry> _load(SharedPreferences prefs) {
    final raw = prefs.getString(entriesPrefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return _sorted([
        for (final item in decoded)
          if (item is Map<String, dynamic>) Entry.fromJson(item),
      ]);
    } catch (_) {
      // 손상된 저장소는 조용히 빈 목록으로 — 앱이 죽는 것보다 낫다.
      return const [];
    }
  }

  static List<Entry> _sorted(List<Entry> entries) {
    final copy = [...entries];
    copy.sort((a, b) {
      final byOccurred = b.occurredAt.compareTo(a.occurredAt);
      if (byOccurred != 0) return byOccurred;
      return b.createdAt.compareTo(a.createdAt);
    });
    return copy;
  }

  Future<void> add(Entry entry) async {
    state = _sorted([...state, entry]);
    await _persist();
  }

  Future<void> update(Entry entry) async {
    state = _sorted([
      for (final e in state)
        if (e.id == entry.id) entry else e,
    ]);
    await _persist();
  }

  Future<void> remove(String id) async {
    state = [
      for (final e in state)
        if (e.id != id) e,
    ];
    await _persist();
  }

  Future<void> clearAll() async {
    state = const [];
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      entriesPrefsKey,
      jsonEncode([for (final e in state) e.toJson()]),
    );
  }
}
