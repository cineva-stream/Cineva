import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../domain/entities/live_football_match.dart';
import '../../domain/entities/live_tv_channel.dart';
import '../providers/live_tv_providers.dart';

/// Tournament-styled modal popup that alerts the user when one or more live
/// football matches are currently being broadcast on Cineva's Live TV channels.
///
/// Tapping "Watch Now" (`Tonton Sekarang`) immediately opens the verified
/// broadcasting [LiveTvChannel] in the player.
class LiveFootballMatchModal extends ConsumerStatefulWidget {
  final List<LiveFootballMatch> matches;
  final ValueChanged<LiveTvChannel>? onWatchChannel;

  const LiveFootballMatchModal({
    super.key,
    required this.matches,
    this.onWatchChannel,
  });

  static Future<void> show(
    BuildContext context, {
    required List<LiveFootballMatch> matches,
    ValueChanged<LiveTvChannel>? onWatchChannel,
  }) {
    if (matches.isEmpty) return Future.value();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (ctx) => LiveFootballMatchModal(
        matches: matches,
        onWatchChannel: onWatchChannel,
      ),
    );
  }

  @override
  ConsumerState<LiveFootballMatchModal> createState() =>
      _LiveFootballMatchModalState();
}

class _LiveFootballMatchModalState
    extends ConsumerState<LiveFootballMatchModal> {
  int _selectedMatchIndex = 0;
  late LiveTvChannel _selectedChannel;

  LiveFootballMatch get _currentMatch =>
      widget.matches[_selectedMatchIndex.clamp(0, widget.matches.length - 1)];

  bool _hasNumericScore(LiveFootballMatch m) {
    final h = m.homeScore.trim();
    final a = m.awayScore.trim();
    return h != '-' && a != '-' && h.isNotEmpty && a.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _selectedChannel = _currentMatch.primaryChannel;
  }

  void _selectMatch(int index) {
    setState(() {
      _selectedMatchIndex = index;
      _selectedChannel = _currentMatch.primaryChannel;
    });
  }

  Future<void> _handleWatchNow() async {
    final targetChannel = _selectedChannel;
    Navigator.of(context).pop();
    if (widget.onWatchChannel != null) {
      widget.onWatchChannel!(targetChannel);
      return;
    }
    ref.read(liveTvIsPlayingProvider.notifier).state = true;
    await context.push('/live-tv/player', extra: targetChannel);
    if (mounted) {
      ref.read(liveTvIsPlayingProvider.notifier).state = false;
      ref.read(liveTvFullscreenProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final match = _currentMatch;
    final channels = match.allChannels;
    final hasScore = _hasNumericScore(match);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1017),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.85),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Tournament Header Banner ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF17221B),
                      const Color(0xFF0D1017).withValues(alpha: 0.0),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Single clean tournament header line (no badge clutter)
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF3B5C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  match.competitionName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.footballLiveModalTitle,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable Tournament Body ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Tournament Matchday Arena Scoreboard ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF151A24),
                              Color(0xFF10131B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Home Team
                            Expanded(
                              child: _buildTournamentTeamColumn(
                                name: s.localizeFootballLabel(
                                  match.homeTeamName,
                                ),
                                logoUrl: match.homeTeamLogo,
                              ),
                            ),

                            // Center Score or VS Display
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasScore)
                                    Text(
                                      '${match.homeScore}  :  ${match.awayScore}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    )
                                  else
                                    Text(
                                      'VS',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.primary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    match.statusDetail,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Away Team
                            Expanded(
                              child: _buildTournamentTeamColumn(
                                name: s.localizeFootballLabel(
                                  match.awayTeamName,
                                ),
                                logoUrl: match.awayTeamLogo,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Official Broadcasting Channel(s) Section (Real-Time EPG Verified) ──
                      Text(
                        s.footballLiveBroadcastOn,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...channels.map((ch) {
                        final isSelected = ch.id == _selectedChannel.id;
                        final epgInfo =
                            match.programInfoForChannel(ch.id) ??
                            '${match.competitionName} • ${match.statusDetail}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: InkWell(
                            onTap: () => setState(() => _selectedChannel = ch),
                            borderRadius: BorderRadius.circular(13),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary.withValues(
                                          alpha: 0.75,
                                        )
                                      : Colors.white.withValues(alpha: 0.08),
                                  width: isSelected ? 1.2 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Official Channel Logo
                                  Container(
                                    width: 34,
                                    height: 34,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.07,
                                        ),
                                      ),
                                    ),
                                    child: ch.logoUrl != null &&
                                            ch.logoUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: ch.logoUrl!,
                                            fit: BoxFit.contain,
                                            errorWidget: (_, _, _) =>
                                                const Icon(
                                                  Icons.live_tv_rounded,
                                                  size: 16,
                                                  color: Colors.white70,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.live_tv_rounded,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Channel Name + Real-Time EPG Programme & Schedule Window
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ch.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          epgInfo,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: Colors.white60,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isSelected
                                        ? Icons.play_circle_fill_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white30,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // ── Other Live Matches Switcher (Shows Match + Broadcasting Channel) ──
                      if (widget.matches.length > 1) ...[
                        const SizedBox(height: 6),
                        Text(
                          s.footballLiveOtherMatches,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.matches.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final m = widget.matches[idx];
                              final isSelected = idx == _selectedMatchIndex;
                              final mHasScore = _hasNumericScore(m);
                              final hName = s.localizeFootballLabel(
                                m.homeTeamName,
                              );
                              final aName = s.localizeFootballLabel(
                                m.awayTeamName,
                              );
                              final matchLabel = mHasScore
                                  ? '$hName ${m.homeScore}-${m.awayScore} $aName'
                                  : '$hName vs $aName';

                              return InkWell(
                                onTap: () => _selectMatch(idx),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(
                                            alpha: 0.16,
                                          )
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        matchLabel,
                                        style: GoogleFonts.outfit(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        m.broadcastingChannelNames,
                                        style: GoogleFonts.inter(
                                          color: Colors.white60,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Pinned Bottom Actions: Watch Now & Maybe Later ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1017),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: Text(
                          s.footballLiveDismissBtn,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _handleWatchNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text(
                          s.footballLiveWatchNowBtn,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentTeamColumn({
    required String name,
    String? logoUrl,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: logoUrl != null && logoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: logoUrl,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const Icon(
                    Icons.shield_rounded,
                    color: Colors.white70,
                    size: 28,
                  ),
                )
              : const Icon(
                  Icons.shield_rounded,
                  color: Colors.white70,
                  size: 28,
                ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
