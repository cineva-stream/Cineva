import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';

/// Interactive 1:1 Avatar Cropping Screen.
class AvatarCropScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const AvatarCropScreen({
    super.key,
    required this.imagePath,
  });

  @override
  ConsumerState<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends ConsumerState<AvatarCropScreen> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transController = TransformationController();
  int _quarterTurns = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
  }

  void _rotateImage() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _transController.value = Matrix4.identity();
    });
  }

  void _resetTransform() {
    setState(() {
      _quarterTurns = 0;
      _transController.value = Matrix4.identity();
    });
  }

  Future<void> _cropAndSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary is not ready');
      }

      // Render at 3.0 pixel ratio for high DPI crispness
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode image bytes');
      }

      final buffer = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedFile = File('${dir.path}/cineva_avatar_$timestamp.png');
      await savedFile.writeAsBytes(buffer);

      if (mounted) {
        Navigator.of(context).pop(savedFile.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              'Gagal memotong gambar: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final size = MediaQuery.of(context).size;
    final double cropSize = (size.width - 48).clamp(240.0, 340.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          s.cropTitle,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: s.cropRotateTooltip,
            icon: const Icon(Icons.rotate_90_degrees_cw_rounded,
                color: AppColors.primary, size: 22),
            onPressed: _rotateImage,
          ),
          IconButton(
            tooltip: s.cropResetTooltip,
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary, size: 22),
            onPressed: _resetTransform,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // ── Instruction banner ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                s.cropInstruction,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Crop Viewport Area ──
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Captured Layer (Clean square without overlays)
                  RepaintBoundary(
                    key: _cropKey,
                    child: Container(
                      width: cropSize,
                      height: cropSize,
                      color: Colors.black,
                      child: ClipRect(
                        child: InteractiveViewer(
                          transformationController: _transController,
                          minScale: 0.8,
                          maxScale: 4.5,
                          boundaryMargin: const EdgeInsets.all(500),
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: _quarterTurns,
                              child: Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Interactive Guides Overlay (Rule of thirds + Circle Preview)
                  IgnorePointer(
                    child: SizedBox(
                      width: cropSize,
                      height: cropSize,
                      child: Stack(
                        children: [
                          // Square Outer Border
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),

                          // Circular Mask Guide
                          Center(
                            child: Container(
                              width: cropSize,
                              height: cropSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          // Rule of Thirds Grid Lines
                          CustomPaint(
                            size: Size(cropSize, cropSize),
                            painter: _CropGridPainter(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Bottom Action Buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  // Batal
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        s.cropCancel,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Gunakan Avatar
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _cropAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded,
                                      color: Colors.black, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.cropUseAvatar,
                                    style: GoogleFonts.outfit(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    final oneThirdW = size.width / 3;
    final twoThirdW = size.width * 2 / 3;
    final oneThirdH = size.height / 3;
    final twoThirdH = size.height * 2 / 3;

    // Vertical lines
    canvas.drawLine(Offset(oneThirdW, 0), Offset(oneThirdW, size.height), paint);
    canvas.drawLine(Offset(twoThirdW, 0), Offset(twoThirdW, size.height), paint);

    // Horizontal lines
    canvas.drawLine(Offset(0, oneThirdH), Offset(size.width, oneThirdH), paint);
    canvas.drawLine(Offset(0, twoThirdH), Offset(size.width, twoThirdH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
