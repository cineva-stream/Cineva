import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/search/presentation/screens/search_screen.dart';
import 'exit_confirmation_bottom_sheet.dart';

/// Wraps individual shell pages with a predictive-back-safe [PopScope].
///
/// On Android 13/14+ (predictive back gestures) and older Android hardware back buttons:
/// - If current route is NOT Beranda ('/'), back navigation reliably navigates to Beranda and resets search state.
/// - If current route IS Beranda, it triggers the smooth [ExitConfirmationBottomSheet].
class ShellPopScope extends ConsumerWidget {
  final Widget child;
  final bool isHome;

  const ShellPopScope({
    super.key,
    required this.child,
    this.isHome = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!isHome) {
          try {
            resetSearchState(ref);
          } catch (_) {
            // Safely ignored if invoked in isolated unit tests without ProviderScope
          }
          context.go('/');
        } else {
          await ExitConfirmationBottomSheet.show(context);
        }
      },
      child: child,
    );
  }
}
