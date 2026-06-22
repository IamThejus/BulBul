import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/book_details/presentation/screens/book_details_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/reader/providers/reader_providers.dart';
import '../../features/reader/presentation/screens/reader_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../models/book_ref.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'route_paths.dart';
import 'scaffold_with_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Exposes the configured [GoRouter] to the widget tree. Kept behind a provider
/// so it can be overridden in tests/deep-link scenarios.
final routerProvider = Provider<GoRouter>((ref) => _createRouter());

GoRouter _createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.home,
    routes: [
      // Bottom-nav shell with three branches, each keeping its own stack/state.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.favorites,
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen details, pushed above the shell (hides the bottom bar).
      GoRoute(
        path: '${RoutePaths.bookDetails}/:workId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final workId = state.pathParameters['workId']!;
          final initial = state.extra is BookRef ? state.extra as BookRef : null;
          return BookDetailsScreen(workId: workId, initial: initial);
        },
      ),

      // Full-screen reader. Requires [ReaderArgs] via `extra`.
      GoRoute(
        path: RoutePaths.reader,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra;
          if (args is! ReaderArgs) return const _MissingArgsScreen();
          return ReaderScreen(args: args);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text('Page not found', style: AppTextStyles.body),
      ),
    ),
  );
}

class _MissingArgsScreen extends StatelessWidget {
  const _MissingArgsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Text(
          'Nothing to read here.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
