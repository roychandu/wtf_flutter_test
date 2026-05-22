import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/wtf_models.dart';
import '../../services/app_controller.dart';
import '../../utils/wtf_theme.dart';
import '../../widgets/wtf_components.dart';
import '../call/call_screen.dart';
import '../wtf_app.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, this.initialText});

  final String? initialText;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final TextEditingController textController;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.initialText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) {
      return;
    }
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    final hasUnread = app.snapshot.unreadFor(app.currentUser.id) > 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      if (hasUnread) {
        app.markChatRead();
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InitialsAvatar(
              label: app.peer.avatarUrl ?? app.peer.name[0],
              color: roleColor(app.peer.role),
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                app.peer.name,
                style: const TextStyle(
                  color: WtfColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Join approved call',
            onPressed: app.snapshot.upcomingCalls.isEmpty
                ? null
                : () => showPreJoinSheet(
                    context,
                    app.snapshot.upcomingCalls.first,
                  ),
            icon: Badge(
              isLabelVisible: app.snapshot.upcomingCalls.any(
                (call) => call.isJoinable,
              ),
              child: const Icon(Icons.videocam_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => app.refresh(),
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  itemCount:
                      app.snapshot.sortedMessages.length +
                      (app.otherSideTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    final messages = app.snapshot.sortedMessages;
                    if (index >= messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: _TypingBubble(),
                        ),
                      );
                    }
                    return _MessageBubble(message: messages[index]);
                  },
                ),
              ),
            ),
            _QuickReplies(onReply: (text) => _send(app, text)),
            _InputBar(
              controller: textController,
              onSend: () => _send(app, textController.text),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(AppController app, String value) async {
    final text = value.trim();
    if (text.isEmpty) {
      return;
    }
    textController.clear();
    await app.sendMessage(text);
    await app.markChatRead();
    _scrollToBottom();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    if (message.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: StatusPill(
            label: message.text,
            color: WtfColors.ink.withValues(alpha: 0.7),
            icon: Icons.info_outline,
          ),
        ),
      );
    }

    final mine = message.senderId == app.currentUser.id;
    final senderRole = message.senderId == SeedData.trainerId
        ? AppRole.trainer
        : AppRole.member;
    final color = roleColor(senderRole);
    final bubbleColor = mine ? color : WtfColors.surface;
    final textColor = mine ? Colors.white : WtfColors.ink;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 16, end: 0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, dy, child) => Transform.translate(
        offset: Offset(0, dy),
        child: Opacity(opacity: 1 - dy / 20, child: child),
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: mine ? 0.08 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: textColor),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatTime(message.createdAt),
                      style: TextStyle(
                        color: mine
                            ? Colors.white.withValues(alpha: 0.85)
                            : WtfColors.ink.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.status == MessageStatus.read
                            ? Icons.done_all
                            : Icons.done,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: WtfColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const AnimatedTypingDots(),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.onReply});

  final ValueChanged<String> onReply;

  @override
  Widget build(BuildContext context) {
    const replies = ['Got it', 'Can we talk at 6?', 'Share plan?'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ActionChip(
          backgroundColor: WtfColors.surface,
          side: const BorderSide(color: WtfColors.line),
          label: Text(
            replies[index],
            style: const TextStyle(
              color: WtfColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          onPressed: () => onReply(replies[index]),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: WtfColors.background,
        border: Border(top: BorderSide(color: WtfColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: FilledButton(
                onPressed: onSend,
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                child: const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
