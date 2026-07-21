import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/prefs.dart';

/// 가계부 시작일(정산 기준일) 저장 키. 1~28일.
const String monthStartDayKey = 'oikos_month_start_day_v1';

/// 매월 정산이 시작되는 날(FR-601). 기본 1일 = 달력 월.
final monthStartDayProvider =
    NotifierProvider<MonthStartDayNotifier, int>(MonthStartDayNotifier.new);

class MonthStartDayNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return (prefs.getInt(monthStartDayKey) ?? 1).clamp(1, 28);
  }

  Future<void> set(int day) async {
    final d = day.clamp(1, 28);
    state = d;
    await ref.read(sharedPreferencesProvider).setInt(monthStartDayKey, d);
  }
}
