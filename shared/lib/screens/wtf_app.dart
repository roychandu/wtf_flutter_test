import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

import '../models/wtf_models.dart';
import '../services/app_controller.dart';
import '../services/dev_bridge_client.dart';
import '../services/hms_meeting_controller.dart';
import '../utils/wtf_theme.dart';
import '../widgets/wtf_components.dart';

import 'home/member_home.dart';
import 'home/trainer_home.dart';
import 'chat/chat_list_screen.dart';
import 'chat/conversation_screen.dart';
import 'schedule/schedule_screen.dart';
import 'requests/requests_screen.dart';
import 'sessions/sessions_screen.dart';
import 'call/call_screen.dart';

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
            MemberHome(
              onSelect: (index) => setState(() => selectedIndex = index),
            ),
            const ChatListScreen(),
            const ScheduleScreen(),
            const SessionsScreen(),
          ]
        : [
            TrainerHome(
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
