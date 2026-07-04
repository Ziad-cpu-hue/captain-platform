import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chat List Screen
// ─────────────────────────────────────────────────────────────────────────────
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return const SizedBox();

    final threadsAsync = ref.watch(userThreadsProvider(user.uid));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            tooltip: 'Contact Support',
            onPressed: () async {
              final threadId = await ref.read(chatServiceProvider)
                .getOrCreateThread(
                  orderId:    'support_${user.uid}',
                  customerId: user.uid,
                  captainId:  'support',
                  isSupport:  true,
                );
              if (context.mounted) {
                context.push('${AppRoutes.chatDetail}/$threadId');
              }
            },
          ),
        ],
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.grey100),
                  const SizedBox(height: 16),
                  const Text('No conversations yet',
                    style: TextStyle(fontFamily: AppTheme.fontFamily,
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  const Text('Chats with your drivers will appear here',
                    style: TextStyle(fontFamily: AppTheme.fontFamily,
                      fontSize: 13, color: AppTheme.textHint)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
            itemBuilder: (_, i) {
              final thread = threads[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: thread.isSupport
                    ? AppTheme.primaryLight : AppTheme.grey50,
                  child: Icon(
                    thread.isSupport ? Icons.support_agent : Icons.person,
                    color: thread.isSupport ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
                title: Text(
                  thread.isSupport ? 'CapTain Support' : 'Trip Chat',
                  style: const TextStyle(fontFamily: AppTheme.fontFamily,
                    fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  thread.lastMessage ?? 'No messages yet',
                  style: const TextStyle(fontFamily: AppTheme.fontFamily,
                    fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      thread.lastMessageAt != null
                        ? timeago.format(thread.lastMessageAt!) : '',
                      style: const TextStyle(fontFamily: AppTheme.fontFamily,
                        fontSize: 11, color: AppTheme.textHint)),
                    if (thread.unreadCount > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary, shape: BoxShape.circle),
                        child: Center(
                          child: Text('${thread.unreadCount}',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600))),
                      ),
                    ],
                  ],
                ),
                onTap: () => context.push('${AppRoutes.chatDetail}/${thread.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Detail Screen
// ─────────────────────────────────────────────────────────────────────────────
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String threadId;
  const ChatDetailScreen({super.key, required this.threadId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgCtrl      = TextEditingController();
  final _scrollCtrl   = ScrollController();
  bool  _sending      = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(UserModel user) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      await ref.read(chatServiceProvider).sendMessage(
        threadId:   widget.threadId,
        senderId:   user.uid,
        senderName: user.displayName,
        senderRole: user.role,
        text:       text,
      );
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync  = ref.watch(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return const SizedBox();

    final msgsAsync = ref.watch(messagesProvider(widget.threadId));

    // Auto scroll when new messages arrive
    ref.listen(messagesProvider(widget.threadId), (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryLight,
              child: const Icon(Icons.person, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trip Chat', style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15, fontWeight: FontWeight.w600)),
                Text('Online', style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11, color: AppTheme.primary)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: msgsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 48, color: AppTheme.grey100),
                        const SizedBox(height: 12),
                        const Text('Start the conversation',
                          style: TextStyle(fontFamily: AppTheme.fontFamily,
                            fontSize: 14, color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg   = messages[i];
                    final isMe  = msg.senderId == user.uid;
                    final showDate = i == 0 ||
                      messages[i].sentAt.day != messages[i - 1].sentAt.day;

                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.sentAt),
                        _MessageBubble(message: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input Bar ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 16, right: 8, top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: AppTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.border, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(user),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : () => _sendMessage(user),
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary, shape: BoxShape.circle),
                    child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = '${message.sentAt.hour.toString().padLeft(2,'0')}:'
                 '${message.sentAt.minute.toString().padLeft(2,'0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryLight,
              child: Text(message.senderName.isNotEmpty
                ? message.senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 4),
                child: Text(message.senderName,
                  style: const TextStyle(fontFamily: AppTheme.fontFamily,
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4  : 18),
                  ),
                  border: isMe ? null
                    : Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Text(message.text, style: TextStyle(
                  fontFamily: AppTheme.fontFamily, fontSize: 14,
                  color: isMe ? Colors.white : AppTheme.textPrimary,
                  height: 1.4)),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10, color: AppTheme.textHint)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.done_all,
                      size: 13,
                      color: message.isRead ? AppTheme.primary : AppTheme.textHint),
                  ],
                ],
              ),
            ],
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String get _label {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(_label, style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.w500)),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );
}
