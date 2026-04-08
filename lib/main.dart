import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:d4rts/app_state.dart';
import 'package:d4rts/screens/game_result_screen.dart';
import 'package:d4rts/screens/game_screen.dart';
import 'package:d4rts/screens/game_setup_screen.dart';
import 'package:d4rts/screens/home_screen.dart';
import 'package:d4rts/screens/import_export_screen.dart';
import 'package:d4rts/screens/settings_screen.dart';
import 'package:d4rts/screens/stats_screen.dart';
import 'package:d4rts/screens/tournament_bracket_screen.dart';
import 'package:d4rts/screens/tournament_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final appState = AppState();
  await appState.init();
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const D4rtsApp(),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
    GoRoute(path: '/game/setup', builder: (ctx, state) => const GameSetupScreen()),
    GoRoute(path: '/game/play', builder: (ctx, state) => const GameScreen()),
    GoRoute(path: '/game/result', builder: (ctx, state) => const GameResultScreen()),
    GoRoute(path: '/tournament/setup', builder: (ctx, state) => const TournamentSetupScreen()),
    GoRoute(path: '/tournament/bracket', builder: (ctx, state) => const TournamentBracketScreen()),
    GoRoute(path: '/stats', builder: (ctx, state) => const StatsScreen()),
    GoRoute(path: '/settings', builder: (ctx, state) => const SettingsScreen()),
    GoRoute(path: '/import-export', builder: (ctx, state) => const ImportExportScreen()),
  ],
);

class D4rtsApp extends StatelessWidget {
  const D4rtsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themeMode = switch (appState.settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'D4RTS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
