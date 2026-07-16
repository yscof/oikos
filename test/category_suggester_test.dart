import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';
import 'package:oikos/insight/category_suggester.dart';

Entry entry({
  required Category category,
  required DateTime occurredAt,
  int amount = 12000,
  EntryKind kind = EntryKind.expense,
}) =>
    Entry(
      id: '${category.name}-${occurredAt.microsecondsSinceEpoch}',
      kind: kind,
      amountWon: amount,
      category: category,
      memo: '',
      occurredAt: occurredAt,
      createdAt: occurredAt,
    );

void main() {
  // 2026-07-16은 목요일
  final weekdayLunch = DateTime(2026, 7, 16, 12, 30);
  final night = DateTime(2026, 7, 16, 22, 30);

  test('정본 케이스: 평일 12:30 + 12,000원 → 식사 1위 (이력 없음)', () {
    final ranked =
        rankCategories(now: weekdayLunch, amountWon: 12000, history: []);
    expect(ranked.first, Category.meal);
  });

  test('밤 + 1.5만~5만 → 배달이 술보다 먼저 (콜드스타트)', () {
    final ranked = rankCategories(now: night, amountWon: 25000, history: []);
    expect(ranked.first, Category.delivery);
    expect(
      ranked.indexOf(Category.drinks),
      lessThan(ranked.indexOf(Category.meal)),
    );
  });

  test('주말 오후 + 중간 금액 → 온라인쇼핑 (콜드스타트)', () {
    final weekendAfternoon = DateTime(2026, 7, 18, 15, 0); // 토요일
    final ranked =
        rankCategories(now: weekendAfternoon, amountWon: 40000, history: []);
    expect(ranked.first, Category.shopping);
  });

  test('이력이 prior를 이긴다: 밤에 늘 카페를 가는 사용자', () {
    final history = [
      for (var d = 1; d <= 6; d++)
        entry(
          category: Category.cafe,
          amount: 30000,
          occurredAt: DateTime(2026, 7, 16 - d, 22, 0),
        ),
    ];
    final ranked =
        rankCategories(now: night, amountWon: 30000, history: history);
    expect(ranked.first, Category.cafe);
  });

  test('지수 감쇠: 최근 이력이 오래된 이력을 이긴다', () {
    final history = [
      for (var i = 0; i < 3; i++)
        entry(
          category: Category.drinks,
          occurredAt: weekdayLunch.subtract(Duration(days: 60 + i)),
        ),
      for (var i = 0; i < 3; i++)
        entry(
          category: Category.leisure,
          occurredAt: weekdayLunch.subtract(Duration(days: 2 + i)),
        ),
    ];
    final ranked =
        rankCategories(now: weekdayLunch, amountWon: 12000, history: history);
    expect(
      ranked.indexOf(Category.leisure),
      lessThan(ranked.indexOf(Category.drinks)),
    );
  });

  test('수입 기록은 추천에 영향을 주지 않는다', () {
    final incomeHistory = [
      for (var d = 1; d <= 10; d++)
        entry(
          category: Category.salary,
          kind: EntryKind.income,
          amount: 12000,
          occurredAt: DateTime(2026, 7, 16 - d, 12, 30),
        ),
    ];
    final withIncome = rankCategories(
        now: weekdayLunch, amountWon: 12000, history: incomeHistory);
    final withoutHistory =
        rankCategories(now: weekdayLunch, amountWon: 12000, history: []);
    expect(withIncome, withoutHistory);
  });

  test('결과는 지출 카테고리 전체를 정확히 한 번씩 담는다', () {
    final ranked =
        rankCategories(now: weekdayLunch, amountWon: 12000, history: []);
    expect(ranked.toSet(), Category.of(EntryKind.expense).toSet());
    expect(ranked.length, Category.of(EntryKind.expense).length);
  });

  test('결정성: 같은 입력 → 같은 순서', () {
    final history = [
      entry(category: Category.meal, occurredAt: DateTime(2026, 7, 10, 12, 0)),
      entry(category: Category.cafe, occurredAt: DateTime(2026, 7, 12, 15, 0)),
    ];
    final a =
        rankCategories(now: weekdayLunch, amountWon: 12000, history: history);
    final b =
        rankCategories(now: weekdayLunch, amountWon: 12000, history: history);
    expect(a, b);
  });
}
