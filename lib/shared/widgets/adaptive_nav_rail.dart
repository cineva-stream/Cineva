import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import 'tv_focusable.dart';

/// Modern, cinema-styled left navigation rail for Android TV (D-Pad friendly)
/// and Windows Desktop (Mouse & Keyboard friendly).
class AdaptiveNavRail extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isTv;

  const AdaptiveNavRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.isTv = false,
  });

  @override
  ConsumerState<AdaptiveNavRail> createState() => _AdaptiveNavRailState();
}

class _AdaptiveNavRailState extends ConsumerState<AdaptiveNavRail> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final width = widget.isTv ? 92.0 : 88.0;

    final destinations = [
      _NavDestination(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: s.navHome,
      ),
      _NavDestination(
        icon: Icons.live_tv_outlined,
        activeIcon: Icons.live_tv_rounded,
        label: s.navLiveTv,
      ),
      _NavDestination(
        icon: Icons.search_rounded,
        activeIcon: Icons.search_rounded,
        label: s.navSearch,
      ),
      _NavDestination(
        icon: Icons.bookmark_border_rounded,
        activeIcon: Icons.bookmark_rounded,
        label: 'Watchlist',
      ),
      _NavDestination(
        icon: Icons.history_rounded,
        activeIcon: Icons.history_rounded,
        label: s.navHistory,
      ),
      _NavDestination(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: s.navSettings,
      ),
    ];

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Top App Brand Logo (official logo_cineva.png)
            Image.asset(
              'assets/images/logo_cineva.png',
              width: widget.isTv ? 48 : 42,
              height: widget.isTv ? 48 : 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            // Navigation Items
            Expanded(
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: destinations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = destinations[index];
                    final isSelected = widget.currentIndex == index;

                    return FocusTraversalOrder(
                      order: NumericFocusOrder(index.toDouble()),
                      child: TvFocusable(
                        focusNode: _focusNodes[index],
                        focusedScale: 1.04,
                        glowBlurRadius: 10,
                        glowSpreadRadius: 0,
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => widget.onDestinationSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                size: widget.isTv ? 26 : 23,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: widget.isTv ? 11.5 : 10.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
