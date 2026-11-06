import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../data/hybrid_pairing_service.dart';
import '../providers/profile_provider.dart';
import '../widgets/avatar_display.dart';

/// 10-Foot UI presentation for Android TV and Windows Desktop.
///
/// Displays a high-contrast QR code for instant smartphone profile pairing,
/// operating over both Local Wi-Fi and 4G/5G mobile cellular via Cloud Relay.
class TvQrSyncView extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToManual;
  final bool showManualOption;

  const TvQrSyncView({
    super.key,
    this.onSwitchToManual,
    this.showManualOption = false,
  });

  @override
  ConsumerState<TvQrSyncView> createState() => _TvQrSyncViewState();
}

class _TvQrSyncViewState extends ConsumerState<TvQrSyncView> {
  final HybridPairingService _pairingService = HybridPairingService();
  PairingSessionInfo? _sessionInfo;
  bool _isLoading = true;
  String? _syncedUserName;
  String? _syncedAvatarId;
  String? _syncedAvatarPath;
  int? _syncedWatchlistCount;
  int? _syncedHistoryCount;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    try {
      final info = await _pairingService.startSession(
        onProfileReceived: (data) async {
          if (!mounted) return;
          final result = await HybridPairingService.applySyncedProfile(
            ref: ref,
            data: data,
          );
          final updated = result.profile;

          if (mounted) {
            setState(() {
              _isSuccess = true;
              _syncedUserName = updated.name;
              _syncedAvatarId = updated.avatarId;
              _syncedAvatarPath = updated.customAvatarPath;
              _syncedWatchlistCount = result.watchlistCount;
              _syncedHistoryCount = result.historyCount;
            });

            // Smooth transition to Home Screen after congratulatory visual
            Future.delayed(const Duration(milliseconds: 1600), () {
              if (mounted) {
                context.go('/');
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _sessionInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pairingService.stopSession();
    super.dispose();
  }

  Future<void> _skipAsGuest() async {
    _pairingService.stopSession();
    await ref.read(userProfileProvider.notifier).skipOnboarding();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 800;

    if (_isSuccess) {
      return _buildSuccessCelebration();
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 20 : 40, vertical: 24),
        child: isCompact
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInstructionsColumn(s),
                    const SizedBox(height: 24),
                    _buildQrCard(),
                  ],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildInstructionsColumn(s),
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildQrCard(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInstructionsColumn(dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cineva Branding Badge
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CINEVA TV SYNC',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Title
        Text(
          s.isIndonesian ? 'Tautkan Akun Cineva Anda' : 'Connect Your Cineva Account',
          style: GoogleFonts.outfit(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          s.isIndonesian
              ? 'Pindai QR code ini melalui aplikasi Cineva di handphone Anda. Bekerja otomatis baik di Wi-Fi rumah maupun paket data seluler (4G/5G).'
              : 'Scan this QR code from your Cineva smartphone app. Works seamlessly over home Wi-Fi and mobile cellular (4G/5G).',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFFB0B0C4),
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        // 3-Step Guided Instructions
        _buildStepItem(
          number: '1',
          icon: Icons.phone_android_rounded,
          title: s.isIndonesian ? 'Buka Cineva di Handphone' : 'Open Cineva on Smartphone',
          desc: s.isIndonesian ? 'Gunakan aplikasi Cineva di smartphone Android Anda' : 'Launch the Cineva Android app',
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          number: '2',
          icon: Iconsax.scan_barcode,
          title: s.isIndonesian ? 'Pilih "Tautkan ke TV"' : 'Select "Connect to TV"',
          desc: s.isIndonesian ? 'Masuk ke Pengaturan ➔ Tautkan ke Android TV / PC' : 'Go to Settings ➔ Connect to Android TV / PC',
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          number: '3',
          icon: Icons.qr_code_scanner_rounded,
          title: s.isIndonesian ? 'Pindai QR Code di Samping' : 'Scan the QR Code Beside',
          desc: s.isIndonesian ? 'Arahkan kamera ponsel Anda untuk sinkronisasi instan' : 'Aim your phone camera for instant transfer',
        ),

        const SizedBox(height: 28),

        // Action Buttons (TV D-Pad & Mouse friendly)
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            TvFocusable(
              focusedScale: 1.05,
              glowBlurRadius: 14,
              borderRadius: BorderRadius.circular(12),
              onTap: _skipAsGuest,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      s.isIndonesian ? 'Masuk sebagai Tamu' : 'Continue as Guest',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.showManualOption && widget.onSwitchToManual != null) ...[
              TvFocusable(
                focusedScale: 1.05,
                glowBlurRadius: 14,
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onSwitchToManual,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.keyboard_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        s.isIndonesian ? 'Setup Manual di PC' : 'Manual PC Setup',
                        style: GoogleFonts.inter(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required String number,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrCard() {
    final s = ref.watch(appStringsProvider);
    if (_isLoading || _sessionInfo == null) {
      return Container(
        height: 340,
        decoration: BoxDecoration(
          color: const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Image Frame
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: QrImageView(
              data: _sessionInfo!.qrPayload,
              version: QrVersions.auto,
              size: 210,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F0F14),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F0F14),
              ),
              embeddedImage: const AssetImage('assets/images/cineva_icon.png'),
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(38, 38),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Listening Radar Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3), duration: 800.ms),
              const SizedBox(width: 8),
              Text(
                s.tvSyncWaitingScan,
                style: GoogleFonts.inter(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Network & PIN Info
          Text(
            s.tvSyncAlternativeCode(_sessionInfo!.pinCode),
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCelebration() {
    final s = ref.watch(appStringsProvider);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        decoration: BoxDecoration(
          color: const Color(0xFF141420),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 36,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Avatar
            AvatarDisplay(
              avatarId: _syncedAvatarId ?? 'avatar_popcorn',
              customAvatarPath: _syncedAvatarPath,
              size: 88,
              showGlow: true,
              borderWidth: 3,
              borderColor: AppColors.primary,
            )
                .animate()
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  s.tvSyncSuccessTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              s.tvSyncWelcomeUser(_syncedUserName ?? s.tvSyncDefaultUser),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryLight,
              ),
            ),

            if ((_syncedWatchlistCount ?? 0) > 0 || (_syncedHistoryCount ?? 0) > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  s.tvSyncSummaryText(_syncedWatchlistCount ?? 0, _syncedHistoryCount ?? 0),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 18),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
