import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 인증 계층 — Supabase가 설정됐을 때만 실제로 쓰인다(supabaseConfigured 게이트).
/// 미설정 빌드에서는 이 프로바이더들을 watch하지 않으므로 Supabase.instance에
/// 접근하지 않는다.

/// 현재 세션 스트림. 초기 세션을 먼저 흘리고 이후 변화를 잇는다.
final authStateProvider = StreamProvider<Session?>((ref) async* {
  final auth = Supabase.instance.client.auth;
  yield auth.currentSession;
  await for (final event in auth.onAuthStateChange) {
    yield event.session;
  }
});

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(Supabase.instance.client),
);

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// 가입. 이메일 확인이 켜져 있으면 세션은 확인 후 생성된다.
  Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(email: email.trim(), password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());
}
