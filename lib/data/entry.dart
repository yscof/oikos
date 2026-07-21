import 'dart:math';

import 'package:flutter/material.dart';

enum EntryKind { expense, income }

/// 지출의 순간에 남기는 '느낌' — 선택 입력. 소비 습관은 숫자가 아니라
/// 결정의 순간 자각에서 바뀐다. 판단이 아닌 자기 인식용이라 담백하게.
/// enum name이 저장 포맷이므로 이름을 바꾸지 말 것.
enum Emotion {
  satisfied('만족', Icons.sentiment_satisfied_outlined),
  mindless('무심코', Icons.sentiment_neutral_outlined),
  regret('아쉬움', Icons.sentiment_dissatisfied_outlined);

  const Emotion(this.label, this.icon);

  final String label;
  final IconData icon;

  /// 미지·null → null (구버전 데이터 호환).
  static Emotion? parse(Object? raw) {
    if (raw is String) {
      for (final e in values) {
        if (e.name == raw) return e;
      }
    }
    return null;
  }
}

/// 20-30대 소비축 카테고리. 배달/온라인쇼핑/술·모임은 인사이트 예문이
/// 의존하는 1급 카테고리다. enum name이 저장 포맷이므로 이름을 바꾸지 말 것.
enum Category {
  meal('식사', Icons.restaurant_outlined, EntryKind.expense),
  cafe('카페·간식', Icons.local_cafe_outlined, EntryKind.expense),
  delivery('배달', Icons.delivery_dining_outlined, EntryKind.expense),
  mart('편의점·마트', Icons.local_convenience_store_outlined, EntryKind.expense),
  shopping('온라인쇼핑', Icons.shopping_bag_outlined, EntryKind.expense),
  drinks('술·모임', Icons.local_bar_outlined, EntryKind.expense),
  transport('교통', Icons.directions_bus_outlined, EntryKind.expense),
  subscription('구독', Icons.autorenew_outlined, EntryKind.expense),
  leisure('문화·여가', Icons.movie_outlined, EntryKind.expense),
  fashion('패션·뷰티', Icons.checkroom_outlined, EntryKind.expense),
  housing('주거·통신', Icons.home_outlined, EntryKind.expense),
  medical('의료·건강', Icons.medical_services_outlined, EntryKind.expense),
  etc('기타', Icons.more_horiz_outlined, EntryKind.expense),
  salary('월급', Icons.payments_outlined, EntryKind.income),
  incomeEtc('기타 수입', Icons.savings_outlined, EntryKind.income);

  const Category(this.label, this.icon, this.kind);

  final String label;
  final IconData icon;
  final EntryKind kind;

  static List<Category> of(EntryKind kind) =>
      values.where((c) => c.kind == kind).toList(growable: false);

  static Category fallbackFor(EntryKind kind) =>
      kind == EntryKind.income ? incomeEtc : etc;

  /// 미지·불일치 카테고리는 kind의 기타로 관용 처리 (구버전 데이터 호환).
  static Category parse(Object? raw, EntryKind kind) {
    if (raw is String) {
      for (final c in values) {
        if (c.name == raw && c.kind == kind) return c;
      }
    }
    return fallbackFor(kind);
  }
}

final _rand = Random();

String newEntryId(DateTime now) =>
    '${now.microsecondsSinceEpoch.toRadixString(36)}'
    '-${_rand.nextInt(0x10000).toRadixString(36)}';

/// copyWith에서 '넘기지 않음'과 '명시적 null(감정 해제)'을 구분하는 센티널.
const Object _unset = Object();

class Entry {
  const Entry({
    required this.id,
    required this.kind,
    required this.amountWon,
    required this.category,
    required this.memo,
    required this.occurredAt,
    required this.createdAt,
    this.emotion,
  });

  final String id;
  final EntryKind kind;
  final int amountWon;
  final Category category;

  /// "어떤 순간이었나요?" — 금융 경험 한 줄 (선택).
  final String memo;

  /// 지출의 느낌 (선택). 수입에는 두지 않는다.
  final Emotion? emotion;

  /// 시각 포함 — 카테고리 추천기의 입력이 된다.
  final DateTime occurredAt;
  final DateTime createdAt;

  Entry copyWith({
    EntryKind? kind,
    int? amountWon,
    Category? category,
    String? memo,
    DateTime? occurredAt,
    Object? emotion = _unset,
  }) {
    final k = kind ?? this.kind;
    var c = category ?? this.category;
    if (c.kind != k) c = Category.fallbackFor(k);
    var e = identical(emotion, _unset) ? this.emotion : emotion as Emotion?;
    if (k == EntryKind.income) e = null; // 수입엔 감정을 남기지 않는다
    return Entry(
      id: id,
      kind: k,
      amountWon: amountWon ?? this.amountWon,
      category: c,
      memo: memo ?? this.memo,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt,
      emotion: e,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'amountWon': amountWon,
        'category': category.name,
        'memo': memo,
        if (emotion != null) 'emotion': emotion!.name,
        'occurredAt': occurredAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  /// 관용적 파싱: 빠진 필드는 무해한 기본값, 미지 카테고리는 기타로,
  /// 미지·없는 감정은 null로 (구버전 데이터 호환).
  factory Entry.fromJson(Map<String, dynamic> json) {
    final kind =
        json['kind'] == EntryKind.income.name ? EntryKind.income : EntryKind.expense;
    final occurredAt =
        DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
    return Entry(
      id: json['id'] as String? ?? newEntryId(occurredAt),
      kind: kind,
      amountWon: (json['amountWon'] as num?)?.toInt() ?? 0,
      category: Category.parse(json['category'], kind),
      memo: json['memo'] as String? ?? '',
      emotion: kind == EntryKind.expense ? Emotion.parse(json['emotion']) : null,
      occurredAt: occurredAt,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? occurredAt,
    );
  }
}
