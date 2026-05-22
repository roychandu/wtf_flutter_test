import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

import '../models/wtf_models.dart';
import '../services/app_controller.dart';
import '../services/dev_bridge_client.dart';
import '../services/hms_meeting_controller.dart';
import '../utils/wtf_theme.dart';
import '../widgets/wtf_components.dart';

class WtfApp extends StatefulWidget {
  const WtfApp({super.key, required this.role, this.bridge});

  final AppRole role;
  final DevBridgeClient? bridge;

  @override
  State<WtfApp> createState() => _WtfAppState();
}

class _WtfAppState extends State<WtfApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController(role: widget.role, bridge: widget.bridge)
      ..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: widget.role == AppRole.member ? 'Guru App' : 'Trainer App',
        theme: wtfTheme(widget.role),
        home: _Bootstrap(role: widget.role, controller: controller),
      ),
    );
  }
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap({required this.role, required this.controller});

  final AppRole role;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.ready) {
          return const _SplashScreen();
        }
        if (!controller.onboardingComplete) {
          return role == AppRole.member
              ? const _MemberOnboardingScreen()
              : const _TrainerLoginScreen();
        }
        return const _RoleHomeShell();
      },
    );
  }
}

class ControllerScope extends InheritedNotifier<AppController> {
  const ControllerScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ControllerScope>();
    assert(scope != null, 'ControllerScope missing from widget tree.');
    return scope!.notifier!;
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('Preparing local workspace...'),
          ],
        ),
      ),
    );
  }
}

class _MemberOnboardingScreen extends StatefulWidget {
  const _MemberOnboardingScreen();

  @override
  State<_MemberOnboardingScreen> createState() =>
      _MemberOnboardingScreenState();
}

class _MemberOnboardingScreenState extends State<_MemberOnboardingScreen> {
  final controller = PageController();
  int page = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: controller,
                      onPageChanged: (value) => setState(() => page = value),
                      children: const [
                        _OnboardingSlide(
                          icon: Icons.forum_outlined,
                          title: 'Stay close to your trainer',
                          body:
                              'Chat, schedule calls, and keep your session history in one clean workspace.',
                        ),
                        _OnboardingSlide(
                          icon: Icons.video_call_outlined,
                          title: 'DK is ready to train',
                          body:
                              'Your profile is prefilled as DK and Aarav is available as the lead trainer.',
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) {
                      final active = index == page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: active ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : WtfColors.line,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  WtfCard(
                    child: Row(
                      children: [
                        InitialsAvatar(
                          label: 'DK',
                          color: WtfColors.guruPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DK',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Assigned to Aarav',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const StatusPill(
                          label: 'Auto-assigned',
                          color: WtfColors.success,
                          icon: Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: app.completeOnboarding,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Create DK profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(56),
          ),
          child: Icon(icon, size: 48, color: color),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: WtfColors.mutedInk),
        ),
      ],
    );
  }
}

class _TrainerLoginScreen extends StatelessWidget {
  const _TrainerLoginScreen();

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: WtfCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InitialsAvatar(
                      label: 'AR',
                      color: WtfColors.trainerPrimary,
                      size: 56,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome back, Aarav',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mock login for the trainer console.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: WtfColors.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: app.completeOnboarding,
                      icon: const Icon(Icons.login),
                      label: const Text('Login as Aarav'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleHomeShell extends StatefulWidget {
  const _RoleHomeShell();

  @override
  State<_RoleHomeShell> createState() => _RoleHomeShellState();
}

class _RoleHomeShellState extends State<_RoleHomeShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    final role = app.role;
    final member = role == AppRole.member;
    final destinations = member
        ? const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Sessions',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(Icons.pending_actions_outlined),
              selectedIcon: Icon(Icons.pending_actions),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Sessions',
            ),
          ];

    final pages = member
        ? [
            _MemberHome(
              onSelect: (index) => setState(() => selectedIndex = index),
            ),
            const ChatListScreen(),
            const ScheduleScreen(),
            const SessionsScreen(),
          ]
        : [
            _TrainerHome(
              onSelect: (index) => setState(() => selectedIndex = index),
            ),
            const ChatListScreen(),
            const RequestsScreen(),
            const SessionsScreen(),
          ];

    return AdaptiveScaffold(
      selectedIndex: selectedIndex,
      destinations: destinations,
      onDestinationSelected: (index) => setState(() => selectedIndex = index),
      title: member ? 'Guru App' : 'Trainer App',
      roleBadge: RoleBadge(
        role: app.currentUser.role,
        name: app.currentUser.name,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(selectedIndex),
          child: pages[selectedIndex],
        ),
      ),
      floatingActionButton: selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ConversationScreen(),
                ),
              ),
              tooltip: 'Start chat',
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.small(
              onPressed: () => _showDevPanel(context, app),
              tooltip: 'Open DevPanel',
              child: const Icon(Icons.more_vert),
            ),
    );
  }
}

class _MemberHome extends StatelessWidget {
  const _MemberHome({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    return PageShell(
      children: [
        const SectionHeader(
          title: 'Hi DK',
          subtitle: 'Your trainer workspace is synced for local demo runs.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= kMobileBreakpoint;
            final children = [
              _HomeActionCard(
                icon: Icons.forum_outlined,
                title: 'Chat with Trainer',
                subtitle:
                    '${app.snapshot.unreadFor(app.currentUser.id)} unread updates',
                onTap: () => onSelect(1),
              ),
              _HomeActionCard(
                icon: Icons.event_available_outlined,
                title: 'Schedule Call',
                subtitle: 'Pick a 30-min slot',
                onTap: () => onSelect(2),
              ),
              _HomeActionCard(
                icon: Icons.insights_outlined,
                title: 'My Sessions',
                subtitle: '${app.snapshot.sessions.length} logged sessions',
                onTap: () => onSelect(3),
              ),
            ];
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: wide ? 3 : 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: wide ? 1.35 : 3.6,
              children: children,
            );
          },
        ),
        const SizedBox(height: 24),
        const UpcomingCallsList(),
      ],
    );
  }
}

class _TrainerHome extends StatelessWidget {
  const _TrainerHome({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    final pending = app.snapshot.requests
        .where((request) => request.status == CallRequestStatus.pending)
        .length;
    return PageShell(
      children: [
        const SectionHeader(
          title: 'Coach console',
          subtitle:
              'Review DK activity, chats, call requests, and session notes.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth >= kDesktopBreakpoint
                ? 4
                : (constraints.maxWidth >= kMobileBreakpoint ? 2 : 1);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: count,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: count == 1 ? 3.6 : 1.2,
              children: [
                _HomeActionCard(
                  icon: Icons.people_outline,
                  title: 'Members',
                  subtitle: 'DK assigned',
                  onTap: () => onSelect(0),
                ),
                _HomeActionCard(
                  icon: Icons.forum_outlined,
                  title: 'Chats',
                  subtitle:
                      '${app.snapshot.unreadFor(app.currentUser.id)} unread',
                  onTap: () => onSelect(1),
                ),
                _HomeActionCard(
                  icon: Icons.pending_actions_outlined,
                  title: 'Requests',
                  subtitle: '$pending pending',
                  onTap: () => onSelect(2),
                ),
                _HomeActionCard(
                  icon: Icons.history_outlined,
                  title: 'Sessions',
                  subtitle: '${app.snapshot.sessions.length} complete',
                  onTap: () => onSelect(3),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const UpcomingCallsList(),
      ],
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return WtfCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: WtfColors.mutedInk),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: WtfColors.mutedInk),
        ],
      ),
    );
  }
}

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
      final app = ControllerScope.of(context);
      app.markChatRead();
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
            Expanded(child: Text(app.peer.name)),
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
            color: WtfColors.mutedInk,
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
                            ? Colors.white.withValues(alpha: 0.75)
                            : WtfColors.mutedInk,
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
          label: Text(replies[index]),
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
                  hintText: 'Message',
                  labelText: 'Message',
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

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int selectedDay = 0;
  DateTime? selectedSlot;
  final noteController = TextEditingController(text: 'Macros review');
  bool submitting = false;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    final days = List.generate(
      3,
      (index) => DateTime.now().add(Duration(days: index)),
    );
    final day = days[selectedDay];
    final slots = _slotsFor(day);
    return PageShell(
      children: [
        const SectionHeader(
          title: 'Schedule a call',
          subtitle: 'Choose the next three days and one 30-minute slot.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < days.length; i++)
              ChoiceChip(
                selected: selectedDay == i,
                label: Text(i == 0 ? 'Today' : formatDate(days[i])),
                onSelected: (_) => setState(() {
                  selectedDay = i;
                  selectedSlot = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        WtfCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots)
                ChoiceChip(
                  selected: selectedSlot == slot,
                  label: Text(formatTime(slot)),
                  onSelected: slot.isAfter(DateTime.now())
                      ? (_) => setState(() => selectedSlot = slot)
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: noteController,
          maxLength: 140,
          decoration: const InputDecoration(
            labelText: 'Note for Aarav',
            helperText: 'Example: Macros review',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: selectedSlot == null || submitting
              ? null
              : () async {
                  setState(() => submitting = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final error = await app.requestCall(
                    scheduledFor: selectedSlot!,
                    note: noteController.text.trim(),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  setState(() => submitting = false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        error ??
                            'Call requested. Waiting for trainer approval.',
                      ),
                    ),
                  );
                },
          icon: submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_outlined),
          label: const Text('Request Call'),
        ),
        const SizedBox(height: 24),
        _MyRequestsList(requests: app.snapshot.sortedRequests),
      ],
    );
  }

  List<DateTime> _slotsFor(DateTime day) {
    final start = DateTime(day.year, day.month, day.day, 8);
    return List.generate(
      25,
      (index) => start.add(Duration(minutes: index * 30)),
    );
  }
}

class _MyRequestsList extends StatelessWidget {
  const _MyRequestsList({required this.requests});

  final List<CallRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No call requests yet.',
        actionLabel: 'Pick a slot',
        onAction: () {},
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'My Requests'),
        for (final request in requests)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RequestCard(request: request, trainerMode: false),
          ),
      ],
    );
  }
}

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    final requests = app.snapshot.sortedRequests;
    return PageShell(
      children: [
        const SectionHeader(
          title: 'Call requests',
          subtitle: 'Approve or decline DK’s requested slots inline.',
        ),
        if (requests.isEmpty)
          EmptyState(
            icon: Icons.pending_actions_outlined,
            title: 'No pending requests.',
            actionLabel: 'Refresh',
            onAction: app.refresh,
          )
        else
          for (final request in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RequestCard(request: request, trainerMode: true),
            ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.trainerMode});

  final CallRequest request;
  final bool trainerMode;

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    final color = switch (request.status) {
      CallRequestStatus.pending => WtfColors.warning,
      CallRequestStatus.approved => WtfColors.success,
      CallRequestStatus.declined => WtfColors.error,
      CallRequestStatus.cancelled => WtfColors.mutedInk,
    };
    return WtfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatDate(request.scheduledFor)} • ${formatTime(request.scheduledFor)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusPill(label: request.status.name, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.status == CallRequestStatus.pending
                ? 'Pending approval by Aarav'
                : request.status == CallRequestStatus.declined
                ? 'Call request declined. Reason: ${request.declineReason ?? 'No reason'}'
                : 'Call approved for ${formatDate(request.scheduledFor)} ${formatTime(request.scheduledFor)}.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: WtfColors.mutedInk),
          ),
          if (request.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(request.note, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          if (trainerMode && request.status == CallRequestStatus.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _decline(context, app),
                    icon: const Icon(Icons.close),
                    label: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => app.approveRequest(request),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            )
          else if (request.status == CallRequestStatus.approved)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: request.isJoinable
                      ? () => showPreJoinSheet(context, request)
                      : null,
                  icon: const Icon(Icons.video_call_outlined),
                  label: const Text('Join Call'),
                ),
                OutlinedButton.icon(
                  onPressed: () => app.simulateNow(request),
                  icon: const Icon(Icons.schedule_send_outlined),
                  label: const Text('Simulate now'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _decline(BuildContext context, AppController app) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline request'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason != null && reason.isNotEmpty) {
      await app.declineRequest(request, reason);
    }
  }
}

class UpcomingCallsList extends StatelessWidget {
  const UpcomingCallsList({super.key});

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    final calls = app.snapshot.upcomingCalls;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Upcoming Calls'),
        if (calls.isEmpty)
          EmptyState(
            icon: Icons.video_call_outlined,
            title: 'Schedule your first call.',
            actionLabel: app.role == AppRole.member
                ? 'Open scheduler'
                : 'Review requests',
            onAction: () {},
          )
        else
          for (final request in calls)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RequestCard(request: request, trainerMode: false),
            ),
      ],
    );
  }
}

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    final sessions = _filtered(app.snapshot.sortedSessions);
    return PageShell(
      children: [
        SectionHeader(
          title: app.role == AppRole.member ? 'My Sessions' : 'Session logs',
          subtitle: 'Latest sessions appear first with ratings and notes.',
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final value in ['All', 'Last 7 days', 'This Month'])
              ChoiceChip(
                selected: filter == value,
                label: Text(value),
                onSelected: (_) => setState(() => filter = value),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (sessions.isEmpty)
          EmptyState(
            icon: Icons.history_outlined,
            title: 'Schedule your first call.',
            actionLabel: 'Refresh',
            onAction: app.refresh,
          )
        else
          for (final session in sessions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WtfCard(
                onTap: () => _showSessionDetail(context, session),
                child: Row(
                  children: [
                    InitialsAvatar(
                      label: '${session.startedAt.day}',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatDate(session.startedAt)} • ${formatTime(session.startedAt)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatDuration(session.durationSec)}${session.rating == null ? '' : ' • ${session.rating}/5'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: WtfColors.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: WtfColors.mutedInk),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  List<SessionLog> _filtered(List<SessionLog> sessions) {
    final now = DateTime.now();
    return sessions.where((session) {
      if (filter == 'Last 7 days') {
        return session.startedAt.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (filter == 'This Month') {
        return session.startedAt.year == now.year &&
            session.startedAt.month == now.month;
      }
      return true;
    }).toList();
  }

  void _showSessionDetail(BuildContext context, SessionLog session) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session detail',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text('Duration: ${formatDuration(session.durationSec)}'),
            Text(
              'Rating: ${session.rating == null ? 'Not rated' : '${session.rating}/5'}',
            ),
            const SizedBox(height: 12),
            Text(
              'Member note: ${session.memberNotes?.isNotEmpty == true ? session.memberNotes : 'None'}',
            ),
            Text(
              'Trainer note: ${session.trainerNotes?.isNotEmpty == true ? session.trainerNotes : 'None'}',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPreJoinSheet(BuildContext context, CallRequest request) async {
  var micOn = true;
  var cameraOn = true;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to join? Check mic and camera.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: WtfColors.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    cameraOn
                        ? Icons.videocam_outlined
                        : Icons.videocam_off_outlined,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: micOn,
                onChanged: (value) => setModalState(() => micOn = value),
                title: const Text('Microphone'),
                secondary: const Icon(Icons.mic_outlined),
              ),
              SwitchListTile(
                value: cameraOn,
                onChanged: (value) => setModalState(() => cameraOn = value),
                title: const Text('Camera'),
                secondary: const Icon(Icons.videocam_outlined),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CallScreen(
                        request: request,
                        micOn: micOn,
                        cameraOn: cameraOn,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.video_call),
                label: const Text('Join room'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.request,
    required this.micOn,
    required this.cameraOn,
  });

  final CallRequest request;
  final bool micOn;
  final bool cameraOn;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final meeting = HmsMeetingController();
  late final DateTime startedAt;
  bool mockMode = false;
  bool ending = false;

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  @override
  void dispose() {
    meeting.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final app = ControllerScope.of(context);
    final roomMeta = widget.request.roomMeta;
    if (roomMeta == null) {
      setState(() => mockMode = true);
      return;
    }
    final role = app.role == AppRole.member
        ? roomMeta.hmsRoleMember
        : roomMeta.hmsRoleTrainer;
    try {
      final token = await app.bridge.fetchHmsToken(
        userId: app.currentUser.id,
        role: role,
        roomId: roomMeta.hmsRoomId,
      );
      if (token.mock || token.authToken.startsWith('mock.')) {
        setState(() => mockMode = true);
        return;
      }
      await meeting.join(
        authToken: token.authToken,
        userName: app.currentUser.name,
        startMuted: !widget.micOn,
        startCameraOff: !widget.cameraOn,
      );
    } on Object {
      setState(() => mockMode = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: Text(mockMode ? '100ms call • Dev mode' : '100ms call'),
        actions: [
          if (meeting.reconnecting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: meeting,
          builder: (context, _) {
            final peers = meeting.peers;
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 600;
                        return GridView.count(
                          crossAxisCount: twoColumns ? 2 : 1,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 4 / 3,
                          children: [
                            _ParticipantTile(
                              name: app.currentUser.name,
                              role: app.currentUser.role,
                              videoTrack: _firstVideoTrack(
                                peers.where((peer) => peer.isLocal),
                                meeting.videoTracks,
                              ),
                              muted: meeting.micMuted,
                              cameraOff: meeting.cameraMuted || mockMode,
                            ),
                            _ParticipantTile(
                              name: app.peer.name,
                              role: app.peer.role,
                              videoTrack: _firstVideoTrack(
                                peers.where((peer) => !peer.isLocal),
                                meeting.videoTracks,
                              ),
                              muted: false,
                              cameraOff: mockMode || peers.length < 2,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (meeting.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StatusPill(
                      label: meeting.error!,
                      color: WtfColors.error,
                      icon: Icons.error_outline,
                    ),
                  )
                else if (mockMode)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: StatusPill(
                      label:
                          'Using local mock tiles until 100ms credentials are configured',
                      color: WtfColors.warning,
                      icon: Icons.info_outline,
                    ),
                  ),
                const SizedBox(height: 12),
                _CallControls(
                  micMuted: meeting.micMuted,
                  cameraMuted: meeting.cameraMuted || mockMode,
                  ending: ending,
                  onMic: mockMode
                      ? () =>
                            setState(() => meeting.micMuted = !meeting.micMuted)
                      : meeting.toggleMic,
                  onCamera: mockMode
                      ? () => setState(
                          () => meeting.cameraMuted = !meeting.cameraMuted,
                        )
                      : meeting.toggleCamera,
                  onFlip: mockMode ? () {} : meeting.switchCamera,
                  onEnd: () => _endCall(app),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _endCall(AppController app) async {
    if (ending) {
      return;
    }
    setState(() => ending = true);
    await meeting.leave();
    final endedAt = DateTime.now();
    final session = await app.completeSession(
      request: widget.request,
      startedAt: startedAt,
      endedAt: endedAt,
    );
    if (!mounted) {
      return;
    }
    await _showPostCallSheet(context, app, session);
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Session saved to your logs.')),
      );
    }
  }
}

HMSVideoTrack? _firstVideoTrack(
  Iterable<HMSPeer> peers,
  Map<String, HMSVideoTrack> tracks,
) {
  for (final peer in peers) {
    final track = tracks[peer.peerId];
    if (track != null) {
      return track;
    }
  }
  return null;
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.name,
    required this.role,
    required this.videoTrack,
    required this.muted,
    required this.cameraOff,
  });

  final String name;
  final AppRole role;
  final HMSVideoTrack? videoTrack;
  final bool muted;
  final bool cameraOff;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(role);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFF111827),
            child: videoTrack != null && !cameraOff
                ? HMSVideoView(track: videoTrack!)
                : Center(
                    child: InitialsAvatar(
                      label: name
                          .substring(0, name.length >= 2 ? 2 : 1)
                          .toUpperCase(),
                      color: color,
                      size: 72,
                    ),
                  ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (muted)
                  const Icon(Icons.mic_off, color: Colors.white, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.micMuted,
    required this.cameraMuted,
    required this.ending,
    required this.onMic,
    required this.onCamera,
    required this.onFlip,
    required this.onEnd,
  });

  final bool micMuted;
  final bool cameraMuted;
  final bool ending;
  final VoidCallback onMic;
  final VoidCallback onCamera;
  final VoidCallback onFlip;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundCallButton(
            tooltip: micMuted ? 'Unmute' : 'Mute',
            icon: micMuted ? Icons.mic_off : Icons.mic,
            onPressed: onMic,
          ),
          const SizedBox(width: 10),
          _RoundCallButton(
            tooltip: cameraMuted ? 'Video on' : 'Video off',
            icon: cameraMuted ? Icons.videocam_off : Icons.videocam,
            onPressed: onCamera,
          ),
          const SizedBox(width: 10),
          _RoundCallButton(
            tooltip: 'Flip camera',
            icon: Icons.cameraswitch,
            onPressed: onFlip,
          ),
          const SizedBox(width: 10),
          _RoundCallButton(
            tooltip: 'End call',
            icon: ending ? Icons.hourglass_empty : Icons.call_end,
            color: WtfColors.error,
            onPressed: ending ? null : onEnd,
          ),
        ],
      ),
    );
  }
}

class _RoundCallButton extends StatelessWidget {
  const _RoundCallButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: IconButton.filled(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: color ?? Colors.white.withValues(alpha: 0.12),
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

Future<void> _showPostCallSheet(
  BuildContext context,
  AppController app,
  SessionLog session,
) async {
  final noteController = TextEditingController();
  var rating = 5;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        final member = app.role == AppRole.member;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member ? 'Rate session' : 'Complete session',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              if (member)
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        tooltip: '$i star',
                        onPressed: () => setModalState(() => rating = i),
                        icon: Icon(
                          i <= rating ? Icons.star : Icons.star_border,
                          color: WtfColors.warning,
                        ),
                      ),
                  ],
                ),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: member ? 'Optional note' : 'Trainer notes',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await app.updateSession(
                    session: session,
                    rating: member ? rating : session.rating,
                    memberNotes: member
                        ? noteController.text.trim()
                        : session.memberNotes,
                    trainerNotes: member
                        ? session.trainerNotes
                        : noteController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(member ? 'Save rating' : 'Mark as complete'),
              ),
            ],
          ),
        );
      },
    ),
  );
  noteController.dispose();
}

void _showDevPanel(BuildContext context, AppController app) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DevPanel', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          StatusPill(
            label: app.bridgeOnline ? 'Bridge online' : 'Bridge offline',
            color: app.bridgeOnline ? WtfColors.success : WtfColors.warning,
            icon: app.bridgeOnline ? Icons.wifi : Icons.wifi_off,
          ),
          const SizedBox(height: 12),
          Text('Bridge: ${app.bridge.baseUrl}'),
          const Text('100ms: HMS_APP_ACCESS_KEY=masked, HMS_APP_SECRET=masked'),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final log in app.snapshot.logs.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      log,
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: app.resetDemo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset demo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
