import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform/cineva_scroll_behavior.dart';
import '../features/player/presentation/widgets/mini_player_overlay.dart';
import '../features/updater/presentation/providers/app_update_provider.dart';
import '../features/updater/presentation/screens/mandatory_update_screen.dart';
import 'routes/app_router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Root widget for Cineva application.
class CinevaApp extends ConsumerWidget {
  const CinevaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMandatoryUpdate = ref.watch(
      appUpdateProvider.select(
        (state) => state.updateInfo?.isMandatoryUpdate == true,
      ),
    );

    return MaterialApp.router(
      title: 'Cineva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      scrollBehavior: const CinevaScrollBehavior(),
      builder: (context, child) {
        return Container(
          color: AppColors.background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              const MiniPlayerOverlay(),
              if (isMandatoryUpdate)
                const Positioned.fill(
                  child: MandatoryUpdateScreen(),
                ),
            ],
          ),
        );
      },
    );
  }
}
