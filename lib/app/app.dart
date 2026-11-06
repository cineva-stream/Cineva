import 'package:flutter/material.dart';

import '../core/platform/cineva_scroll_behavior.dart';
import 'routes/app_router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Root widget for Cineva application.
class CinevaApp extends StatelessWidget {
  const CinevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cineva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      scrollBehavior: const CinevaScrollBehavior(),
      builder: (context, child) {
        return Container(
          color: AppColors.background,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
