/// 톤 계약: 사용자에게 노출되는 모든 인사이트 문장은 이 파일에만 존재한다.
/// 금지 — 명령형(~하세요/~마세요 류의 '세요'체), 판단어(과소비/낭비), 'AI'.
/// 아래 금지어 부재는 tone_test에서 기계 검증된다.
library;

import '../core/formats.dart';
import '../data/entry.dart';

/// 받침 유무에 따른 이/가.
String josaIGa(String word) {
  final code = word.codeUnitAt(word.length - 1);
  if (code < 0xAC00 || code > 0xD7A3) return '이(가)';
  return (code - 0xAC00) % 28 == 0 ? '가' : '이';
}

String headlineDeltaUp(Category c) => '이번 주 ${c.label} 소비가 평소보다 조금 많았어요';

String headlineDeltaDown(Category c) => '이번 주 ${c.label} 소비가 평소보다 줄었어요';

String headlineFrequency(Category c) =>
    '이번 주는 ${c.label}${josaIGa(c.label)} 잦았어요';

String headlineQuietWeek() => '이번 주는 평소보다 차분한 소비 흐름이에요';

String headlineWeekdayPattern(String weekday) => '주로 $weekday요일에 소비가 모이는 편이에요';

String headlineSteady() => '이번 주 소비는 평소와 비슷한 흐름이에요';

/// 콜드스타트 순환 문장 — 같은 날에는 같은 문장이 나온다.
const List<String> coldStartHeadlines = [
  '기록이 쌓이면 소비의 흐름을 읽어드릴게요',
  '몇 번의 기록이면 나의 소비 리듬이 보이기 시작해요',
  '숫자 몇 개면 충분해요, 흐름은 오이코스가 읽을게요',
];

String evidenceWonDelta(num baselineWon, num thisWeekWon) =>
    '이렇게 읽었어요: 최근 4주 평균 ${wonMan(baselineWon)} → 이번 주 ${wonMan(thisWeekWon)}';

String evidenceQuietWeek(num baselineWon, num soFarWon) =>
    '이렇게 읽었어요: 최근 4주 주 평균 ${wonMan(baselineWon)} → 이번 주 지금까지 ${wonMan(soFarWon)}';

String evidenceCountDelta(double baselineCount, int thisWeekCount) =>
    '이렇게 읽었어요: 최근 4주 평균 주 ${num1(baselineCount)}회 → 이번 주 $thisWeekCount회';

String evidenceWeekday(int percent, String weekday) =>
    '이렇게 읽었어요: 최근 4주 지출의 $percent%가 $weekday요일에 있었어요';

/// 홈의 무채색 소문 — 오늘. 습관은 '하루' 단위로 만들어지므로 오늘을 먼저 보여준다.
String todayMurmur(int todayExpenseWon) => '오늘 지출 ${wonCompact(todayExpenseWon)}';

/// 홈의 무채색 소문 한 줄 — 이번 주.
String weekMurmur(int weekExpenseWon) => '이번 주 지출 ${wonCompact(weekExpenseWon)}';

/// 누적 기록 수를 되비추는 조용한 한 줄. 스트릭 아님 — 깨지지 않고 쌓이기만 한다.
String recordCountMurmur(int count) => '지금까지 $count번 기록했어요';

/// 톤 계약 기계 검증용 — 모든 템플릿을 실제 값으로 전개한다.
List<String> allSentencesForToneCheck() => [
      for (final c in Category.of(EntryKind.expense)) ...[
        headlineDeltaUp(c),
        headlineDeltaDown(c),
        headlineFrequency(c),
      ],
      headlineQuietWeek(),
      headlineSteady(),
      for (final d in weekdaysKo) headlineWeekdayPattern(d),
      ...coldStartHeadlines,
      evidenceWonDelta(32000, 51000),
      evidenceQuietWeek(90000, 60000),
      evidenceCountDelta(1.5, 5),
      evidenceWeekday(62, '금'),
      todayMurmur(23000),
      weekMurmur(124000),
      recordCountMurmur(148),
    ];
