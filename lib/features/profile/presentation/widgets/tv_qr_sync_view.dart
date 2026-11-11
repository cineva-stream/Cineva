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

/// 10-Foot UI presentation for Android TV, Tablet, and Windows Desktop.
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
  bool _isReceiving = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    setState(() {
      _isLoading = true;
      _isReceiving = false;
    });
    try {
      final info = await _pairingService.startSession(
        onStatusChanged: (status) {
          if (!mounted) return;
          if (status == HybridPairingStatus.receiving) {
            setState(() => _isReceiving = true);
          }
        },
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
    final isLandscape = size.width > size.height;
    // Keep side-by-side layout on 720p/1080p landscape TVs (e.g. 640x360, 853x480)
    // and only stack vertically on portrait phones/tablets or very narrow windows.
    final isCompact = size.width < 580 || (!isLandscape && size.width < 760);
    final isShortScreen = size.height < 560;

    if (_isSuccess) {
      return _buildSuccessCelebration();
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1120),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 20 : (isShortScreen ? 28 : 44),
          vertical: isShortScreen ? 12 : 24,
        ),
        child: isCompact
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInstructionsColumn(s, isShortScreen: isShortScreen),
                    const SizedBox(height: 24),
                    _buildQrCard(isShortScreen: isShortScreen),
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
                      child: _buildInstructionsColumn(
                        s,
                        isShortScreen: isShortScreen,
                      ),
                    ),
                  ),
                  SizedBox(width: isShortScreen ? 28 : 48),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildQrCard(isShortScreen: isShortScreen),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInstructionsColumn(dynamic s, {required bool isShortScreen}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cineva Branding Badge
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
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
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: isShortScreen ? 10 : 14),

        // Title
        Text(
          s.isIndonesian
              ? 'Tautkan Akun Cineva Anda'
              : 'Connect Your Cineva Account',
          style: GoogleFonts.outfit(
            fontSize: isShortScreen ? 24 : 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),

        SizedBox(height: isShortScreen ? 6 : 8),

        // Subtitle
        Text(
          s.isIndonesian
              ? 'Pindai QR code ini melalui aplikasi Cineva di handphone Anda. Bekerja otomatis baik di Wi-Fi rumah maupun paket data seluler (4G/5G).'
              : 'Scan this QR code from your Cineva smartphone app. Works seamlessly over home Wi-Fi and mobile cellular (4G/5G).',
          style: GoogleFonts.inter(
            fontSize: isShortScreen ? 12.5 : 13.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),

        SizedBox(height: isShortScreen ? 14 : 22),

        // 3-Step Guided Instructions
        _buildStepItem(
          number: '1',
          icon: Icons.phone_android_rounded,
          title: s.isIndonesian
              ? 'Buka Cineva di Handphone'
              : 'Open Cineva on Smartphone',
          desc: s.isIndonesian
              ? 'Gunakan aplikasi Cineva di smartphone Android Anda'
              : 'Launch the Cineva Android app',
          isShortScreen: isShortScreen,
        ),
        SizedBox(height: isShortScreen ? 8 : 10),
        _buildStepItem(
          number: '2',
          icon: Iconsax.scan_barcode,
          title: s.isIndonesian
              ? 'Pilih "Tautkan ke TV"'
              : 'Select "Connect to TV"',
          desc: s.isIndonesian
              ? 'Masuk ke Pengaturan ➔ Tautkan ke Android TV / PC'
              : 'Go to Settings ➔ Connect to Android TV / PC',
          isShortScreen: isShortScreen,
        ),
        SizedBox(height: isShortScreen ? 8 : 10),
        _buildStepItem(
          number: '3',
          icon: Icons.qr_code_scanner_rounded,
          title: s.isIndonesian
              ? 'Pindai QR Code di Samping'
              : 'Scan the QR Code Beside',
          desc: s.isIndonesian
              ? 'Arahkan kamera ponsel Anda untuk sinkronisasi instan'
              : 'Aim your phone camera for instant transfer',
          isShortScreen: isShortScreen,
        ),

        SizedBox(height: isShortScreen ? 16 : 26),

        // Action Buttons (TV D-Pad & Mouse friendly)
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            TvFocusable(
              autofocus: true,
              showFocusBorder: true,
              focusedScale: 1.05,
              glowBlurRadius: 16,
              borderRadius: BorderRadius.circular(12),
              onTap: _skipAsGuest,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: isShortScreen ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderFocused,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.isIndonesian
                          ? 'Masuk sebagai Tamu'
                          : 'Continue as Guest',
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
            if (widget.showManualOption && widget.onSwitchToManual != null)
              TvFocusable(
                showFocusBorder: true,
                focusedScale: 1.05,
                glowBlurRadius: 16,
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onSwitchToManual,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: isShortScreen ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.isIndonesian
                            ? 'Setup Manual di PC'
                            : 'Manual PC Setup',
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
            TvFocusable(
              showFocusBorder: true,
              focusedScale: 1.05,
              glowBlurRadius: 14,
              borderRadius: BorderRadius.circular(12),
              onTap: _isLoading ? null : _startSession,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: isShortScreen ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.isIndonesian ? 'Muat Ulang QR' : 'Refresh QR',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    required bool isShortScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isShortScreen ? 8 : 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isShortScreen ? 30 : 34,
            height: isShortScreen ? 30 : 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.outfit(
                  color: AppColors.primaryLight,
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: isShortScreen ? 12.5 : 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: isShortScreen ? 10.5 : 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            icon,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard({required bool isShortScreen}) {
    final s = ref.watch(appStringsProvider);
    final qrSize = isShortScreen ? 156.0 : 206.0;

    if (_isLoading) {
      return Container(
        height: isShortScreen ? 260 : 340,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderFocused),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_sessionInfo == null) {
      return Container(
        height: isShortScreen ? 260 : 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderFocused),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.primary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              s.isIndonesian
                  ? 'Gagal membuat sesi QR'
                  : 'Failed to start QR session',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TvFocusable(
              showFocusBorder: true,
              borderRadius: BorderRadius.circular(10),
              onTap: _startSession,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.isIndonesian ? 'Coba Lagi' : 'Retry',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isShortScreen ? 18 : 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.32),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Image Frame
          Container(
            padding: EdgeInsets.all(isShortScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: QrImageView(
              data: _sessionInfo!.qrPayload,
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.background,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.background,
              ),
              embeddedImage: const AssetImage('assets/images/cineva_icon.png'),
              embeddedImageStyle: QrEmbeddedImageStyle(
                size: Size(
                  isShortScreen ? 30 : 38,
                  isShortScreen ? 30 : 38,
                ),
              ),
            ),
          ),

          SizedBox(height: isShortScreen ? 12 : 18),

          // Listening Radar or Receiving Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isReceiving) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s.tvSyncReceiving,
                  style: GoogleFonts.inter(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ] else ...[
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
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.3, 1.3),
                      duration: 800.ms,
                    ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    s.tvSyncWaitingScan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: isShortScreen ? 8 : 12),

          // Network & PIN Info Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              s.tvSyncAlternativeCode(_sessionInfo!.pinCode),
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
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
          color: AppColors.surface,
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
            ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  s.tvSyncSuccessTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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

            if ((_syncedWatchlistCount ?? 0) > 0 ||
                (_syncedHistoryCount ?? 0) > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  s.tvSyncSummaryText(
                    _syncedWatchlistCount ?? 0,
                    _syncedHistoryCount ?? 0,
                  ),
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
