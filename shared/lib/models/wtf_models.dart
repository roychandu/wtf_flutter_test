import 'dart:math';

enum AppRole { member, trainer }

extension AppRoleX on AppRole {
  String get value => switch (this) {
    AppRole.member => 'member',
    AppRole.trainer => 'trainer',
  };

  String get label => switch (this) {
    AppRole.member => 'Guru',
    AppRole.trainer => 'Trainer',
  };

  static AppRole fromValue(String value) => switch (value) {
    'trainer' => AppRole.trainer,
    _ => AppRole.member,
  };
}

enum MessageStatus { sending, sent, read }

enum CallRequestStatus { pending, approved, declined, cancelled }

class SeedData {
  static const memberId = 'member_dk';
  static const trainerId = 'trainer_aarav';
  static const chatId = 'chat_dk_aarav';

  static final dk = UserProfile(
    id: memberId,
    role: AppRole.member,
    name: 'DK',
    email: 'dk@wtf.local',
    avatarUrl: 'DK',
    assignedTrainerId: trainerId,
  );

  static final aarav = UserProfile(
    id: trainerId,
    role: AppRole.trainer,
    name: 'Aarav',
    email: 'aarav@wtf.local',
    avatarUrl: 'AR',
    assignedTrainerId: null,
  );
}

String newId(String prefix) {
  final now = DateTime.now().microsecondsSinceEpoch;
  final salt = Random().nextInt(1 << 32).toRadixString(16);
  return '${prefix}_${now}_$salt';
}

DateTime parseDate(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value).toLocal();
  }
  return DateTime.now();
}

String encodeDate(DateTime value) => value.toUtc().toIso8601String();

class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.assignedTrainerId,
  });

  final String id;
  final AppRole role;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? assignedTrainerId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.value,
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'assignedTrainerId': assignedTrainerId,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    role: AppRoleX.fromValue(json['role'] as String? ?? 'member'),
    name: json['name'] as String,
    email: json['email'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    assignedTrainerId: json['assignedTrainerId'] as String?,
  );
}

class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.status,
    this.system = false,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;
  final bool system;

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? createdAt,
    MessageStatus? status,
    bool? system,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      system: system ?? this.system,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'createdAt': encodeDate(createdAt),
    'status': status.name,
    'system': system,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    chatId: json['chatId'] as String,
    senderId: json['senderId'] as String,
    receiverId: json['receiverId'] as String,
    text: json['text'] as String,
    createdAt: parseDate(json['createdAt']),
    status: MessageStatus.values.byName(
      json['status'] as String? ?? MessageStatus.sent.name,
    ),
    system: json['system'] as bool? ?? false,
  );
}

class RoomMeta {
  const RoomMeta({
    required this.id,
    required this.callRequestId,
    required this.hmsRoomId,
    required this.hmsRoleMember,
    required this.hmsRoleTrainer,
  });

  final String id;
  final String callRequestId;
  final String hmsRoomId;
  final String hmsRoleMember;
  final String hmsRoleTrainer;

  Map<String, dynamic> toJson() => {
    'id': id,
    'callRequestId': callRequestId,
    'hmsRoomId': hmsRoomId,
    'hmsRoleMember': hmsRoleMember,
    'hmsRoleTrainer': hmsRoleTrainer,
  };

  factory RoomMeta.fromJson(Map<String, dynamic> json) => RoomMeta(
    id: json['id'] as String,
    callRequestId: json['callRequestId'] as String,
    hmsRoomId: json['hmsRoomId'] as String,
    hmsRoleMember: json['hmsRoleMember'] as String? ?? 'member',
    hmsRoleTrainer: json['hmsRoleTrainer'] as String? ?? 'trainer',
  );
}

class CallRequest {
  const CallRequest({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.requestedAt,
    required this.scheduledFor,
    required this.note,
    required this.status,
    this.declineReason,
    this.roomMeta,
  });

  final String id;
  final String memberId;
  final String trainerId;
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final String note;
  final CallRequestStatus status;
  final String? declineReason;
  final RoomMeta? roomMeta;

  bool get isJoinable {
    if (status != CallRequestStatus.approved) {
      return false;
    }
    final now = DateTime.now();
    return scheduledFor.difference(now).inMinutes <= 10;
  }

  CallRequest copyWith({
    String? id,
    String? memberId,
    String? trainerId,
    DateTime? requestedAt,
    DateTime? scheduledFor,
    String? note,
    CallRequestStatus? status,
    String? declineReason,
    RoomMeta? roomMeta,
  }) {
    return CallRequest(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      trainerId: trainerId ?? this.trainerId,
      requestedAt: requestedAt ?? this.requestedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      note: note ?? this.note,
      status: status ?? this.status,
      declineReason: declineReason ?? this.declineReason,
      roomMeta: roomMeta ?? this.roomMeta,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'trainerId': trainerId,
    'requestedAt': encodeDate(requestedAt),
    'scheduledFor': encodeDate(scheduledFor),
    'note': note,
    'status': status.name,
    'declineReason': declineReason,
    'roomMeta': roomMeta?.toJson(),
  };

  factory CallRequest.fromJson(Map<String, dynamic> json) => CallRequest(
    id: json['id'] as String,
    memberId: json['memberId'] as String,
    trainerId: json['trainerId'] as String,
    requestedAt: parseDate(json['requestedAt']),
    scheduledFor: parseDate(json['scheduledFor']),
    note: json['note'] as String? ?? '',
    status: CallRequestStatus.values.byName(
      json['status'] as String? ?? CallRequestStatus.pending.name,
    ),
    declineReason: json['declineReason'] as String?,
    roomMeta: json['roomMeta'] == null
        ? null
        : RoomMeta.fromJson(Map<String, dynamic>.from(json['roomMeta'] as Map)),
  );
}

class SessionLog {
  const SessionLog({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.rating,
    this.trainerNotes,
    this.memberNotes,
  });

  final String id;
  final String memberId;
  final String trainerId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final int? rating;
  final String? trainerNotes;
  final String? memberNotes;

  SessionLog copyWith({
    String? id,
    String? memberId,
    String? trainerId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSec,
    int? rating,
    String? trainerNotes,
    String? memberNotes,
  }) {
    return SessionLog(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      trainerId: trainerId ?? this.trainerId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSec: durationSec ?? this.durationSec,
      rating: rating ?? this.rating,
      trainerNotes: trainerNotes ?? this.trainerNotes,
      memberNotes: memberNotes ?? this.memberNotes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'trainerId': trainerId,
    'startedAt': encodeDate(startedAt),
    'endedAt': encodeDate(endedAt),
    'durationSec': durationSec,
    'rating': rating,
    'trainerNotes': trainerNotes,
    'memberNotes': memberNotes,
  };

  factory SessionLog.fromJson(Map<String, dynamic> json) => SessionLog(
    id: json['id'] as String,
    memberId: json['memberId'] as String,
    trainerId: json['trainerId'] as String,
    startedAt: parseDate(json['startedAt']),
    endedAt: parseDate(json['endedAt']),
    durationSec: json['durationSec'] as int? ?? 0,
    rating: json['rating'] as int?,
    trainerNotes: json['trainerNotes'] as String?,
    memberNotes: json['memberNotes'] as String?,
  );

  static int calculateDurationSec(DateTime start, DateTime end) {
    return end.difference(start).inSeconds.clamp(0, 24 * 60 * 60);
  }
}

class AppSnapshot {
  const AppSnapshot({
    required this.users,
    required this.messages,
    required this.requests,
    required this.sessions,
    required this.logs,
    required this.trainerTyping,
    required this.memberTyping,
  });

  final List<UserProfile> users;
  final List<Message> messages;
  final List<CallRequest> requests;
  final List<SessionLog> sessions;
  final List<String> logs;
  final bool trainerTyping;
  final bool memberTyping;

  UserProfile get member =>
      users.firstWhere((user) => user.role == AppRole.member);
  UserProfile get trainer =>
      users.firstWhere((user) => user.role == AppRole.trainer);

  List<Message> get sortedMessages {
    final copy = [...messages];
    copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return copy;
  }

  List<CallRequest> get sortedRequests {
    final copy = [...requests];
    copy.sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));
    return copy;
  }

  List<CallRequest> get upcomingCalls => sortedRequests
      .where((request) => request.status == CallRequestStatus.approved)
      .where(
        (request) => request.scheduledFor.isAfter(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
      )
      .toList();

  List<SessionLog> get sortedSessions {
    final copy = [...sessions];
    copy.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return copy;
  }

  int unreadFor(String userId) {
    return messages
        .where((message) => message.receiverId == userId)
        .where((message) => message.status != MessageStatus.read)
        .length;
  }

  AppSnapshot copyWith({
    List<UserProfile>? users,
    List<Message>? messages,
    List<CallRequest>? requests,
    List<SessionLog>? sessions,
    List<String>? logs,
    bool? trainerTyping,
    bool? memberTyping,
  }) {
    return AppSnapshot(
      users: users ?? this.users,
      messages: messages ?? this.messages,
      requests: requests ?? this.requests,
      sessions: sessions ?? this.sessions,
      logs: logs ?? this.logs,
      trainerTyping: trainerTyping ?? this.trainerTyping,
      memberTyping: memberTyping ?? this.memberTyping,
    );
  }

  Map<String, dynamic> toJson() => {
    'users': users.map((user) => user.toJson()).toList(),
    'messages': messages.map((message) => message.toJson()).toList(),
    'requests': requests.map((request) => request.toJson()).toList(),
    'sessions': sessions.map((session) => session.toJson()).toList(),
    'logs': logs,
    'trainerTyping': trainerTyping,
    'memberTyping': memberTyping,
  };

  factory AppSnapshot.fromJson(Map<String, dynamic> json) => AppSnapshot(
    users: (json['users'] as List? ?? const [])
        .map(
          (item) =>
              UserProfile.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    messages: (json['messages'] as List? ?? const [])
        .map((item) => Message.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    requests: (json['requests'] as List? ?? const [])
        .map(
          (item) =>
              CallRequest.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    sessions: (json['sessions'] as List? ?? const [])
        .map(
          (item) => SessionLog.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    logs: (json['logs'] as List? ?? const [])
        .map((item) => item.toString())
        .toList(),
    trainerTyping: json['trainerTyping'] as bool? ?? false,
    memberTyping: json['memberTyping'] as bool? ?? false,
  );

  factory AppSnapshot.seeded() => AppSnapshot(
    users: [SeedData.dk, SeedData.aarav],
    messages: const [],
    requests: const [],
    sessions: const [],
    logs: const ['[AUTH] Seeded DK and Aarav profiles'],
    trainerTyping: false,
    memberTyping: false,
  );
}

class ScheduleValidator {
  static String? validateSlot(
    DateTime slot,
    List<CallRequest> existingRequests, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    if (!slot.isAfter(reference)) {
      return 'Choose a future time slot.';
    }

    final hasConflict = existingRequests.any((request) {
      if (request.status != CallRequestStatus.approved) {
        return false;
      }
      return request.scheduledFor.difference(slot).inMinutes.abs() < 30;
    });

    if (hasConflict) {
      return 'That slot is already approved. Pick another time.';
    }
    return null;
  }
}
