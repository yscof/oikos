/// 가입 비밀번호 규칙 (MEM01_LOGIN01):
/// 8자 이상, 대문자·소문자·숫자·특수문자를 모두 포함.
const String passwordRulesHint = '8자 이상 · 대문자, 소문자, 숫자, 특수문자 포함';

/// 규칙을 어기면 안내 문장을, 통과하면 null을 돌려준다.
String? validatePassword(String password) {
  if (password.length < 8) {
    return '비밀번호는 8자 이상이어야 해요.';
  }
  if (!password.contains(RegExp(r'[A-Z]'))) {
    return '비밀번호에 대문자를 1자 이상 넣어 주세요.';
  }
  if (!password.contains(RegExp(r'[a-z]'))) {
    return '비밀번호에 소문자를 1자 이상 넣어 주세요.';
  }
  if (!password.contains(RegExp(r'[0-9]'))) {
    return '비밀번호에 숫자를 1자 이상 넣어 주세요.';
  }
  if (!password.contains(RegExp(r'[^A-Za-z0-9]'))) {
    return '비밀번호에 특수문자를 1자 이상 넣어 주세요.';
  }
  return null;
}
