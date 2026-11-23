import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/feedback_service.dart';

/// Screen allowing Cineva users to report bugs, suggest new features,
/// or submit media/subtitle issues directly to the developer's Telegram Bot.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  FeedbackCategory _selectedCategory = FeedbackCategory.bugs;
  bool _includeDeviceInfo = true;
  bool _isSubmitting = false;

  String _deviceInfo = 'Memuat perangkat...';
  String _appVersion = 'Cineva v1.2.0';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _titleController = TextEditingController();
    _descController = TextEditingController();

    _loadTechnicalSpecs();
  }

  Future<void> _loadTechnicalSpecs() async {
    final dev = await FeedbackService.getDeviceInfo();
    final ver = await FeedbackService.getAppVersion();
    if (mounted) {
      setState(() {
        _deviceInfo = dev;
        _appVersion = ver;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final s = ref.read(appStringsProvider);

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack(s.feedbackValidationTitleRequired, isError: true);
      return;
    }

    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      _showSnack(s.feedbackValidationDescRequired, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final service = FeedbackService();
    final success = await service.submitFeedback(
      name: _nameController.text.trim(),
      category: _selectedCategory.idLabel,
      title: title,
      description: desc,
      deviceInfo: _includeDeviceInfo ? _deviceInfo : 'Tidak disertakan',
      appVersion: _appVersion,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSuccessDialog();
    } else {
      _showSnack(s.feedbackErrorDesc, isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showSuccessDialog() {
    final s = ref.read(appStringsProvider);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.85),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4CAF50),
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.feedbackSuccessTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.feedbackSuccessDesc,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          s.isIndonesian ? 'Selesai' : 'Done',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.feedbackScreenTitle,
          style: GoogleFonts.outfit(
            fontSize: 18.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Info Banner ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Iconsax.message_favorite,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          s.feedbackScreenSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Category Selector ──
                Text(
                  s.feedbackCategoryLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return _buildCategoryChip(cat, isSelected, s.isIndonesian);
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Name Field (Optional) ──
                Text(
                  s.feedbackNameLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hintText: s.feedbackNameHint,
                  prefixIcon: Iconsax.user,
                ),
                const SizedBox(height: 18),

                // ── Title Field ──
                Row(
                  children: [
                    Text(
                      s.feedbackTitleLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '*',
                      style: TextStyle(
                        color: Color(0xFFFF5252),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _titleController,
                  hintText: s.feedbackTitleHint,
                  prefixIcon: Iconsax.edit_2,
                ),
                const SizedBox(height: 18),

                // ── Description Field ──
                Row(
                  children: [
                    Text(
                      s.feedbackDescLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '*',
                      style: TextStyle(
                        color: Color(0xFFFF5252),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _descController,
                    minLines: 5,
                    maxLines: 8,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: s.feedbackDescHint,
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Device Technical Specs Card ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.smartphone_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _deviceInfo,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              _appVersion,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: _includeDeviceInfo,
                        activeColor: AppColors.primary,
                        checkColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setState(() => _includeDeviceInfo = val ?? true);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    s.feedbackIncludeDeviceInfo,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // ── Submit Button ──
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            size: 19,
                          ),
                    label: Text(
                      _isSubmitting ? s.feedbackSendingBtn : s.feedbackSubmitBtn,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    FeedbackCategory cat,
    bool isSelected,
    bool isIndonesian,
  ) {
    IconData icon;
    Color accentColor;

    switch (cat) {
      case FeedbackCategory.bugs:
        icon = Icons.bug_report_rounded;
        accentColor = const Color(0xFFFF5252);
        break;
      case FeedbackCategory.features:
        icon = Icons.lightbulb_rounded;
        accentColor = AppColors.primary;
        break;
      case FeedbackCategory.report:
        icon = Icons.report_problem_rounded;
        accentColor = const Color(0xFF29B6F6);
        break;
      case FeedbackCategory.general:
        icon = Icons.chat_bubble_rounded;
        accentColor = const Color(0xFFAB47BC);
        break;
    }

    return InkWell(
      onTap: () => setState(() => _selectedCategory = cat),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? accentColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              cat.localizedLabel(isIndonesian),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: AppColors.textSecondary,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

