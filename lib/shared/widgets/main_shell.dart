import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

/// Lightweight, modern, and minimalist bottom navigation shell.
///
/// Designed for maximum performance with zero frame drops on 4GB RAM devices:
/// - Pure static rendering (no heavy animations or layout shifts)
/// - Opaque obsidian surface (removes expensive GPU BackdropFilter blurs)
/// - Edge-to-edge system navigation bar padding
class MainShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: child,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.6,
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
          height: 60,
          child: Row(
            children: [
              _NavTab(
                icon: Iconsax.home_2,
                label: 'Beranda',
                isActive: currentIndex == 0,
                onTap: () => _onTap(context, 0),
              ),
              _NavTab(
                icon: Iconsax.bookmark,
                label: 'Watchlist',
                isActive: currentIndex == 1,
                onTap: () => _onTap(context, 1),
              ),
              _NavTab(
                icon: Iconsax.search_normal_1,
                label: 'Cari',
                isActive: currentIndex == 2,
                onTap: () => _onTap(context, 2),
              ),
              _NavTab(
                icon: Iconsax.clock,
                label: 'Riwayat',
                isActive: currentIndex == 3,
                onTap: () => _onTap(context, 3),
              ),
              _NavTab(
                icon: Iconsax.setting_2,
                label: 'Pengaturan',
                isActive: currentIndex == 4,
                onTap: () => _onTap(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static, minimalist navigation tab with zero animation overhead.
class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textMuted;

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
              icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
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
