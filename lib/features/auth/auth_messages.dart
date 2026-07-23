import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 인증 오류(영문)를 한글 안내로 바꾼다. 모르는 오류는 원문 그대로.
String authErrorMessage(AuthException e) {
  final m = e.message.toLowerCase();
  final wait = RegExp(r'after (\d+) second').firstMatch(m);
  if (wait != null) {
    return '보안을 위해 ${wait.group(1)}초 뒤에 다시 시도할 수 있어요.';
  }
  if (m.contains('invalid login credentials')) {
    return '이메일 또는 비밀번호가 맞지 않아요.';
  }
  if (m.contains('already registered')) {
    return '이미 가입된 이메일이에요. 로그인으로 시도해 보세요.';
  }
  if (m.contains('email not confirmed')) {
    return '이메일 인증이 아직 안 됐어요. 받은 메일함(스팸함 포함)을 확인해 주세요.';
  }
  if (m.contains('rate limit')) {
    return '메일 발송 한도에 잠시 닿았어요. 조금 뒤에 다시 시도해 주세요.';
  }
  if (m.contains('unable to validate email') || m.contains('invalid format')) {
    return '이메일 주소 형식을 확인해 주세요.';
  }
  if (m.contains('password should be')) {
    return '비밀번호가 서버 규칙에 맞지 않아요. 더 길고 복잡하게 만들어 주세요.';
  }
  if (m.contains('network') ||
      m.contains('socket') ||
      m.contains('failed host lookup')) {
    return '네트워크 연결을 확인해 주세요.';
  }
  return e.message;
}
