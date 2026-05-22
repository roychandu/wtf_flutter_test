import 'package:flutter/material.dart';
import '../../models/wtf_models.dart';
import '../../services/app_controller.dart';
import '../../utils/wtf_theme.dart';
import '../../widgets/wtf_components.dart';
import '../requests/request_card.dart';
import '../wtf_app.dart';
import 'member_home.dart';

class TrainerHome extends StatelessWidget {
  const TrainerHome({super.key, required this.onSelect});

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
                HomeActionCard(
                  icon: Icons.people_outline,
                  title: 'Members',
                  subtitle: 'DK assigned',
                  onTap: () => onSelect(0),
                ),
                HomeActionCard(
                  icon: Icons.forum_outlined,
                  title: 'Chats',
                  subtitle:
                      '${app.snapshot.unreadFor(app.currentUser.id)} unread',
                  onTap: () => onSelect(1),
                ),
                HomeActionCard(
                  icon: Icons.pending_actions_outlined,
                  title: 'Requests',
                  subtitle: '$pending pending',
                  onTap: () => onSelect(2),
                ),
                HomeActionCard(
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
