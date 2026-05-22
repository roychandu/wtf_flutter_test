import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  test('Guru app can read shared message JSON', () {
    final message = Message.fromJson({
      'id': 'msg_1',
      'chatId': SeedData.chatId,
      'senderId': SeedData.memberId,
      'receiverId': SeedData.trainerId,
      'text': 'Hi Coach',
      'createdAt': '2026-05-22T10:30:00.000Z',
      'status': 'sent',
    });

    expect(message.text, 'Hi Coach');
    expect(message.status, MessageStatus.sent);
  });

  test('Guru scheduler blocks past time', () {
    final now = DateTime(2026, 5, 22, 10);
    expect(
      ScheduleValidator.validateSlot(
        now.subtract(const Duration(minutes: 1)),
        const [],
        now: now,
      ),
      'Choose a future time slot.',
    );
  });

  test('Guru session duration is calculated', () {
    final start = DateTime(2026, 5, 22, 12);
    expect(
      SessionLog.calculateDurationSec(
        start,
        start.add(const Duration(minutes: 30)),
      ),
      1800,
    );
  });
}
