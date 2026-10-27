import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/avatar_catalog.dart';
import 'cartoon_avatar_painter.dart';

/// Reusable cinematic avatar display widget.
///
/// Supports both preset cartoon character avatars (with vector illustrations)
/// and custom cropped user avatars from local file storage.
class AvatarDisplay extends StatelessWidget {
  final String avatarId;
  final String? customAvatarPath;
  final double size;
  final bool showGlow;
  final double borderWidth;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AvatarDisplay({
    super.key,
    required this.avatarId,
    this.customAvatarPath,
    this.size = 44.0,
    this.showGlow = false,
    this.borderWidth = 1.5,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = avatarId == 'custom' &&
        customAvatarPath != null &&
        customAvatarPath!.isNotEmpty &&
        File(customAvatarPath!).existsSync();

    final preset = AvatarCatalog.getById(avatarId);
    final effectiveBorderColor = borderColor ??
        (showGlow ? AppColors.primary : Colors.white.withValues(alpha: 0.15));

    Widget content;

    if (isCustom) {
      content = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: effectiveBorderColor,
            width: borderWidth,
          ),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: size * 0.35,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: Image.file(
            File(customAvatarPath!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.surfaceVariant,
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      );
    } else {
      content = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: effectiveBorderColor,
            width: borderWidth,
          ),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: preset.glowColor.withValues(alpha: 0.45),
                    blurRadius: size * 0.4,
                    spreadRadius: 1.5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipOval(
          child: CartoonAvatarWidget(
            avatarId: preset.id,
            size: size,
          ),
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
