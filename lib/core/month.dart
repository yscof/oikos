/// 정산 기준일(가계부 시작일)에 따른 '이번 달' 구간 계산 (FR-601).
library;

/// startDay(1~28) 기준으로 [now]가 속한 정산월 구간 [start, end)를 돌려준다.
/// 예) startDay=25, now=7/10 → [6/25, 7/25). now=7/28 → [7/25, 8/25).
/// startDay=1이면 달력 월과 같다.
({DateTime start, DateTime end}) financialMonthRange(DateTime now, int startDay) {
  final d = startDay.clamp(1, 28);
  final start = now.day >= d
      ? DateTime(now.year, now.month, d)
      : DateTime(now.year, now.month - 1, d);
  final end = DateTime(start.year, start.month + 1, d);
  return (start: start, end: end);
}
