import 'package:flutter/material.dart';
import '../../../settings/data/settings_service.dart';

/// User customization settings for subtitle rendering and synchronization.
class SubtitleStyleSettings {
  final double strokeWidth;
  final Color strokeColor;
  final double fontSize;
  final Color textColor;
  final double bottomOffset;
  final double backgroundOpacity;
  final int syncOffsetMs; // Delay or advance in milliseconds

  const SubtitleStyleSettings({
    this.strokeWidth = 2.5,
    this.strokeColor = Colors.black,
    this.fontSize = 20.0,
    this.textColor = Colors.white,
    this.bottomOffset = 32.0,
    this.backgroundOpacity = 0.0,
    this.syncOffsetMs = 0,
  });

  SubtitleStyleSettings copyWith({
    double? strokeWidth,
    Color? strokeColor,
    double? fontSize,
    Color? textColor,
    double? bottomOffset,
    double? backgroundOpacity,
    int? syncOffsetMs,
  }) {
    return SubtitleStyleSettings(
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      bottomOffset: bottomOffset ?? this.bottomOffset,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      syncOffsetMs: syncOffsetMs ?? this.syncOffsetMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'strokeWidth': strokeWidth,
      'fontSize': fontSize,
      'textColor': textColor.toARGB32(),
      'bottomOffset': bottomOffset,
      'backgroundOpacity': backgroundOpacity,
      'syncOffsetMs': syncOffsetMs,
    };
  }

  factory SubtitleStyleSettings.fromMap(Map<String, dynamic> map) {
    return SubtitleStyleSettings(
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 2.5,
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 20.0,
      textColor: Color(map['textColor'] as int? ?? 0xFFFFFFFF),
      bottomOffset: (map['bottomOffset'] as num?)?.toDouble() ?? 32.0,
      backgroundOpacity: (map['backgroundOpacity'] as num?)?.toDouble() ?? 0.0,
      syncOffsetMs: (map['syncOffsetMs'] as num?)?.toInt() ?? 0,
    );
  }

  /// Creates a SubtitleStyleSettings initialized directly from user preferences in SettingsService.
  factory SubtitleStyleSettings.fromSettings() {
    try {
      return SubtitleStyleSettings(
        fontSize: SettingsService.getSubtitleFontSizePoints(),
        backgroundOpacity: SettingsService.getSubtitleBackgroundOpacity(),
        strokeWidth: SettingsService.getSubtitleStrokeWidth(),
        bottomOffset: SettingsService.getSubtitleBottomOffset(),
        textColor: Color(SettingsService.getSubtitleTextColorValue()),
      );
    } catch (_) {
      return const SubtitleStyleSettings();
    }
  }
}
