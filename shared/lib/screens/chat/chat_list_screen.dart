import 'package:flutter/material.dart';
import '../../models/wtf_models.dart';
import '../../services/app_controller.dart';
import '../../utils/wtf_theme.dart';
import '../../widgets/wtf_components.dart';
import '../wtf_app.dart';
import 'conversation_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    final messages = app.snapshot.sortedMessages;
    final last = messages.isEmpty ? null : messages.last;
    return PageShell(
      children: [
        SectionHeader(
          title: app.role == AppRole.member ? 'Trainer chat' : 'Member chats',
          subtitle: 'Real-time bridge with typing and read receipts.',
        ),
        if (messages.isEmpty)
          EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No messages yet. Start the conversation.',
            actionLabel: 'Say hi',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const ConversationScreen(initialText: 'Hi Coach'),
              ),
            ),
          )
        else
          WtfCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ConversationScreen(),
              ),
            ),
            child: Row(
              children: [
                InitialsAvatar(
                  label: app.peer.avatarUrl ?? app.peer.name.substring(0, 1),
                  color: roleColor(app.peer.role),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.peer.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            relativeTime(last!.createdAt),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        last.system
                            ? last.text
                            : '${last.senderId == app.currentUser.id ? 'You: ' : ''}${last.text}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WtfColors.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _UnreadBadge(count: app.snapshot.unreadFor(app.currentUser.id)),
              ],
            ),
          ),
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}
