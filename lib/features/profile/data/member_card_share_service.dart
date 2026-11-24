import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for rendering the KTP / ATM Member Card [RepaintBoundary]
/// into an Ultra-HD PNG image and sharing it with a humorous default caption
/// across Android (Native Share Sheet) and Windows Desktop.
class MemberCardShareService {
  static const MethodChannel _shareChannel = MethodChannel(
    'com.cinevagroup.cinevastream/share',
  );

  /// Captures the widget associated with [boundaryKey] into PNG bytes at 3.0x resolution.
  static Future<Uint8List?> captureCardPngBytes(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final context = boundaryKey.currentContext;
      if (context == null) return null;
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('MemberCardShareService.captureCardPngBytes error: $e');
      return null;
    }
  }

  /// Shares the captured KTP / ATM Member Card PNG along with [captionText].
  ///
  /// - On **Android**: Copies caption to clipboard as a handy backup and opens the
  ///   native Android `Intent.ACTION_SEND` share sheet with both the PNG card image
  ///   and the humorous caption attached.
  /// - On **Windows / Desktop**: Copies caption to clipboard and opens the file save
  ///   dialog so the user can save the high-res PNG card and paste the caption.
  static Future<bool> shareCardWithCaption({
    required GlobalKey boundaryKey,
    required String captionText,
    required String username,
  }) async {
    final pngBytes = await captureCardPngBytes(boundaryKey);
    if (pngBytes == null) return false;

    // Always copy the humorous caption to clipboard so the user can also paste it anywhere
    await Clipboard.setData(ClipboardData(text: captionText));

    final cleanUsername = username.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final fileName = 'Cineva_ID_Card_$cleanUsername.png';

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(pngBytes, flush: true);

        await _shareChannel.invokeMethod('shareImageWithText', {
          'filePath': file.path,
          'text': captionText,
          'title': 'Cineva Member Card',
        });
        return true;
      } catch (e) {
        debugPrint('Android native share failed: $e');
        return false;
      }
    }

    // Desktop / Windows fallback: Save PNG via FilePicker + caption is already on Clipboard
    final savedPath = await saveCardToDevice(
      boundaryKey: boundaryKey,
      username: username,
      preCapturedBytes: pngBytes,
    );
    return savedPath != null;
  }

  /// Saves the high-resolution PNG card directly to the user's device.
  /// Returns the saved file path if successful, or `null` if cancelled/failed.
  static Future<String?> saveCardToDevice({
    required GlobalKey boundaryKey,
    required String username,
    Uint8List? preCapturedBytes,
  }) async {
    final pngBytes = preCapturedBytes ?? await captureCardPngBytes(boundaryKey);
    if (pngBytes == null) return null;

    final cleanUsername = username.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final fileName = 'Cineva_Member_Card_$cleanUsername.png';

    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Simpan Kartu Member Cineva (PNG)',
        fileName: fileName,
        bytes: pngBytes,
      );
      if (uri != null) {
        return uri.path;
      }
      return null;
    } catch (e) {
      debugPrint('MemberCardShareService.saveCardToDevice fallback: $e');
      try {
        final dir = await getApplicationDocumentsDirectory();
        final fallbackFile = File('${dir.path}/$fileName');
        await fallbackFile.writeAsBytes(pngBytes, flush: true);
        return fallbackFile.path;
      } catch (_) {
        return null;
      }
    }
  }
}
