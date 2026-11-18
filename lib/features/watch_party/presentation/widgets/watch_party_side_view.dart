import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/watch_party_room.dart';
import '../providers/watch_party_provider.dart';

/// Right-side panel view for Watch Party (Create Room & Join Room) inside PlayerScreen.
/// Allows users to manage Watch Party sessions without blocking or dimming the active video stream.
class WatchPartySideView extends ConsumerStatefulWidget {
  final WatchPartyMedia media;
  final VoidCallback? onClose;
  final void Function(String roomCode, WatchPartyMedia media)?
      onRoomCreatedOrJoined;

  const WatchPartySideView({
    super.key,
    required this.media,
    this.onClose,
    this.onRoomCreatedOrJoined,
  });

  @override
  ConsumerState<WatchPartySideView> createState() => _WatchPartySideViewState();
}

class _WatchPartySideViewState extends ConsumerState<WatchPartySideView>
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
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);

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
          media: widget.media,
          allowGuestControl: _allowGuestControl,
        );

    if (!mounted) return;

    if (roomCode != null) {
      widget.onRoomCreatedOrJoined?.call(roomCode, widget.media);
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
      final targetMedia = room?.media ?? widget.media;
      widget.onRoomCreatedOrJoined?.call(code, targetMedia);
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

    return Column(
      children: [
        const SizedBox(height: 10),

        // ── Minimalist Tab Bar Switcher ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
            tabs: [
              Tab(text: s.watchPartyCreateRoom),
              Tab(text: s.watchPartyJoinRoom),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Error Banner ──
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 16,
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

        // ── Tab Views ──
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCreateRoomTab(s),
              _buildJoinRoomTab(s),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateRoomTab(AppStrings s) {
    final media = widget.media;
    final imageUrl = _resolveImageUrl(media);
    final episodeSubtitle = _formattedEpisodeSubtitle(media);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
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
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(
                                Icons.movie_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.movie_rounded,
                              color: AppColors.textSecondary,
                            ),
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
                          fontSize: 13.5,
                        ),
                      ),
                      if (media.episode != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          episodeSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11.5,
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

          const SizedBox(height: 14),

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
              prefixIcon: const Icon(
                Iconsax.user,
                size: 16,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Host Permission Toggle Checkbox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _allowGuestControl
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Material(
              color: Colors.transparent,
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
                    fontSize: 10.5,
                  ),
                ),
                value: _allowGuestControl,
                onChanged: (val) {
                  setState(() => _allowGuestControl = val ?? false);
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleCreateRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                _isSubmitting
                    ? 'Membuat Ruangan...'
                    : s.watchPartyCreateAndStart,
                style: const TextStyle(
                  fontSize: 12.5,
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
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
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
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 3.0,
            ),
            decoration: InputDecoration(
              hintText: s.watchPartyRoomCodeHint,
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                letterSpacing: 1.0,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              prefixIcon: const Icon(
                Iconsax.key,
                size: 18,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 14),

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
              prefixIcon: const Icon(
                Iconsax.user,
                size: 16,
                color: Color(0xFF64B5F6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
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
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF64B5F6),
                ),
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

          const SizedBox(height: 18),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleJoinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                _isSubmitting ? 'Bergabung...' : s.watchPartyJoinRoom,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveImageUrl(WatchPartyMedia media) {
    final p = media.posterPath?.trim();
    final b = media.backdropPath?.trim();
    if (p != null && p.isNotEmpty) {
      return p.startsWith('http')
          ? p
          : ApiConstants.imageUrl(p, size: ApiConstants.posterMedium);
    }
    if (b != null && b.isNotEmpty) {
      return b.startsWith('http')
          ? b
          : ApiConstants.imageUrl(b, size: ApiConstants.backdropSmall);
    }
    return null;
  }

  String _formattedEpisodeSubtitle(WatchPartyMedia media) {
    final base = 'Season ${media.season ?? 1} - Episode ${media.episode}';
    final epName = _cleanEpisodeName(media.episodeTitle);
    if (epName.isNotEmpty) {
      return '$base ($epName)';
    }
    return base;
  }

  String _cleanEpisodeName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    var cleaned = raw.trim();
    cleaned = cleaned.replaceFirst(
      RegExp(r'^S\d+\s*:\s*E\d+\s*[-:•]?\s*', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^Season\s+\d+\s*(?:[-:•]\s*)?Episode\s+\d+\s*[-:•]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceFirst(
      RegExp(r'^Episode\s+\d+\s*[-:•]?\s*', caseSensitive: false),
      '',
    );
    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }
    if (RegExp(r'^\d+$').hasMatch(cleaned)) return '';
    return cleaned.trim();
  }
}

