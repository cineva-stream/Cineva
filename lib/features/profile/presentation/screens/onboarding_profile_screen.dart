import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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
import '../../../settings/data/settings_service.dart';

/// Modern Onboarding Profile Setup Screen for Cineva.
///
/// Features:
/// - 10 Cinematic Avatar Presets + Custom Gallery Avatar with 1:1 Cropping.
/// - Fluid micro-animations for avatar selection and entrance.
/// - Name & Username customization.
/// - Option to Skip anytime.
class OnboardingProfileScreen extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  ConsumerState<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen> {
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
        // Open interactive 1:1 Crop Screen
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

  Future<void> _saveAndEnter(AppStrings s) async {
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
      if (!SettingsService.hasAcceptedLegal()) {
        context.push('/onboarding-legal');
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _skipAndEnter() async {
    await ref.read(userProfileProvider.notifier).skipOnboarding();
    if (mounted) {
      if (!SettingsService.hasAcceptedLegal()) {
        context.push('/onboarding-legal');
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Top Bar: Logo & Skip Action ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'CINEVA',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 3, top: 2),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _skipAndEnter,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.profileSkip,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              // ── Header Title & Subtitle ──
              Text(
                s.profileCreateTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 450.ms)
                  .slideY(begin: 0.1, end: 0, duration: 450.ms),

              const SizedBox(height: 6),

              Text(
                s.profileCreateSubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 450.ms),

              const SizedBox(height: 28),

              // ── Active Avatar Preview with Glow & Badge ──
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: AvatarDisplay(
                        key: ValueKey('$_selectedAvatarId-$_customAvatarPath'),
                        avatarId: _selectedAvatarId,
                        customAvatarPath: _customAvatarPath,
                        size: 96,
                        showGlow: true,
                        borderWidth: 2.5,
                        borderColor: AppColors.primary,
                      ),
                    ),
                    // Gallery quick button on preview
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
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
              )
                  .animate(delay: 300.ms)
                  .scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              // ── Avatar Selector Section Header ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.profileChooseAvatar,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Avatar Horizontal Selector (Gallery Button + 10 Presets) ──
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Option 0: Pick from Gallery item
                    _buildGalleryPickerItem(s),

                    // 10 Presets
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
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 2.5 : 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
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
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 450.ms)
                  .slideX(begin: 0.05, end: 0, duration: 450.ms),

              const SizedBox(height: 28),

              // ── Name Input Field ──
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

              // ── Username Input Field ──
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

              // ── Main Action Button: Lanjut ──
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () => _saveAndEnter(s),
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
                        s.profileSaveAndEnter,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.1, end: 0, duration: 500.ms),

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
          duration: const Duration(milliseconds: 250),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCustomSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.surfaceVariant,
            border: Border.all(
              color: isCustomSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.25),
              width: isCustomSelected ? 2.5 : 1.2,
            ),
            boxShadow: isCustomSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
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
