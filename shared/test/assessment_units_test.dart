import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  test('Message serializes and deserializes', () {
    final message = Message(
      id: 'msg_1',
      chatId: SeedData.chatId,
      senderId: SeedData.memberId,
      receiverId: SeedData.trainerId,
      text: 'Hi Coach',
      createdAt: DateTime.utc(2026, 5, 22, 10, 30),
      status: MessageStatus.sent,
    );

    final decoded = Message.fromJson(message.toJson());

    expect(decoded.id, 'msg_1');
    expect(decoded.text, 'Hi Coach');
    expect(decoded.status, MessageStatus.sent);
    expect(decoded.createdAt.toUtc(), DateTime.utc(2026, 5, 22, 10, 30));
  });

  test('Scheduler rejects past slots', () {
    final now = DateTime(2026, 5, 22, 10);
    final error = ScheduleValidator.validateSlot(
      now.subtract(const Duration(minutes: 1)),
      const [],
      now: now,
    );

    expect(error, 'Choose a future time slot.');
  });

  test('Scheduler rejects approved conflicts', () {
    final now = DateTime(2026, 5, 22, 10);
    final request = CallRequest(
      id: 'req_1',
      memberId: SeedData.memberId,
      trainerId: SeedData.trainerId,
      requestedAt: now,
      scheduledFor: now.add(const Duration(hours: 1)),
      note: 'Macros review',
      status: CallRequestStatus.approved,
    );

    final error = ScheduleValidator.validateSlot(
      now.add(const Duration(hours: 1, minutes: 15)),
      [request],
      now: now,
    );

    expect(error, 'That slot is already approved. Pick another time.');
  });

  test('Session duration calculation is bounded and positive', () {
    final start = DateTime(2026, 5, 22, 12);
    final end = start.add(const Duration(minutes: 42, seconds: 5));

    expect(SessionLog.calculateDurationSec(start, end), 2525);
    expect(SessionLog.calculateDurationSec(end, start), 0);
  });

  testWidgets('Chat route can still read ControllerScope', (tester) async {
    SharedPreferences.setMockInitialValues({'wtf_member_ready': true});

    await tester.pumpWidget(
      WtfApp(role: AppRole.member, bridge: _FakeDevBridgeClient()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Start chat'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Aarav'), findsOneWidget);
  });
}

class _FakeDevBridgeClient extends DevBridgeClient {
  _FakeDevBridgeClient() : super(baseUrl: 'http://fake.local');

  @override
  Future<AppSnapshot> fetchState() async => AppSnapshot.seeded();

  @override
  Future<void> markRead({
    required String userId,
    required String chatId,
  }) async {}
}
