import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/watch_party_room.dart';
import '../providers/watch_party_provider.dart';

/// Screen displayed when opening a deep link (e.g. `https://cineva.app/party/CNV-XXXX`).
///
/// Handles room discovery, media preview before PIN validation (Option C),
/// 4-digit PIN verification with anti-brute force 30s lockout after 5 failed attempts (Option D),
/// and seamless direct navigation to the player.
class WatchPartyDirectJoinScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const WatchPartyDirectJoinScreen({
    super.key,
    required this.roomCode,
  });

  /// Helper to extract clean `CNV-XXXX` code from URL or raw text.
  static String extractRoomCode(String input) {
    final match = RegExp(r'CNV-[2-9A-Z]{4}', caseSensitive: false)
        .firstMatch(input);
    if (match != null) {
      return match.group(0)!.toUpperCase();
    }
    final trimmed = input.trim().toUpperCase();
    if (trimmed.startsWith('CNV-') && trimmed.length == 8) {
      return trimmed;
    }
    return trimmed;
  }

  @override
  ConsumerState<WatchPartyDirectJoinScreen> createState() =>
      _WatchPartyDirectJoinScreenState();
}

class _WatchPartyDirectJoinScreenState
    extends ConsumerState<WatchPartyDirectJoinScreen> {
  late final String _cleanCode;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  WatchPartyRoom? _room;
  bool _isLoading = true;
  String? _errorMessage;

  // Anti-brute force protection (Option D)
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _cleanCode = WatchPartyDirectJoinScreen.extractRoomCode(widget.roomCode);

    final profile = ref.read(userProfileProvider);
    final defaultName = profile.name.trim().isNotEmpty &&
            profile.name != 'Penikmat Film' &&
            profile.name != 'Movie Enthusiast'
        ? profile.name.trim()
        : 'Tamu Nobar';
    _nameController.text = defaultName;

    _fetchRoom();
  }

  Future<void> _fetchRoom() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(watchPartyServiceProvider);
      final room = await service.fetchRoom(_cleanCode);
      if (mounted) {
        setState(() {
          _room = room;
          _isLoading = false;
          if (room == null) {
            _errorMessage = 'Ruang Nonton Bareng tidak ditemukan atau sudah dibubarkan.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat ruang: $e';
        });
      }
    }
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 30;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 1) {
          _cooldownSeconds--;
        } else {
          _cooldownSeconds = 0;
          _failedAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _join() async {
    if (_cooldownSeconds > 0) return;

    final room = _room;
    if (room == null) return;

    final pin = _pinController.text.trim();
    if (room.isProtectedByPin) {
      if (pin.isEmpty) {
        setState(() {
          _errorMessage = 'PIN diperlukan untuk bergabung ke room ini.';
        });
        return;
      }
      if (!room.verifyPin(pin)) {
        final newAttempts = _failedAttempts + 1;
        setState(() {
          _failedAttempts = newAttempts;
        });

        if (newAttempts >= 5) {
          _startCooldown();
          setState(() {
            _errorMessage =
                'Terlalu banyak percobaan PIN salah. Terkunci selama 30 detik.';
          });
        } else {
          setState(() {
            _errorMessage =
                'PIN salah. Percobaan ke-$newAttempts dari 5.';
          });
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Tamu Nobar';

    final success = await ref.read(watchPartyProvider.notifier).joinRoom(
          roomCode: _cleanCode,
          memberName: name,
          pin: pin.isNotEmpty ? pin : null,
        );

    if (!mounted) return;

    if (success) {
      final media = room.media;
      context.pushReplacement(
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
      setState(() {
        _isLoading = false;
        _errorMessage =
            ref.read(watchPartyProvider).errorMessage ?? 'Gagal bergabung ke ruangan.';
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _nameController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _isLoading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 20),
                        Text(
                          'Menghubungkan ke Ruang Nobar $_cleanCode...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : _room == null
                      ? _buildNotFoundView(context, s)
                      : _buildRoomPreviewAndJoinView(context, s, _room!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundView(BuildContext context, AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.warning_2,
              color: Colors.redAccent,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ruang Tidak Ditemukan',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ??
                'Ruang dengan kode $_cleanCode tidak aktif atau telah dibubarkan oleh host.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Kembali ke Beranda',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomPreviewAndJoinView(
    BuildContext context,
    AppStrings s,
    WatchPartyRoom room,
  ) {
    final media = room.media;
    final isLocked = room.isProtectedByPin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Header Media Preview Card (Option C) ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Media Backdrop / Poster Header
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (media.backdropPath != null && media.backdropPath!.isNotEmpty)
                        Image.network(
                          'https://image.tmdb.org/t/p/w780${media.backdropPath}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 48),
                          ),
                        )
                      else if (media.posterPath != null && media.posterPath!.isNotEmpty)
                        Image.network(
                          'https://image.tmdb.org/t/p/w500${media.posterPath}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 48),
                          ),
                        )
                      else
                        Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 48),
                        ),
                      // Gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.surfaceVariant.withValues(alpha: 0.95),
                            ],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                      // Top Row Badges
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'NONTON BARENG',
                                style: GoogleFonts.outfit(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isLocked ? const Color(0xFFFFD54F) : AppColors.primary,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLocked ? Iconsax.lock : Iconsax.messages_1,
                                    color: isLocked ? const Color(0xFFFFD54F) : AppColors.primaryLight,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _cleanCode,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
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
              ),

              // Media Title and Room Details
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (media.episodeTitle != null && media.episodeTitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'S${media.season ?? 1} E${media.episode ?? 1}: ${media.episodeTitle}',
                        style: GoogleFonts.inter(
                          color: AppColors.primaryLight,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Iconsax.crown, color: Color(0xFFFFD54F), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Host: ${room.hostName}',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Iconsax.people, color: AppColors.textSecondary, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '${room.members.length} Penonton',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── 2. Member Name Input ──
        Text(
          'Nama Anda di Ruangan',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Masukkan nama Anda...',
            hintStyle: GoogleFonts.inter(color: Colors.white30),
            prefixIcon: const Icon(Iconsax.user, color: AppColors.textSecondary, size: 18),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),

        // ── 3. PIN Input if Protected (Option C & D) ──
        if (isLocked) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Iconsax.lock, color: Color(0xFFFFD54F), size: 14),
              const SizedBox(width: 6),
              Text(
                'PIN Ruangan (4 Digit)',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFD54F),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _pinController,
            enabled: _cooldownSeconds == 0,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: GoogleFonts.inter(color: Colors.white24, letterSpacing: 4),
              prefixIcon: const Icon(Iconsax.key, color: Color(0xFFFFD54F), size: 18),
              filled: true,
              fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFFFD54F).withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFD54F)),
              ),
            ),
          ),
        ],

        // Error / Lockout Banner (Option D)
        if (_cooldownSeconds > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.timer_1, color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Terlalu banyak percobaan PIN salah. Coba lagi dalam $_cooldownSeconds detik.',
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: GoogleFonts.inter(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _cooldownSeconds > 0 ? null : _join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _cooldownSeconds > 0
                      ? 'Terkunci ($_cooldownSeconds s)'
                      : (isLocked ? 'Verifikasi & Gabung' : 'Gabung Menonton'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
