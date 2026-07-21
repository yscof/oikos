import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/prefs.dart';

/// 이번 달 전체 예산(원) 저장 키. 0 = 설정 안 함.
const String monthBudgetKey = 'oikos_month_budget_v1';

/// 월 전체 예산(FR-501). 0이면 미설정 — 홈에 예산 현황을 띄우지 않는다.
final monthBudgetProvider =
    NotifierProvider<MonthBudgetNotifier, int>(MonthBudgetNotifier.new);

class MonthBudgetNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final v = prefs.getInt(monthBudgetKey) ?? 0;
    return v < 0 ? 0 : v;
  }

  Future<void> set(int won) async {
    final v = won < 0 ? 0 : won;
    state = v;
    await ref.read(sharedPreferencesProvider).setInt(monthBudgetKey, v);
  }
}
