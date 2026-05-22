import 'package:flutter/material.dart';
import '../../models/wtf_models.dart';
import '../../services/app_controller.dart';
import '../../utils/wtf_theme.dart';
import '../../widgets/wtf_components.dart';
import '../requests/request_card.dart';
import '../wtf_app.dart';

class MemberHome extends StatelessWidget {
  const MemberHome({super.key, required this.onSelect});

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
              HomeActionCard(
                icon: Icons.forum_outlined,
                title: 'Chat with Trainer',
                subtitle:
                    '${app.snapshot.unreadFor(app.currentUser.id)} unread updates',
                onTap: () => onSelect(1),
              ),
              HomeActionCard(
                icon: Icons.event_available_outlined,
                title: 'Schedule Call',
                subtitle: 'Pick a 30-min slot',
                onTap: () => onSelect(2),
              ),
              HomeActionCard(
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

class HomeActionCard extends StatelessWidget {
  const HomeActionCard({
    super.key,
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
