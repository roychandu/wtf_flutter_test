import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  test('Trainer app can read shared message JSON', () {
    final message = Message.fromJson({
      'id': 'msg_2',
      'chatId': SeedData.chatId,
      'senderId': SeedData.trainerId,
      'receiverId': SeedData.memberId,
      'text': 'Plan shared',
      'createdAt': '2026-05-22T11:30:00.000Z',
      'status': 'read',
    });

    expect(message.senderId, SeedData.trainerId);
    expect(message.status, MessageStatus.read);
  });

  test('Trainer scheduler blocks approved conflicts', () {
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

    expect(
      ScheduleValidator.validateSlot(now.add(const Duration(hours: 1)), [
        request,
      ], now: now),
      'That slot is already approved. Pick another time.',
    );
  });

  test('Trainer session duration clamps negative values', () {
    final end = DateTime(2026, 5, 22, 12);
    expect(
      SessionLog.calculateDurationSec(end.add(const Duration(minutes: 1)), end),
      0,
    );
  });
}
