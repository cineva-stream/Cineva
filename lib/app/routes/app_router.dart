import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/section_catalog_screen.dart';
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
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/profile/presentation/screens/onboarding_profile_screen.dart';
import '../../features/profile/presentation/screens/legal_agreement_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/cineva_insights_screen.dart';
import '../../features/profile/presentation/screens/tv_pairing_scanner_screen.dart';
import '../../features/live_tv/presentation/screens/live_tv_screen.dart';
import '../../features/live_tv/presentation/screens/live_tv_player_screen.dart';
import '../../features/live_tv/domain/entities/live_tv_channel.dart';
import '../../features/search/domain/entities/streaming_platform.dart';
import '../../features/search/presentation/screens/platform_catalog_screen.dart';
import '../../features/calendar/presentation/screens/airing_calendar_screen.dart';
import '../../features/person/presentation/screens/person_detail_screen.dart';
import '../../features/collection/presentation/screens/collection_detail_screen.dart';
import '../../features/tv_universe/presentation/screens/tv_universe_screen.dart';
import '../../features/watch_party/presentation/screens/watch_party_direct_join_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shell_pop_scope.dart';

/// Application route configuration using GoRouter.
///
/// Uses a [ShellRoute] for the bottom navigation bar, with nested
/// routes for each tab. Detail and player screens navigate outside
/// the shell (full-screen) with smooth transitions.
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final uri = state.uri;
    // Normalize custom scheme deep links: cineva://movie/123, cineva://tv/456, cineva://party/CNV-XXXX
    if (uri.scheme == 'cineva') {
      final host = uri.host.toLowerCase();
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if ((host == 'movie' || host == 'tv' || host == 'party') &&
          segments.isNotEmpty) {
        return '/$host/${segments.first}';
      }
      if (host == 'open') {
        return '/';
      }
    }
    // Check query parameters (?watch=movie/123 or ?type=tv&id=456)
    final watchParam = uri.queryParameters['watch'] ?? '';
    final watchMatch =
        RegExp(r'^(movie|tv)/(\d+)$', caseSensitive: false).firstMatch(watchParam);
    if (watchMatch != null) {
      return '/${watchMatch.group(1)!.toLowerCase()}/${watchMatch.group(2)}';
    }
    final qType = (uri.queryParameters['type'] ?? '').toLowerCase();
    final qId = uri.queryParameters['id'] ?? '';
    if ((qType == 'movie' || qType == 'tv') && RegExp(r'^\d+$').hasMatch(qId)) {
      return '/$qType/$qId';
    }
    // Normalize GitHub Pages repository prefix (/Cineva/movie/:id, /Cineva/tv/:id)
    final path = uri.path;
    final movieMatch =
        RegExp(r'^/Cineva/movie/(\d+)', caseSensitive: false).firstMatch(path);
    if (movieMatch != null) {
      return '/movie/${movieMatch.group(1)}';
    }
    final tvMatch =
        RegExp(r'^/Cineva/tv/(\d+)', caseSensitive: false).firstMatch(path);
    if (tvMatch != null) {
      return '/tv/${tvMatch.group(1)}';
    }
    return null;
  },
  observers: [
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
  ],
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

    // ── Onboarding Profile Screen ──
    GoRoute(
      path: '/onboarding-profile',
      name: 'onboarding-profile',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.06);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),

    // ── Onboarding Legal Screen ──
    GoRoute(
      path: '/onboarding-legal',
      name: 'onboarding-legal',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LegalAgreementScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.06, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),

    // ── Edit Profile Screen ──
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EditProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.06, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),

    // ── Cineva Insights & KTP / ATM Member Card Studio Screen ──
    GoRoute(
      path: '/profile/insights',
      name: 'profile-insights',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CinevaInsightsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.06);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),

    // ── TV Pairing QR Scanner Screen (Smartphone) ──
    GoRoute(
      path: '/tv-pairing-scanner',
      name: 'tv-pairing-scanner',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const TvPairingScannerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.08);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
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
          path: '/live-tv',
          name: 'liveTv',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ShellPopScope(child: LiveTvScreen()),
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
          path: '/platform/:id',
          name: 'platformCatalog',
          pageBuilder: (context, state) {
            final platformId = state.pathParameters['id'] ?? 'netflix';
            final platform = StreamingPlatform.fromId(platformId);
            return CustomTransitionPage(
              key: state.pageKey,
              child: PlatformCatalogScreen(platform: platform),
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
            );
          },
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
      path: '/catalog/:sectionKey',
      name: 'sectionCatalog',
      pageBuilder: (context, state) {
        final sectionKey =
            state.pathParameters['sectionKey'] ?? 'popular_movies';
        return CustomTransitionPage(
          key: state.pageKey,
          child: SectionCatalogScreen(sectionKey: sectionKey),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
      },
    ),
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
      path: '/Cineva/movie/:id',
      name: 'movieDetailDeepLinkRepoPath',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CustomTransitionPage(
          key: state.pageKey,
          child: MovieDetailScreen(movieId: id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/Cineva/tv/:id',
      name: 'tvDetailDeepLinkRepoPath',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CustomTransitionPage(
          key: state.pageKey,
          child: TvDetailScreen(tvId: id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    // ── Watch Party Direct Join Deep Link Route ──
    GoRoute(
      path: '/party/:code',
      name: 'watchPartyDeepLink',
      pageBuilder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: WatchPartyDirectJoinScreen(roomCode: code),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/Cineva/party/:code',
      name: 'watchPartyDeepLinkRepoPath',
      pageBuilder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: WatchPartyDirectJoinScreen(roomCode: code),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
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
            overview: extra['overview'] as String?,
          ),
          transitionDuration: const Duration(milliseconds: 340),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/live-tv/player',
      name: 'liveTvPlayer',
      pageBuilder: (context, state) {
        final channel = state.extra as LiveTvChannel?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: LiveTvPlayerScreen(initialChannel: channel),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
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

    GoRoute(
      path: '/feedback',
      name: 'feedback',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FeedbackScreen(),
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
      path: '/calendar',
      name: 'airingCalendar',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiringCalendarScreen(),
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
      path: '/person/:id',
      name: 'personDetail',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final initialName = state.extra as String?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PersonDetailScreen(personId: id, initialName: initialName),
          transitionDuration: const Duration(milliseconds: 320),
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
        );
      },
    ),
    GoRoute(
      path: '/collection/:id',
      name: 'collectionDetail',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: CollectionDetailScreen(
            collectionId: id,
            fallbackPoster: extra?['fallbackPoster'] as String?,
            fallbackBackdrop: extra?['fallbackBackdrop'] as String?,
          ),
          transitionDuration: const Duration(milliseconds: 320),
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
        );
      },
    ),
    GoRoute(
      path: '/tv-universe/:id',
      name: 'tvUniverse',
      pageBuilder: (context, state) {
        final universeId = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: TvUniverseScreen(
            universeId: universeId,
            fallbackPoster: extra?['fallbackPoster'] as String?,
            fallbackBackdrop: extra?['fallbackBackdrop'] as String?,
          ),
          transitionDuration: const Duration(milliseconds: 320),
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
        );
      },
    ),
  ],
);
