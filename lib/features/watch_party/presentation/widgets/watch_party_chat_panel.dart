import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../domain/models/watch_party_room.dart';
import '../providers/watch_party_provider.dart';

/// Side panel for Watch Party: displays Room Code, online member count, Host permission checkbox,
/// realtime chat message feed, Quick Emoji Reactions bar, and message input.
class WatchPartyChatPanel extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const WatchPartyChatPanel({
    super.key,
    this.onClose,
  });

  @override
  ConsumerState<WatchPartyChatPanel> createState() => _WatchPartyChatPanelState();
}

class _WatchPartyChatPanelState extends ConsumerState<WatchPartyChatPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  static const List<String> _quickEmojis = [
    '❤️',
    '😂',
    '😱',
    '🔥',
    '👏',
    '🍿',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ref.read(watchPartyProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _copyRoomCode(WatchPartyRoom room, AppStrings s) {
    final textToCopy = room.isProtectedByPin
        ? 'Kode: ${room.roomCode} | PIN: ${room.pin}'
        : room.roomCode;
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          room.isProtectedByPin
              ? s.watchPartyPinCopied
              : s.watchPartyCodeCopied,
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLeaveRoom(AppStrings s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          s.watchPartyLeaveConfirm,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          s.watchPartyLeaveConfirmDesc,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              s.isIndonesian ? 'Batal' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(watchPartyProvider.notifier).leaveRoom();
            },
            child: Text(s.watchPartyLeaveBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final watchPartyState = ref.watch(watchPartyProvider);
    final room = watchPartyState.room;
    if (room == null) return const SizedBox.shrink();

    final s = ref.watch(appStringsProvider);
    final isHost = watchPartyState.isHost;

    // Autoscroll when new messages appear
    if (room.messages.length != _lastMessageCount) {
      _lastMessageCount = room.messages.length;
      _scrollToBottom();
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 340,
          color: const Color(0xFF121217).withValues(alpha: 0.94),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // ── 1. Top Panel Header ──
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.people,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.watchPartyTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Leave Room Icon Button
                        IconButton(
                          onPressed: () => _confirmLeaveRoom(s),
                          tooltip: s.watchPartyLeaveBtn,
                          icon: const Icon(
                            Icons.exit_to_app_rounded,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        // Close Panel Icon Button
                        IconButton(
                          onPressed: () {
                            if (widget.onClose != null) {
                              widget.onClose!();
                            } else {
                              ref
                                  .read(watchPartyProvider.notifier)
                                  .toggleChatPanel(false);
                            }
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Room Code Pill + PIN Badge + Member Count
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _copyRoomCode(room, s),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  room.roomCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (room.isProtectedByPin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 12,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isHost ? 'PIN: ${room.pin}' : 'PIN',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                s.watchPartyOnlineCount(room.members.length),
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
                  ],
                ),
              ),

              // ── 2. Host Permission Toggle Checkbox (User Requested!) ──
              if (isHost)
                Container(
                  margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: room.allowGuestControl
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: room.allowGuestControl,
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (val) {
                          ref
                              .read(watchPartyProvider.notifier)
                              .setAllowGuestControl(val ?? false);
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.watchPartyAllowGuestControl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (!room.allowGuestControl)
                Container(
                  margin: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 13, color: Colors.amberAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.watchPartyHostOnlyControlNotice,
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── 3. Realtime Messages Stream ──
              Expanded(
                child: Builder(
                  builder: (context) {
                    final seenIds = <String>{};
                    final displayMessages = <WatchPartyMessage>[];
                    for (final m in room.messages) {
                      if (seenIds.add(m.id)) {
                        displayMessages.add(m);
                      }
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: displayMessages.length,
                      itemBuilder: (context, index) {
                        final msg = displayMessages[index];
                        return _buildMessageItem(msg, watchPartyState.myMemberId);
                      },
                    );
                  },
                ),
              ),

              // ── 4. Quick Emoji Reactions Bar ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _quickEmojis.map((emoji) {
                    return InkWell(
                      onTap: () {
                        ref
                            .read(watchPartyProvider.notifier)
                            .sendEmojiReaction(emoji);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── 5. Message Input Bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161D),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSendMessage(),
                        decoration: InputDecoration(
                          hintText: s.watchPartyTypeMessage,
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _handleSendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
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

  Widget _buildMessageItem(WatchPartyMessage msg, String? myMemberId) {
    if (msg.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              msg.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    if (msg.type == 'emoji') {
      final isMe = msg.senderId == myMemberId;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                msg.senderName,
                style: TextStyle(
                  color: msg.isHost
                      ? const Color(0xFFFFD54F)
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                msg.emoji ?? '🔥',
                style: const TextStyle(fontSize: 28),
              ),
            ],
          ),
        ),
      );
    }

    final isMe = msg.senderId == myMemberId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.85)
                : const Color(0xFF22222D),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMe ? 14 : 2),
              bottomRight: Radius.circular(isMe ? 2 : 14),
            ),
            border: Border.all(
              color: isMe
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.senderName,
                      style: TextStyle(
                        color: msg.isHost
                            ? const Color(0xFFFFD54F)
                            : AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (msg.isHost) ...[
                      const SizedBox(width: 4),
                      const Text('👑', style: TextStyle(fontSize: 9)),
                    ],
                  ],
                ),
              const SizedBox(height: 2),
              Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

