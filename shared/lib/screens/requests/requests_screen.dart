import 'package:flutter/material.dart';
import '../../models/wtf_models.dart';
import '../../services/app_controller.dart';
import '../../widgets/wtf_components.dart';
import '../wtf_app.dart';
import 'request_card.dart';

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
              child: RequestCard(request: request, trainerMode: true),
            ),
      ],
    );
  }
}
