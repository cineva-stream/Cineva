import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../domain/models/avatar_catalog.dart';
import '../providers/profile_provider.dart';
import '../screens/avatar_crop_screen.dart';
import 'avatar_display.dart';

/// Modal bottom sheet to edit user profile from Settings.
class EditProfileBottomSheet extends ConsumerStatefulWidget {
  const EditProfileBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const EditProfileBottomSheet(),
    );
  }

  @override
  ConsumerState<EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState
    extends ConsumerState<EditProfileBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  final ImagePicker _picker = ImagePicker();

  late String _selectedAvatarId;
  String? _customAvatarPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _usernameController = TextEditingController(text: profile.username);
    _selectedAvatarId = profile.avatarId;
    _customAvatarPath = profile.customAvatarPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (picked != null && mounted) {
        final croppedPath = await Navigator.of(context).push<String>(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AvatarCropScreen(imagePath: picked.path),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );

        if (croppedPath != null && mounted) {
          setState(() {
            _selectedAvatarId = 'custom';
            _customAvatarPath = croppedPath;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final s = ref.read(appStringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              '${s.profileGalleryError}: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveChanges(AppStrings s) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : s.profileDefaultName;
    final username = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim().replaceAll('@', '')
        : 'cineva_fan';

    await ref.read(userProfileProvider.notifier).save(
          name: name,
          username: username,
          avatarId: _selectedAvatarId,
          customAvatarPath: _customAvatarPath,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Text(
                s.profileUpdatedSuccess,
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.profileEditTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 22),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Active Avatar Preview
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AvatarDisplay(
                    key: ValueKey('$_selectedAvatarId-$_customAvatarPath'),
                    avatarId: _selectedAvatarId,
                    customAvatarPath: _customAvatarPath,
                    size: 80,
                    showGlow: true,
                    borderWidth: 2,
                    borderColor: AppColors.primary,
                  ),
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Iconsax.camera,
                        size: 13,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Avatar Presets & Gallery Row
            Text(
              s.profileChooseAvatarShort,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Gallery Pick Button
                  _buildGalleryPickerButton(s),

                  // 10 Presets
                  ...AvatarCatalog.presets.map((preset) {
                    final isSelected = _selectedAvatarId == preset.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarId = preset.id;
                            _customAvatarPath = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 2.2 : 1,
                            ),
                          ),
                          child: AvatarDisplay(
                            avatarId: preset.id,
                            size: 48,
                            borderWidth: 0,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Nama Input
            Text(
              s.profileNickname,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            _buildInputField(
              controller: _nameController,
              hintText: s.profileNicknameHint,
              icon: Iconsax.user,
            ),

            const SizedBox(height: 14),

            // Username Input
            Text(
              s.profileUsername,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            _buildInputField(
              controller: _usernameController,
              hintText: s.profileUsernameHint,
              icon: Icons.alternate_email_rounded,
              prefixText: '@',
            ),

            const SizedBox(height: 24),

            // Tombol Simpan
            Container(
              height: 48,
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
                onPressed: _isSaving ? null : () => _saveChanges(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        s.profileSaveChanges,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryPickerButton(AppStrings s) {
    final isCustomSelected = _selectedAvatarId == 'custom';
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: _pickFromGallery,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCustomSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.surfaceVariant,
            border: Border.all(
              color: isCustomSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.2),
              width: isCustomSelected ? 2.2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.gallery_add,
                size: 18,
                color: isCustomSelected ? AppColors.primary : Colors.white,
              ),
              const SizedBox(height: 1),
              Text(
                s.profileGallery,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: isCustomSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              if (prefixText != null)
                Text(
                  prefixText,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
