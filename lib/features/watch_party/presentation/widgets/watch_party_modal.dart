import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/watch_party_room.dart';
import '../providers/watch_party_provider.dart';

/// Modal dialog allowing users to Create a Watch Party room or Join an existing room with a code.
/// Supports Host permission configuration and Guest Mode with custom display names.
class WatchPartyModal extends ConsumerStatefulWidget {
  final WatchPartyMedia? media;

  const WatchPartyModal({
    super.key,
    this.media,
  });

  static Future<void> show(BuildContext context, {WatchPartyMedia? media}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => WatchPartyModal(media: media),
    );
  }

  @override
  ConsumerState<WatchPartyModal> createState() => _WatchPartyModalState();
}

class _WatchPartyModalState extends ConsumerState<WatchPartyModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _hostNameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _guestNameController = TextEditingController();

  bool _allowGuestControl = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.media != null ? 0 : 1;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );

    final profile = ref.read(userProfileProvider);
    final defaultName =
        profile.name.isNotEmpty && profile.name != 'Penikmat Film'
            ? profile.name
            : '';
    _hostNameController.text = defaultName;
    _guestNameController.text = defaultName;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostNameController.dispose();
    _roomCodeController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateRoom() async {
    if (widget.media == null) return;
    final s = ref.read(appStringsProvider);
    final hostName = _hostNameController.text.trim().isNotEmpty
        ? _hostNameController.text.trim()
        : 'Host';

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final roomCode = await ref.read(watchPartyProvider.notifier).createRoom(
          hostName: hostName,
          media: widget.media!,
          allowGuestControl: _allowGuestControl,
        );

    if (!mounted) return;

    if (roomCode != null) {
      ref.read(watchPartyProvider.notifier).toggleChatPanel(true);
      Navigator.of(context).pop();

      // Launch PlayerScreen for the host
      context.push(
        '/player',
        extra: {
          'title': widget.media!.title,
          'tmdbId': widget.media!.tmdbId,
          'imdbId': widget.media!.imdbId,
          'mediaType': widget.media!.mediaType,
          'season': widget.media!.season,
          'episode': widget.media!.episode,
          'episodeTitle': widget.media!.episodeTitle,
          'posterPath': widget.media!.posterPath,
          'backdropPath': widget.media!.backdropPath,
        },
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = s.isIndonesian
            ? 'Gagal membuat ruangan. Silakan coba lagi.'
            : 'Failed to create room. Please try again.';
      });
    }
  }

  Future<void> _handleJoinRoom() async {
    final s = ref.read(appStringsProvider);
    final code = _roomCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = s.isIndonesian
            ? 'Masukkan kode ruangan terlebih dahulu'
            : 'Please enter the room code';
      });
      return;
    }

    final guestName = _guestNameController.text.trim().isNotEmpty
        ? _guestNameController.text.trim()
        : 'Tamu';

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await ref.read(watchPartyProvider.notifier).joinRoom(
          roomCode: code,
          memberName: guestName,
        );

    if (!mounted) return;

    if (success) {
      final room = ref.read(watchPartyProvider).room;
      ref.read(watchPartyProvider.notifier).toggleChatPanel(true);
      Navigator.of(context).pop();

      if (room != null) {
        // Launch PlayerScreen for the guest with room media
        context.push(
          '/player',
          extra: {
            'title': room.media.title,
            'tmdbId': room.media.tmdbId,
            'imdbId': room.media.imdbId,
            'mediaType': room.media.mediaType,
            'season': room.media.season,
            'episode': room.media.episode,
            'episodeTitle': room.media.episodeTitle,
            'posterPath': room.media.posterPath,
            'backdropPath': room.media.backdropPath,
            'initialPositionMs': (room.playback.positionSeconds * 1000).toInt(),
          },
        );
      }
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = s.isIndonesian
            ? 'Ruangan tidak ditemukan atau kode salah.'
            : 'Room not found or invalid code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 460,
            constraints: const BoxConstraints(maxHeight: 640),
            decoration: BoxDecoration(
              color: const Color(0xFF16161D).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.people,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.watchPartyTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              s.isIndonesian
                                  ? 'Tonton bersama teman secara realtime'
                                  : 'Watch together in real-time sync',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: s.watchPartyCreateRoom),
                      Tab(text: s.watchPartyJoinRoom),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Error Banner
                if (_errorMessage != null)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tab Views
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCreateRoomTab(s),
                      _buildJoinRoomTab(s),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateRoomTab(AppStrings s) {
    if (widget.media == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            s.isIndonesian
                ? 'Buka film atau episode yang ingin ditonton terlebih dahulu untuk membuat ruangan.'
                : 'Open a movie or episode first to create a watch party room.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final media = widget.media!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Summary Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 64,
                    child: (media.posterPath != null &&
                            media.posterPath!.isNotEmpty)
                        ? Image.network(
                            '${ApiConstants.tmdbImageBaseUrl}${media.posterPath}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.movie_rounded,
                                  color: AppColors.textSecondary),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.movie_rounded,
                                color: AppColors.textSecondary),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (media.episode != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Season ${media.season ?? 1} • Episode ${media.episode}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        media.mediaType == 'tv' ? 'Serial TV' : 'Film',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Host Display Name
          Text(
            s.watchPartyNickname,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _hostNameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: s.watchPartyNicknameHint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              prefixIcon: const Icon(Iconsax.user, size: 16, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 14),

          // Host Permission Toggle Checkbox (User requested!)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _allowGuestControl
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              checkColor: Colors.white,
              title: Text(
                s.watchPartyAllowGuestControl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                s.watchPartyAllowGuestControlSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              value: _allowGuestControl,
              onChanged: (val) {
                setState(() => _allowGuestControl = val ?? false);
              },
            ),
          ),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleCreateRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                _isSubmitting ? 'Membuat Ruangan...' : s.watchPartyCreateAndStart,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRoomTab(AppStrings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Code Input
          Text(
            s.watchPartyRoomCode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _roomCodeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3.5,
            ),
            decoration: InputDecoration(
              hintText: s.watchPartyRoomCodeHint,
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              prefixIcon: const Icon(Iconsax.key, size: 18, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),

          const SizedBox(height: 16),

          // Guest Mode / Display Name Input
          Text(
            '${s.watchPartyNickname} (Guest Mode)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _guestNameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: s.watchPartyNicknameHint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              prefixIcon: const Icon(Iconsax.user, size: 16, color: Color(0xFF64B5F6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 10),

          // Guest Mode notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFF64B5F6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.watchPartyGuestPrompt,
                    style: const TextStyle(
                      color: Color(0xFF90CAF9),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleJoinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded, size: 20),
              label: Text(
                _isSubmitting ? 'Menghubungkan...' : s.watchPartyJoinAndStart,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

