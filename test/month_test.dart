import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/core/month.dart';

void main() {
  group('financialMonthRange', () {
    test('시작일 1 → 달력 월', () {
      final r = financialMonthRange(DateTime(2026, 7, 16), 1);
      expect(r.start, DateTime(2026, 7, 1));
      expect(r.end, DateTime(2026, 8, 1));
    });

    test('시작일 25, 오늘이 25일 이후 → 이번 달 25일부터', () {
      final r = financialMonthRange(DateTime(2026, 7, 28), 25);
      expect(r.start, DateTime(2026, 7, 25));
      expect(r.end, DateTime(2026, 8, 25));
    });

    test('시작일 25, 오늘이 25일 이전 → 지난 달 25일부터', () {
      final r = financialMonthRange(DateTime(2026, 7, 10), 25);
      expect(r.start, DateTime(2026, 6, 25));
      expect(r.end, DateTime(2026, 7, 25));
    });

    test('연 경계: 1월 10일, 시작일 25 → 지난해 12월 25일부터', () {
      final r = financialMonthRange(DateTime(2026, 1, 10), 25);
      expect(r.start, DateTime(2025, 12, 25));
      expect(r.end, DateTime(2026, 1, 25));
    });

    test('시작일이 딱 그날이면 그날부터 포함', () {
      final r = financialMonthRange(DateTime(2026, 7, 25), 25);
      expect(r.start, DateTime(2026, 7, 25));
    });
  });
}
