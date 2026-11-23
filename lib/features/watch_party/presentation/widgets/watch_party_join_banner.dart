import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/watch_party_provider.dart';
import '../screens/watch_party_direct_join_screen.dart';
import 'watch_party_beta_notice_card.dart';

/// Modern minimalist banner displayed on the Home Screen allowing users to join
/// a Watch Party room directly without needing to search for the movie or TV series manually.
///
/// Supports three adaptive presentations:
/// 1. [isCompanion: true]   - Stacked companion card placed beside the Hero Carousel on Tablet, Windows & TV.
/// 2. [isCompactPair: true] - Side-by-side (left-right) Bento card paired with AiringCalendarBanner on Mobile.
/// 3. Default               - Classic full-width horizontal banner.
class WatchPartyJoinBanner extends ConsumerWidget {
  final bool isCompanion;
  final bool isCompactPair;
  final double? height;

  const WatchPartyJoinBanner({
    super.key,
    this.isCompanion = false,
    this.isCompactPair = false,
    this.height,
  });

  void _showJoinModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => const _WatchPartyJoinSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    if (isCompanion) {
      return _buildCompanionCard(context, ref, s);
    }
    if (isCompactPair) {
      return _buildCompactPairCard(context, ref, s);
    }
    return _buildClassicHorizontalBanner(context, ref, s);
  }

  /// Stacked vertical companion card placed beside Hero Carousel on Tablet, Windows & TV.
  Widget _buildCompanionCard(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) {
    final cardHeight = height ?? 220.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPad = screenWidth < 960 ? 14.0 : 18.0;
    final isTight = cardHeight < 190;

    return TvFocusable(
      focusedScale: 1.02,
      glowBlurRadius: 18,
      borderRadius: BorderRadius.circular(24),
      onTap: () => _showJoinModal(context, ref),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1218),
              Color(0xFF111119),
              Color(0xFF0B0B11),
            ],
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: const Color(0xFFE50914).withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient glow top-right
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE50914).withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: isTight ? 11 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top badges & icon row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'SYNC PLAY',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.watchPartyBetaBadge,
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: isTight ? 28 : 32,
                        height: isTight ? 28 : 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB81D24)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Iconsax.people,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTight ? 8 : 12),
                  Text(
                    s.watchPartyBannerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: isTight ? 15.5 : 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      s.watchPartyBannerDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.2,
                        color: const Color(0xFFB0B0C4),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: isTight ? 8 : 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          size: 14,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.watchPartyBannerJoinBtn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
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

  /// Side-by-side (left-right) Bento card for Mobile below the Hero Carousel.
  Widget _buildCompactPairCard(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) {
    final cardHeight = height ?? 138.0;

    return TvFocusable(
      focusedScale: 1.02,
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showJoinModal(context, ref),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A131A),
              Color(0xFF13131B),
              Color(0xFF0E0E14),
            ],
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.24),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFFB81D24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Iconsax.people,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'SYNC',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.watchPartyBannerTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                s.watchPartyBannerDesc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.2,
                  color: AppColors.textMuted,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6.5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.login_rounded,
                    size: 13,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      s.watchPartyBannerJoinBtn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
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

  Widget _buildClassicHorizontalBanner(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF14141A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                // 1. Sleek Gradient Icon Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFFB81D24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Iconsax.people,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Title & Brief Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.watchPartyBannerTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'SYNC',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.watchPartyBannerDesc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // 3. Compact Action Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showJoinModal(context, ref),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.login_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.watchPartyBannerJoinBtn,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
        ),
      ),
    );
  }
}

/// Compact bottom sheet modal for entering the Watch Party room code from the Home Screen.
class _WatchPartyJoinSheet extends ConsumerStatefulWidget {
  const _WatchPartyJoinSheet();

  @override
  ConsumerState<_WatchPartyJoinSheet> createState() =>
      _WatchPartyJoinSheetState();
}

class _WatchPartyJoinSheetState extends ConsumerState<_WatchPartyJoinSheet> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isSearching = false;
  bool _requiresPin = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    final defaultName = profile.name.trim().isNotEmpty &&
            profile.name != 'Penikmat Film' &&
            profile.name != 'Movie Enthusiast'
        ? profile.name.trim()
        : '';
    _nameController.text = defaultName;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final s = ref.read(appStringsProvider);
    final rawCode = _codeController.text.trim();
    if (rawCode.isEmpty) {
      setState(() {
        _errorMessage = s.watchPartyEnterCodePrompt;
      });
      return;
    }

    final code = WatchPartyDirectJoinScreen.extractRoomCode(rawCode);

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : s.watchPartyGuest;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    final notifier = ref.read(watchPartyProvider.notifier);
    final room = await notifier.fetchRoom(code);

    if (!mounted) return;

    if (room == null) {
      setState(() {
        _isSearching = false;
        _errorMessage = s.watchPartyRoomNotFoundOrNotReady;
      });
      return;
    }

    // Verify PIN if the room is protected
    if (room.isProtectedByPin) {
      final candidatePin = _pinController.text.trim();
      if (candidatePin.isEmpty) {
        setState(() {
          _isSearching = false;
          _requiresPin = true;
          _errorMessage = s.watchPartyPinRequired;
        });
        return;
      } else if (!room.verifyPin(candidatePin)) {
        setState(() {
          _isSearching = false;
          _requiresPin = true;
          _errorMessage = s.watchPartyPinIncorrect;
        });
        return;
      }
    }

    // Join room
    final joinSuccess = await notifier.joinRoom(
      roomCode: code,
      memberName: name,
      pin: _pinController.text.trim().isNotEmpty
          ? _pinController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (joinSuccess) {
      Navigator.of(context).pop();

      // Launch player directly with the host's exact media
      final media = room.media;
      context.push(
        '/player',
        extra: {
          'title': media.title,
          'tmdbId': media.tmdbId,
          'imdbId': media.imdbId,
          'mediaType': media.mediaType,
          'season': media.season,
          'episode': media.episode,
          'episodeTitle': media.episodeTitle,
          'posterPath': media.posterPath,
          'backdropPath': media.backdropPath,
          'streamServer': media.streamServer,
        },
      );
    } else {
      final err = ref.read(watchPartyProvider).errorMessage;
      setState(() {
        _isSearching = false;
        _errorMessage = err ?? s.watchPartyJoinFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF14141B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 28,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: keyboardInset == 0,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle Bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Iconsax.people,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.watchPartyJoinRoom,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        s.watchPartyAutoSearchDesc,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Room Code Input
            Text(
              s.watchPartyRoomCode,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 2.0,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: InputDecoration(
                hintText: s.watchPartyRoomCodeHint,
                hintStyle: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                prefixIcon: const Icon(
                  Iconsax.key,
                  size: 18,
                  color: AppColors.primary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Room PIN Input (Optional if open, Required if room has PIN)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  s.watchPartyPin,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _requiresPin
                        ? const Color(0xFFFFB300)
                        : Colors.white,
                  ),
                ),
                if (!_requiresPin)
                  Text(
                    s.watchPartyPinOptional,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 6.0,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                counterText: '',
                hintText: s.watchPartyPinHint,
                hintStyle: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: _requiresPin
                      ? const Color(0xFFFFB300)
                      : AppColors.primary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _requiresPin
                        ? const Color(0xFFFFB300)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _requiresPin
                        ? const Color(0xFFFFB300)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _requiresPin
                        ? const Color(0xFFFFB300)
                        : AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Display Name Input
            Text(
              s.watchPartyNickname,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: s.watchPartyNicknameHint,
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                prefixIcon: const Icon(
                  Iconsax.user,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 15,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _handleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                icon: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_circle_fill_rounded, size: 20),
                label: Text(
                  _isSearching
                      ? s.watchPartySearchingRoom
                      : s.watchPartyJoinAndStart,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            WatchPartyBetaNoticeCard(strings: s),
          ],
        ),
      ),
    ),
  ),
);
  }
}
