import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/platform/device_form_factor.dart';
import '../../features/live_tv/presentation/providers/live_tv_providers.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import 'adaptive_nav_rail.dart';
import 'desktop_window_caption.dart';
import 'exit_confirmation_bottom_sheet.dart';

/// Lightweight, modern, and adaptive navigation shell.
///
/// Automatically adapts to device form factor:
/// - Smartphone: BottomNavigationBar with edge-to-edge system padding.
/// - Android TV & Windows Desktop: Modern Left Navigation Rail with D-Pad focus & hover states.
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/live-tv')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/history')) return 3;
    if (location.startsWith('/settings')) return 4;
    if (location == '/' || location.startsWith('/?')) return 0;
    return -1;
  }

  int _currentRailIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/live-tv')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/watchlist')) return 3;
    if (location.startsWith('/history')) return 4;
    if (location.startsWith('/settings')) return 5;
    if (location == '/' || location.startsWith('/?')) return 0;
    return 0;
  }

  void _onTapBottomNav(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        resetSearchState(ref);
        context.go('/');
        break;
      case 1:
        context.go('/live-tv');
        break;
      case 2:
        if (_currentIndex(context) == 2 &&
            ref.read(searchQueryProvider).isNotEmpty) {
          resetSearchState(ref);
        }
        context.go('/search');
        break;
      case 3:
        context.go('/history');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  void _onTapRail(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        resetSearchState(ref);
        context.go('/');
        break;
      case 1:
        context.go('/live-tv');
        break;
      case 2:
        if (_currentRailIndex(context) == 2 &&
            ref.read(searchQueryProvider).isNotEmpty) {
          resetSearchState(ref);
        }
        context.go('/search');
        break;
      case 3:
        context.go('/watchlist');
        break;
      case 4:
        context.go('/history');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final currentIndex = _currentIndex(context);
    final location = GoRouterState.of(context).uri.toString();
    final isWatchlist = location.startsWith('/watchlist');
    final isLiveTv = location.startsWith('/live-tv');
    final isLiveTvPlaying = ref.watch(liveTvIsPlayingProvider);
    final isLiveTvFullscreen = ref.watch(liveTvFullscreenProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    final isTv = ref.watch(isTvProvider);
    final isWideScreen = isWideScreenLayout(context, isTv: isTv);

    // Smoothly hide bottom nav bar when on Watchlist or when Live TV is actively streaming
    final bool shouldHideBottomNav =
        isWatchlist || (isLiveTv && (isLiveTvPlaying || isLiveTvFullscreen));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isLiveTv && (isLiveTvFullscreen || isLiveTvPlaying)) {
          ref.read(liveTvFullscreenProvider.notifier).state = false;
          ref.read(liveTvIsPlayingProvider.notifier).state = false;
          context.go('/');
          return;
        }
        if (isWatchlist) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
          return;
        }
        final currentIdx = _currentIndex(context);
        if (currentIdx != 0) {
          // If anywhere other than Beranda, back button returns to Beranda and resets search
          resetSearchState(ref);
          context.go('/');
        } else {
          // If already on Beranda, show smooth exit confirmation bottom sheet
          await ExitConfirmationBottomSheet.show(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: !isWideScreen,
        extendBodyBehindAppBar: !isWideScreen,
        body: isWideScreen
            ? Column(
                children: [
                  const DesktopWindowCaption(title: 'Cineva'),
                  Expanded(
                    child: Row(
                      children: [
                        AdaptiveNavRail(
                          currentIndex: _currentRailIndex(context),
                          onDestinationSelected: (idx) => _onTapRail(context, ref, idx),
                          isTv: isTv,
                        ),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              )
            : child,
        bottomNavigationBar: isWideScreen
            ? null
            : (isLiveTvFullscreen && isLiveTv)
                ? null
                : AnimatedSlide(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    offset: shouldHideBottomNav ? const Offset(0, 1.2) : Offset.zero,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                      opacity: shouldHideBottomNav ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: shouldHideBottomNav,
                        child: Container(
                          padding: EdgeInsets.only(bottom: bottomPadding),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            height: isCompact ? 56 : 60,
                            child: Row(
                              children: [
                                _NavTab(
                                  icon: Icons.home_outlined,
                                  activeIcon: Icons.home_rounded,
                                  label: s.navHome,
                                  isActive: currentIndex == 0,
                                  isCompact: isCompact,
                                  onTap: () => _onTapBottomNav(context, ref, 0),
                                ),
                                _NavTab(
                                  icon: Icons.live_tv_outlined,
                                  activeIcon: Icons.live_tv_rounded,
                                  label: s.navLiveTv,
                                  isActive: currentIndex == 1,
                                  isCompact: isCompact,
                                  onTap: () => _onTapBottomNav(context, ref, 1),
                                ),
                                _NavTab(
                                  icon: Icons.search_rounded,
                                  activeIcon: Icons.search_rounded,
                                  label: s.navSearch,
                                  isActive: currentIndex == 2,
                                  isCompact: isCompact,
                                  onTap: () => _onTapBottomNav(context, ref, 2),
                                ),
                                _NavTab(
                                  icon: Icons.history_rounded,
                                  activeIcon: Icons.history_rounded,
                                  label: s.navHistory,
                                  isActive: currentIndex == 3,
                                  isCompact: isCompact,
                                  onTap: () => _onTapBottomNav(context, ref, 3),
                                ),
                                _NavTab(
                                  icon: Icons.settings_outlined,
                                  activeIcon: Icons.settings_rounded,
                                  label: s.navSettings,
                                  isActive: currentIndex == 4,
                                  isCompact: isCompact,
                                  onTap: () => _onTapBottomNav(context, ref, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

/// Static, minimalist navigation tab with zero animation overhead and adaptive scaling for 720p screens.
class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final bool isCompact;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textMuted;
    final displayIcon = (isActive && activeIcon != null) ? activeIcon! : icon;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        radius: 30,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              displayIcon,
              size: isCompact ? 20 : 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            SizedBox(height: isCompact ? 3 : 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: isCompact ? 9.5 : 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
