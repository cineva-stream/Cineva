import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform/cineva_scroll_behavior.dart';
import '../features/backup/data/auto_backup_service.dart';
import '../features/player/presentation/widgets/mini_player_overlay.dart';
import '../features/updater/presentation/providers/app_update_provider.dart';
import '../features/updater/presentation/screens/mandatory_update_screen.dart';
import 'routes/app_router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Root widget for Cineva application.
class CinevaApp extends ConsumerStatefulWidget {
  const CinevaApp({super.key});

  @override
  ConsumerState<CinevaApp> createState() => _CinevaAppState();
}

class _CinevaAppState extends ConsumerState<CinevaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AutoBackupService.checkAndRunScheduledBackup(ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AutoBackupService.checkAndRunScheduledBackup(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
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
