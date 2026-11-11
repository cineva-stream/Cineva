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
    final width = widget.isTv ? 96.0 : 88.0;
    final itemWidth = widget.isTv ? 76.0 : 70.0;

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
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Stack(
        children: [
          // Subtle 1px right border overlay that does not shift horizontal centering
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 1.0,
            child: Container(color: Colors.white.withValues(alpha: 0.06)),
          ),
          // Content centered across the full width of the rail
          SafeArea(
            left: false,
            right: false,
            top: false,
            bottom: true,
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 18),
                  // Top App Brand Logo (pinned at the top, perfectly centered horizontally)
                  Center(
                    child: Image.asset(
                      'assets/images/logo_cineva.png',
                      width: widget.isTv ? 48 : 42,
                      height: widget.isTv ? 48 : 42,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Navigation Items centered vertically within remaining space,
                  // and strictly centered horizontally along the exact same vertical axis
                  Expanded(
                    child: Center(
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (
                                int index = 0;
                                index < destinations.length;
                                index++
                              ) ...[
                                if (index > 0) const SizedBox(height: 8),
                                Builder(
                                  builder: (context) {
                                    final item = destinations[index];
                                    final isSelected =
                                        widget.currentIndex == index;

                                    return FocusTraversalOrder(
                                      order: NumericFocusOrder(
                                        index.toDouble(),
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: itemWidth,
                                          child: TvFocusable(
                                            focusNode: _focusNodes[index],
                                            focusedScale: 1.04,
                                            glowBlurRadius: 10,
                                            glowSpreadRadius: 0,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            onTap: () => widget
                                                .onDestinationSelected(index),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              width: itemWidth,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 9,
                                                    horizontal: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.primary
                                                          .withValues(
                                                            alpha: 0.16,
                                                          )
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: isSelected
                                                    ? Border.all(
                                                        color: AppColors.primary
                                                            .withValues(
                                                              alpha: 0.35,
                                                            ),
                                                        width: 1.0,
                                                      )
                                                    : Border.all(
                                                        color:
                                                            Colors.transparent,
                                                        width: 1.0,
                                                      ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Center(
                                                    child: Icon(
                                                      isSelected
                                                          ? item.activeIcon
                                                          : item.icon,
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : AppColors.textMuted,
                                                      size: widget.isTv
                                                          ? 25
                                                          : 22,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: Text(
                                                      item.label,
                                                      maxLines: 1,
                                                      textAlign:
                                                          TextAlign.center,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: widget.isTv
                                                            ? 11.0
                                                            : 10.0,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                        color: isSelected
                                                            ? AppColors.primary
                                                            : AppColors
                                                                  .textMuted,
                                                        letterSpacing: 0.1,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
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
