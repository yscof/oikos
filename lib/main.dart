import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const OikosApp(),
    ),
  );
}

class OikosApp extends StatefulWidget {
  const OikosApp({super.key});

  @override
  State<OikosApp> createState() => _OikosAppState();
}

class _OikosAppState extends State<OikosApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '오이코스',
      theme: oikosTheme(Brightness.light),
      darkTheme: oikosTheme(Brightness.dark),
      routerConfig: _router,
    );
  }
}
