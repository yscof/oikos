import 'package:go_router/go_router.dart';

import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import 'app_shell.dart';

/// 인스턴스별 라우터 — 위젯 테스트마다 새로 만들어 상태 누수를 막는다.
/// 하단 탭: 가계부(/) · 통계(/stats) · 더보기(/more).
/// 내역·설정은 탭 위로 push되는 상세 화면.
GoRouter createRouter() => GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ]),
          ],
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
