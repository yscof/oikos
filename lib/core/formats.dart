/// 사용자에게 보이는 숫자·날짜 포맷. intl 없이 손으로 쓴다.
library;

String _group(int n) {
  final digits = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// 입력 필드용 — 숫자 문자열에 천 단위 콤마. '12000' → '12,000'
String groupThousands(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// 3자리 콤마 + 원. 예) 12,000원
String won(int amount) => '${amount < 0 ? '-' : ''}${_group(amount.abs())}원';

/// 요약 문장용 만/천 축약 — 천 미만 자리는 버린다(어림 표현).
/// 예) 124,000 → 12만 4천원, 420,000 → 42만원, 9,500 → 9,500원
String wonCompact(int amount) {
  if (amount < 10000) return won(amount);
  final man = amount ~/ 10000;
  final thousand = (amount % 10000) ~/ 1000;
  if (thousand == 0) return '${_group(man)}만원';
  return '${_group(man)}만 $thousand천원';
}

/// 소수 1자리, 불필요한 .0은 지운다. 예) 1.5 → 1.5, 2.0 → 2
String num1(double v) => v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

/// 근거 문장용 만 단위. 예) 32,000 → 3.2만원, 20,000 → 2만원, 9,000 → 9,000원
String wonMan(num amount) {
  if (amount.abs() < 10000) return won(amount.round());
  return '${num1(amount / 10000)}만원';
}

/// 내역 그룹 헤더용 날짜 라벨: 오늘 / 어제 / M월 d일
String dayLabel(DateTime date, DateTime now) {
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '오늘';
  if (diff == 1) return '어제';
  return '${day.month}월 ${day.day}일';
}

const List<String> weekdaysKo = ['월', '화', '수', '목', '금', '토', '일'];

/// 요일 한 글자. DateTime.monday(1) → 월
String weekdayKo(DateTime date) => weekdaysKo[date.weekday - 1];
