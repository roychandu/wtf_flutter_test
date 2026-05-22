import 'package:flutter/material.dart';
import '../../models/wtf_models.dart';
import '../../services/app_controller.dart';
import '../../utils/wtf_theme.dart';
import '../../widgets/wtf_components.dart';
import '../wtf_app.dart';

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
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filter == value ? Colors.white : WtfColors.ink,
                ),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: WtfColors.surface,
                side: BorderSide(
                  color: filter == value ? Colors.transparent : WtfColors.line,
                ),
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
