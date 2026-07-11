import 'package:go_router/go_router.dart';

import '../features/game/presentation/game_screen.dart';
import 'presentation/home_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/game', builder: (context, state) => const GameScreen()),
  ],
);
