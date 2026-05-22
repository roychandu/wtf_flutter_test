import 'package:flutter/material.dart';
import 'package:wtf_shared/screens/wtf_app.dart';
import '../../models/wtf_models.dart';
import '../../services/app_controller.dart';
import '../../utils/wtf_theme.dart';
import '../../widgets/wtf_components.dart';
import '../call/call_screen.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.trainerMode,
  });

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
              child: RequestCard(request: request, trainerMode: false),
            ),
      ],
    );
  }
}
