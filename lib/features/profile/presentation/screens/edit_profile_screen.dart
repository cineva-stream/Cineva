import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../domain/models/avatar_catalog.dart';
import '../providers/profile_provider.dart';
import '../widgets/avatar_display.dart';
import 'avatar_crop_screen.dart';

/// Dedicated Edit Profile Screen in Cineva.
///
/// Features:
/// - AppBar with title "Edit Profile" / "Ubah Profil" and back button.
/// - Centered avatar preview with 10 cartoon presets + custom gallery picker with 1:1 cropper.
/// - Nickname input with automatic first-letter capitalization.
/// - Username input restricted to lowercase letters, numbers, underscores (no spaces).
/// - Clean save button without glow.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  final ImagePicker _picker = ImagePicker();

  String _selectedAvatarId = 'avatar_popcorn';
  String? _customAvatarPath;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                s.profileUpdatedSuccess,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: s.isIndonesian ? 'Kembali' : 'Back',
        ),
        title: Text(
          s.profileEditTitle,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 0.8,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // ── Big Avatar Preview ──
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AvatarDisplay(
                      avatarId: _selectedAvatarId,
                      customAvatarPath: _customAvatarPath,
                      size: 96,
                      borderWidth: 2.5,
                      borderColor: AppColors.primary,
                      showGlow: false,
                    ),
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.camera,
                          size: 15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Avatar Selector Label ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.profileChooseAvatar,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Horizontal Avatar Selection List (10 Cartoon Presets + Gallery) ──
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Option 0: Pick from Gallery item
                    _buildGalleryPickerItem(s),

                    // 10 Cartoon Presets
                    ...AvatarCatalog.presets.map((preset) {
                      final isSelected = _selectedAvatarId == preset.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
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
                                    : Colors.white.withValues(alpha: 0.12),
                                width: isSelected ? 2.5 : 1.2,
                              ),
                            ),
                            child: AvatarDisplay(
                              avatarId: preset.id,
                              size: 54,
                              borderWidth: 0,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Name Input Field (Capitalized) ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.profileNickname,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildInputField(
                controller: _nameController,
                hintText: s.profileNicknameHint,
                icon: Iconsax.user,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 18),

              // ── Username Input Field (Lowercase, No Spaces) ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.profileUsername,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildInputField(
                controller: _usernameController,
                hintText: s.profileUsernameHint,
                icon: Icons.alternate_email_rounded,
                prefixText: '@',
                textCapitalization: TextCapitalization.none,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) => newValue.copyWith(
                      text: newValue.text.toLowerCase(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ── Save Changes Button (No Glow) ──
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () => _saveChanges(s),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.profileSaveChanges,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryPickerItem(AppStrings s) {
    final isCustomSelected = _selectedAvatarId == 'custom';
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: _pickFromGallery,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 59,
          height: 59,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCustomSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.surfaceVariant,
            border: Border.all(
              color: isCustomSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.2),
              width: isCustomSelected ? 2.5 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.gallery_add,
                size: 20,
                color: isCustomSelected ? AppColors.primary : Colors.white,
              ),
              const SizedBox(height: 2),
              Text(
                s.profileGallery,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              if (prefixText != null)
                Text(
                  prefixText,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}
