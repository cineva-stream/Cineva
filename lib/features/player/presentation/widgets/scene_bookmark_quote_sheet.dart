import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../profile/data/member_card_share_service.dart';
import '../../data/services/scene_bookmark_service.dart';

/// Modal sheet providing two tabs during playback:
/// 1. **Scene Bookmarks (Momen Adegan)**: Save timestamped scene notes / subtitle
///    lines and tap any saved bookmark to jump directly to that timestamp.
/// 2. **Cinematic Quote Card (Kartu Kutipan)**: Preview and share a 16:9 cinema
///    quote card with darkened movie/episode backdrop, subtitle dialogue,
///    timestamp, title, and official Cineva branding.
class SceneBookmarkQuoteSheet extends StatefulWidget {
  final String mediaKey;
  final String title;
  final String? episodeLabel;
  final int currentPositionMs;
  final String initialQuoteText;
  final String? backdropPath;
  final AppStrings s;
  final ValueChanged<Duration> onSeekTo;

  const SceneBookmarkQuoteSheet({
    super.key,
    required this.mediaKey,
    required this.title,
    this.episodeLabel,
    required this.currentPositionMs,
    required this.initialQuoteText,
    this.backdropPath,
    required this.s,
    required this.onSeekTo,
  });

  static Future<void> show(
    BuildContext context, {
    required String mediaKey,
    required String title,
    String? episodeLabel,
    required int currentPositionMs,
    required String initialQuoteText,
    String? backdropPath,
    required AppStrings s,
    required ValueChanged<Duration> onSeekTo,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SceneBookmarkQuoteSheet(
        mediaKey: mediaKey,
        title: title,
        episodeLabel: episodeLabel,
        currentPositionMs: currentPositionMs,
        initialQuoteText: initialQuoteText,
        backdropPath: backdropPath,
        s: s,
        onSeekTo: onSeekTo,
      ),
    );
  }

  @override
  State<SceneBookmarkQuoteSheet> createState() =>
      _SceneBookmarkQuoteSheetState();
}

class _SceneBookmarkQuoteSheetState extends State<SceneBookmarkQuoteSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _quoteController;
  final GlobalKey _quoteCardBoundaryKey = GlobalKey();

  List<SceneBookmark> _bookmarks = const [];
  bool _isSharing = false;
  late int _selectedTimestampMs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedTimestampMs = widget.currentPositionMs;
    final cleanInitial = widget.initialQuoteText
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    _quoteController = TextEditingController(
      text: cleanInitial.isNotEmpty
          ? cleanInitial
          : widget.s.sceneQuoteDefaultText,
    );
    _bookmarks = SceneBookmarkService.getBookmarks(widget.mediaKey);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  String? get _backdropUrl {
    final path = (widget.backdropPath ?? '').trim();
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return ApiConstants.imageUrl(path, size: ApiConstants.backdropLarge);
  }

  Future<void> _saveBookmark() async {
    final text = _quoteController.text.trim();
    final bookmark = SceneBookmark(
      id: '${widget.mediaKey}_${DateTime.now().millisecondsSinceEpoch}',
      mediaKey: widget.mediaKey,
      title: widget.title,
      episodeLabel: widget.episodeLabel,
      positionMs: _selectedTimestampMs,
      quoteText: text.isNotEmpty ? text : widget.s.sceneQuoteDefaultText,
      backdropPath: widget.backdropPath,
      createdAt: DateTime.now(),
    );
    final updated = await SceneBookmarkService.addBookmark(bookmark);
    if (!mounted) return;
    setState(() {
      _bookmarks = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.s.sceneBookmarkSavedToast),
        backgroundColor: AppColors.surfaceVariant,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteBookmark(String id) async {
    final updated = await SceneBookmarkService.deleteBookmark(
      widget.mediaKey,
      id,
    );
    if (!mounted) return;
    setState(() {
      _bookmarks = updated;
    });
  }

  Future<void> _shareQuoteCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final quote = _quoteController.text.trim().isNotEmpty
          ? _quoteController.text.trim()
          : widget.s.sceneQuoteDefaultText;
      final timestamp = SceneBookmark.formatDurationMs(_selectedTimestampMs);
      final epPart =
          (widget.episodeLabel != null && widget.episodeLabel!.isNotEmpty)
          ? ' (${widget.episodeLabel})'
          : '';
      final caption =
          '"$quote"\n— ${widget.title}$epPart [$timestamp] • Cineva';

      await MemberCardShareService.shareCardWithCaption(
        boundaryKey: _quoteCardBoundaryKey,
        captionText: caption,
        username: 'Quote_${widget.title}',
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 580),
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF101014),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bookmark_added_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.sceneBookmarkTitle,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      Tab(
                        height: 38,
                        text: '${s.sceneBookmarkTabMoments} (${_bookmarks.length})',
                      ),
                      Tab(height: 38, text: s.sceneBookmarkTabQuote),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tab Views
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookmarksTab(s),
                      _buildQuoteCardTab(s),
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

  Widget _buildBookmarksTab(AppStrings s) {
    final timestampLabel = SceneBookmark.formatDurationMs(_selectedTimestampMs);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input row with current timestamp pill + save button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      timestampLabel,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _quoteController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: s.sceneBookmarkInputHint,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveBookmark,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  s.sceneBookmarkSaveBtn,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Saved Bookmarks List
          Expanded(
            child: _bookmarks.isEmpty
                ? Center(
                    child: Text(
                      s.sceneBookmarkEmpty,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: _bookmarks.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, index) {
                      final item = _bookmarks[index];
                      return InkWell(
                        onTap: () {
                          widget.onSeekTo(
                            Duration(milliseconds: item.positionMs),
                          );
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.formattedTimestamp,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.quoteText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: s.sceneBookmarkTabQuote,
                                onPressed: () {
                                  setState(() {
                                    _selectedTimestampMs = item.positionMs;
                                    _quoteController.text = item.quoteText;
                                  });
                                  _tabController.animateTo(1);
                                },
                                icon: const Icon(
                                  Icons.format_quote_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteBookmark(item.id),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white38,
                                  size: 18,
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
      ),
    );
  }

  Widget _buildQuoteCardTab(AppStrings s) {
    final quote = _quoteController.text.trim().isNotEmpty
        ? _quoteController.text.trim()
        : s.sceneQuoteDefaultText;
    final timestampLabel = SceneBookmark.formatDurationMs(_selectedTimestampMs);
    final backdropUrl = _backdropUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          // 16:9 Cinematic Quote Card (Captured via RepaintBoundary)
          RepaintBoundary(
            key: _quoteCardBoundaryKey,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF09090C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (backdropUrl != null)
                      CachedNetworkImage(
                        imageUrl: backdropUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const SizedBox.shrink(),
                      ),
                    // Deep Cinema Vignette Overlay
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.72),
                            Colors.black.withValues(alpha: 0.92),
                          ],
                        ),
                      ),
                    ),
                    // Card Content
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Bar: Cineva Branding + Timestamp
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'CINEVA',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Text(
                                  timestampLabel,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Quote Dialogue
                          Center(
                            child: Text(
                              '“$quote”',
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                height: 1.38,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Bottom Metadata: Title & Episode
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.episodeLabel != null &&
                                          widget.episodeLabel!.isNotEmpty
                                      ? '${widget.title} • ${widget.episodeLabel}'
                                      : widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
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
            ),
          ),

          const SizedBox(height: 12),

          // Editable quote input + Share Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quoteController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: s.sceneBookmarkInputHint,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareQuoteCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isSharing
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 17),
                label: Text(
                  s.sceneQuoteShareBtn,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
