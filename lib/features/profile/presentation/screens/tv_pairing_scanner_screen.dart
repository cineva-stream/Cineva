import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/profile_sync_sender.dart';
import '../providers/profile_provider.dart';

/// Interactive QR Scanner on Android Smartphone to pair and sync user profile
/// to Android TV or Windows Desktop instantly.
///
/// Supports automatic dual-path transmission:
/// 1. Fast Local Wi-Fi (< 50ms)
/// 2. Zero-Config End-to-End Encrypted Cloud Relay (over 4G/5G mobile cellular)
class TvPairingScannerScreen extends ConsumerStatefulWidget {
  const TvPairingScannerScreen({super.key});

  @override
  ConsumerState<TvPairingScannerScreen> createState() =>
      _TvPairingScannerScreenState();
}

class _TvPairingScannerScreenState extends ConsumerState<TvPairingScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _cameraController;
  late final AnimationController _laserController;

  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.isEmpty) continue;

      final parsed = ParsedPairingQr.tryParse(rawValue);
      if (parsed != null) {
        final s = ref.read(appStringsProvider);
        HapticFeedback.mediumImpact();
        setState(() {
          _isProcessing = true;
          _statusText = s.scannerConnecting;
        });

        await _transferProfile(parsed);
        break;
      }
    }
  }

  Future<void> _transferProfile(ParsedPairingQr qrData) async {
    final s = ref.read(appStringsProvider);
    final profile = ref.read(userProfileProvider);

    setState(() {
      _statusText = s.scannerSending(profile.name);
    });

    final result = await ProfileSyncSender.sendProfile(
      qrData: qrData,
      profile: profile,
    );

    if (!mounted) return;

    if (result.success) {
      HapticFeedback.heavyImpact();
      _showSuccessDialog(result.usedCloudRelay);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _isProcessing = false;
        _statusText = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(
            result.errorMessage ?? s.scannerFailed,
            style: GoogleFonts.inter(color: Colors.white),
          ),
          action: SnackBarAction(
            label: s.retry,
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _showSuccessDialog(bool usedCloudRelay) {
    final s = ref.read(appStringsProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFF141420),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 32,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                )
                    .animate()
                    .scale(duration: 400.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 20),

                Text(
                  s.tvSyncSuccessTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  usedCloudRelay
                      ? s.scannerSuccessViaCloud
                      : s.scannerSuccessViaLan,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // close dialog
                      Navigator.of(context).pop(); // back to settings
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      s.scannerDone,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualEntryDialog() {
    final s = ref.read(appStringsProvider);
    final topicCtrl = TextEditingController();
    final keyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF141420),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dialpad_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      s.scannerManualDialogTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  s.scannerManualDialogDesc,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: topicCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: s.scannerManualTopicLabel,
                    labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: keyCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: s.scannerManualKeyLabel,
                    labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(s.scannerCancelBtn, style: GoogleFonts.inter(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final topic = topicCtrl.text.trim();
                        final key = keyCtrl.text.trim();
                        if (topic.isNotEmpty && key.isNotEmpty) {
                          Navigator.of(ctx).pop();
                          _transferProfile(ParsedPairingQr(topic: topic, key: key));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(s.scannerSendBtn, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    const scanBoxSize = 260.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Mobile Scanner Camera Preview
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // 2. Translucent Cutout Background Overlay
          CustomPaint(
            size: Size.infinite,
            painter: _ScannerOverlayPainter(
              boxSize: scanBoxSize,
              borderColor: AppColors.primary,
            ),
          ),

          // 3. Animated Laser Scanning Line
          Center(
            child: SizedBox(
              width: scanBoxSize - 20,
              height: scanBoxSize - 20,
              child: AnimatedBuilder(
                animation: _laserController,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, (_laserController.value * 2) - 1),
                    child: Container(
                      height: 2.5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.0),
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. Top Header with Back, Title & Flash Toggle
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  Text(
                    s.scannerTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          color: Colors.black87,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await _cameraController.toggleTorch();
                      setState(() => _isTorchOn = !_isTorchOn);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isTorchOn
                            ? AppColors.primary
                            : Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isTorchOn ? Colors.black : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Instruction & Manual Entry Button (Without network badge)
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.scannerInstructions,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: Colors.white70,
                      shadows: [
                        const Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Manual entry fallback button
                  TextButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard_alt_outlined, size: 17, color: AppColors.primaryLight),
                    label: Text(
                      s.scannerManualEntryBtn,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Processing / Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusText ?? s.scannerConnecting,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.scannerDoNotClose,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter that creates a darkened backdrop with a rounded transparent viewport
/// and stylish corner accent brackets.
class _ScannerOverlayPainter extends CustomPainter {
  final double boxSize;
  final Color borderColor;

  const _ScannerOverlayPainter({
    required this.boxSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double left = (size.width - boxSize) / 2;
    final double top = (size.height - boxSize) / 2;
    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    // Darkened background outside cutout
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(bgPath, bgPaint);

    // Subtle outline
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, outlinePaint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;
    const radius = 20.0;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + radius + cornerLength)
        ..lineTo(left, top + radius)
        ..arcToPoint(Offset(left + radius, top), radius: const Radius.circular(radius))
        ..lineTo(left + radius + cornerLength, top),
      cornerPaint,
    );

    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(left + boxSize - radius - cornerLength, top)
        ..lineTo(left + boxSize - radius, top)
        ..arcToPoint(Offset(left + boxSize, top + radius), radius: const Radius.circular(radius))
        ..lineTo(left + boxSize, top + radius + cornerLength),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + boxSize - radius - cornerLength)
        ..lineTo(left, top + boxSize - radius)
        ..arcToPoint(Offset(left + radius, top + boxSize), radius: const Radius.circular(radius))
        ..lineTo(left + radius + cornerLength, top + boxSize),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(left + boxSize - radius - cornerLength, top + boxSize)
        ..lineTo(left + boxSize - radius, top + boxSize)
        ..arcToPoint(Offset(left + boxSize, top + boxSize - radius), radius: const Radius.circular(radius))
        ..lineTo(left + boxSize, top + boxSize - radius - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.boxSize != boxSize || oldDelegate.borderColor != borderColor;
}
