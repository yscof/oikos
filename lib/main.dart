import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme.dart';
import 'core/prefs.dart';
import 'features/home/home_screen.dart';

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

class OikosApp extends StatelessWidget {
  const OikosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오이코스',
      theme: oikosTheme(Brightness.light),
      darkTheme: oikosTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
