/// Supabase 접속 설정 — 빌드 시 --dart-define 으로 주입한다.
/// 값이 비어 있으면(미설정) 앱은 지금까지처럼 완전 오프라인으로 동작하고,
/// 로그인 게이트도 켜지 않는다. CI·테스트는 이 값 없이도 그대로 통과한다.
library;

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// URL/키가 모두 주입됐을 때만 Supabase(로그인·동기화)를 켠다.
const bool supabaseConfigured = supabaseUrl != '' && supabaseAnonKey != '';
