import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/core/formats.dart';

void main() {
  group('won', () {
    test('콤마 그룹핑', () {
      expect(won(0), '0원');
      expect(won(500), '500원');
      expect(won(12000), '12,000원');
      expect(won(1234567), '1,234,567원');
    });

    test('음수', () {
      expect(won(-12000), '-12,000원');
    });
  });

  group('groupThousands', () {
    test('입력용 천단위 콤마', () {
      expect(groupThousands('0'), '0');
      expect(groupThousands('12000'), '12,000');
      expect(groupThousands('1500000'), '1,500,000');
      expect(groupThousands(''), '');
    });
  });

  group('dayLabel', () {
    final now = DateTime(2026, 7, 16, 14, 30);

    test('오늘/어제', () {
      expect(dayLabel(DateTime(2026, 7, 16, 1), now), '오늘');
      expect(dayLabel(DateTime(2026, 7, 15, 23), now), '어제');
    });

    test('그 외는 M월 d일', () {
      expect(dayLabel(DateTime(2026, 7, 3), now), '7월 3일');
      expect(dayLabel(DateTime(2025, 12, 25), now), '12월 25일');
    });
  });

  test('weekdayKo', () {
    expect(weekdayKo(DateTime(2026, 7, 13)), '월');
    expect(weekdayKo(DateTime(2026, 7, 19)), '일');
  });
}
