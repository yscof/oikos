import '../data/entry.dart';

/// 룰 타입. enum 순서가 동점 시 결정적 tie-break에 쓰인다.
enum InsightRule {
  categoryDeltaUp,
  frequency,
  categoryDeltaDown,
  quietWeek,
  weekdayPattern,
  steady,
  coldStart,
}

class Insight {
  const Insight({
    required this.rule,
    required this.priority,
    required this.headline,
    this.evidence,
    this.category,
  });

  final InsightRule rule;
  final double priority;

  /// 사용자에게 보이는 문장 — insight_messages.dart에서만 온다.
  final String headline;

  /// 탭하면 보이는 『이렇게 읽었어요: …』 근거. null이면 탭 불가.
  final String? evidence;
  final Category? category;
}

class InsightResult {
  const InsightResult({required this.headline, required this.senses});

  final Insight headline;

  /// "이번 주 감각" 보조 라인 — 헤드라인과 다른 룰 타입, 최대 2개.
  final List<Insight> senses;
}
