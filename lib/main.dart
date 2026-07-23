import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/prefs.dart';
import 'core/supabase_config.dart';
import 'data/auth.dart';
import 'data/theme_mode_store.dart';
import 'features/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // URL/키가 주입된 빌드에서만 Supabase(로그인·동기화)를 켠다.
  if (supabaseConfigured) {
    // anonKey는 대시보드의 'anon public' 키. 신버전의 publishableKey로 이름이
    // 바뀌는 중이라 deprecation 안내가 뜨지만 현재 버전에선 그대로 동작한다.
    // ignore: deprecated_member_use
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const OikosApp(),
    ),
  );
}

class OikosApp extends ConsumerStatefulWidget {
  const OikosApp({super.key});

  @override
  ConsumerState<OikosApp> createState() => _OikosAppState();
}

class _OikosAppState extends ConsumerState<OikosApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  ThemeData get _light => oikosTheme(Brightness.light);
  ThemeData get _dark => oikosTheme(Brightness.dark);

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    // 미설정(오프라인) 빌드는 지금까지처럼 곧장 앱으로 — 로그인 게이트 없음.
    if (!supabaseConfigured) return _routerApp(mode);

    // 설정된 빌드: 로그인 상태에 따라 로그인 화면 ↔ 앱.
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (session) =>
          session == null ? _loginApp(mode) : _routerApp(mode),
      loading: () => MaterialApp(
        theme: _light,
        darkTheme: _dark,
        themeMode: mode,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) => _loginApp(mode),
    );
  }

  Widget _routerApp(ThemeMode mode) => MaterialApp.router(
        title: '오이코스',
        theme: _light,
        darkTheme: _dark,
        themeMode: mode,
        routerConfig: _router,
      );

  Widget _loginApp(ThemeMode mode) => MaterialApp(
        title: '오이코스',
        theme: _light,
        darkTheme: _dark,
        themeMode: mode,
        home: const LoginScreen(),
      );
}
