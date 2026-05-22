import 'package:flutter/material.dart';
import '../../models/wtf_models.dart';
import '../../services/app_controller.dart';
import '../../utils/wtf_theme.dart';
import '../../widgets/wtf_components.dart';
import '../requests/request_card.dart';
import '../wtf_app.dart';

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
            child: RequestCard(request: request, trainerMode: false),
          ),
      ],
    );
  }
}
