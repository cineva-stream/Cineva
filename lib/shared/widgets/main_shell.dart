import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import 'exit_confirmation_bottom_sheet.dart';

/// Lightweight, modern, and minimalist bottom navigation shell.
///
/// Designed for maximum performance with zero frame drops on 4GB RAM devices:
/// - Pure static rendering (no heavy animations or layout shifts)
/// - Opaque obsidian surface (removes expensive GPU BackdropFilter blurs)
/// - Edge-to-edge system navigation bar padding
/// - Centralized PopScope: back button always lands on Beranda, and on Beranda shows smooth exit bottom sheet
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/watchlist')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/history')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/watchlist');
        break;
      case 2:
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final currentIndex = _currentIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final currentIdx = _currentIndex(context);
        if (currentIdx != 0) {
          // If anywhere other than Beranda, back button returns to Beranda
          context.go('/');
        } else {
          // If already on Beranda, show smooth exit confirmation bottom sheet
          await ExitConfirmationBottomSheet.show(context);
        }
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: child,
        bottomNavigationBar: Container(
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
                  onTap: () => _onTap(context, 0),
                ),
                _NavTab(
                  icon: Icons.bookmark_border_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  label: s.navWatchlist,
                  isActive: currentIndex == 1,
                  isCompact: isCompact,
                  onTap: () => _onTap(context, 1),
                ),
                _NavTab(
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  label: s.navSearch,
                  isActive: currentIndex == 2,
                  isCompact: isCompact,
                  onTap: () => _onTap(context, 2),
                ),
                _NavTab(
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_rounded,
                  label: s.navHistory,
                  isActive: currentIndex == 3,
                  isCompact: isCompact,
                  onTap: () => _onTap(context, 3),
                ),
                _NavTab(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: s.navSettings,
                  isActive: currentIndex == 4,
                  isCompact: isCompact,
                  onTap: () => _onTap(context, 4),
                ),
              ],
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
