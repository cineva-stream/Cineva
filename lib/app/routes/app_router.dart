import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/detail/presentation/screens/movie_detail_screen.dart';
import '../../features/detail/presentation/screens/tv_detail_screen.dart';
import '../../features/player/presentation/screens/player_screen.dart';
import '../../features/watchlist/presentation/screens/watchlist_screen.dart';
import '../../features/history/presentation/screens/watch_history_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/download/presentation/screens/download_list_screen.dart';
import '../../features/settings/data/legal_content.dart';
import '../../features/settings/presentation/screens/legal_document_screen.dart';
import '../../features/settings/presentation/screens/about_info_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shell_pop_scope.dart';

/// Application route configuration using GoRouter.
///
/// Uses a [ShellRoute] for the bottom navigation bar, with nested
/// routes for each tab. Detail and player screens navigate outside
/// the shell (full-screen) with smooth transitions.
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ── Splash Screen ──
    GoRoute(
      path: '/splash',
      name: 'splash',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),

    // ── Shell: Bottom Navigation ──
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ShellPopScope(isHome: true, child: HomeScreen()),
          ),
        ),
        GoRoute(
          path: '/watchlist',
          name: 'watchlist',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ShellPopScope(child: WatchlistScreen()),
          ),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ShellPopScope(child: SearchScreen()),
          ),
        ),
        GoRoute(
          path: '/history',
          name: 'watchHistory',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ShellPopScope(child: WatchHistoryScreen()),
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ShellPopScope(child: SettingsScreen()),
          ),
        ),
      ],
    ),

    // ── Full-screen routes (outside bottom nav shell) ──
    GoRoute(
      path: '/movie/:id',
      name: 'movieDetail',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CustomTransitionPage(
          key: state.pageKey,
          child: MovieDetailScreen(movieId: id),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/tv/:id',
      name: 'tvDetail',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CustomTransitionPage(
          key: state.pageKey,
          child: TvDetailScreen(tvId: id),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return CustomTransitionPage(
          key: state.pageKey,
          child: PlayerScreen(
            magnetLink: extra['magnetLink'] as String? ?? '',
            title: extra['title'] as String? ?? '',
            imdbId: extra['imdbId'] as String?,
            season: extra['season'] as int?,
            episode: extra['episode'] as int?,
            tmdbId: extra['tmdbId'] as int?,
            mediaType: extra['mediaType'] as String?,
            posterPath: extra['posterPath'] as String?,
            backdropPath: extra['backdropPath'] as String?,
            episodeTitle: extra['episodeTitle'] as String?,
            initialPositionMs: extra['initialPositionMs'] as int?,
            localVideoPath: extra['localVideoPath'] as String?,
            localSubtitlePath: extra['localSubtitlePath'] as String?,
          ),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/downloads',
      name: 'downloads',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DownloadListScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    ),
    // ── Settings Legal & Info Routes ──
    GoRoute(
      path: '/settings/privacy-policy',
      name: 'settingsPrivacyPolicy',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LegalDocumentScreen(type: LegalDocType.privacyPolicy),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings/terms',
      name: 'settingsTerms',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LegalDocumentScreen(type: LegalDocType.termsAndConditions),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings/disclaimer',
      name: 'settingsDisclaimer',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LegalDocumentScreen(type: LegalDocType.disclaimer),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings/info',
      name: 'settingsInfo',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AboutInfoScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    ),
  ],
);
