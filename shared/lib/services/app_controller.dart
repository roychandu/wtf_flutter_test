import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wtf_models.dart';
import 'dev_bridge_client.dart';

class AppController extends ChangeNotifier {
  AppController({required this.role, DevBridgeClient? bridge})
    : bridge = bridge ?? DevBridgeClient();

  final AppRole role;
  final DevBridgeClient bridge;

  AppSnapshot snapshot = AppSnapshot.seeded();
  bool ready = false;
  bool bridgeOnline = false;
  bool onboardingComplete = false;
  String? lastError;
  Timer? _poller;

  UserProfile get currentUser =>
      role == AppRole.member ? snapshot.member : snapshot.trainer;
  UserProfile get peer =>
      role == AppRole.member ? snapshot.trainer : snapshot.member;
  bool get otherSideTyping =>
      role == AppRole.member ? snapshot.trainerTyping : snapshot.memberTyping;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    onboardingComplete = prefs.getBool(_prefsKey) ?? false;
    await refresh();
    ready = true;
    notifyListeners();
    _poller = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => refresh(silent: true),
    );
  }

  String get _prefsKey => 'wtf_${role.value}_ready';

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    onboardingComplete = true;
    await prefs.setBool(_prefsKey, true);
    _appendLog('[AUTH] ${currentUser.name} completed first-run setup');
    notifyListeners();
  }

  Future<void> resetLocalAuth() async {
    final prefs = await SharedPreferences.getInstance();
    onboardingComplete = false;
    await prefs.remove(_prefsKey);
    notifyListeners();
  }

  Future<void> refresh({bool silent = false}) async {
    var hasChanged = false;
    try {
      final oldMessagesHash = snapshot.messages.map((m) => '${m.id}:${m.status.name}').join(',');
      final oldTyping = otherSideTyping;
      final oldRequestsHash = snapshot.requests.map((r) => '${r.id}:${r.status.name}:${r.scheduledFor.millisecondsSinceEpoch}:${r.roomMeta?.id}').join(',');
      final oldSessionsHash = snapshot.sessions.map((s) => '${s.id}:${s.rating}:${s.trainerNotes}:${s.memberNotes}').join(',');
      final oldLogsHash = snapshot.logs.join(',');

      final nextSnapshot = await bridge.fetchState();

      final newMessagesHash = nextSnapshot.messages.map((m) => '${m.id}:${m.status.name}').join(',');
      final newTyping = role == AppRole.member ? nextSnapshot.trainerTyping : nextSnapshot.memberTyping;
      final newRequestsHash = nextSnapshot.requests.map((r) => '${r.id}:${r.status.name}:${r.scheduledFor.millisecondsSinceEpoch}:${r.roomMeta?.id}').join(',');
      final newSessionsHash = nextSnapshot.sessions.map((s) => '${s.id}:${s.rating}:${s.trainerNotes}:${s.memberNotes}').join(',');
      final newLogsHash = nextSnapshot.logs.join(',');

      hasChanged = oldMessagesHash != newMessagesHash ||
          oldTyping != newTyping ||
          oldRequestsHash != newRequestsHash ||
          oldSessionsHash != newSessionsHash ||
          oldLogsHash != newLogsHash;

      snapshot = nextSnapshot;
      bridgeOnline = true;
      lastError = null;
    } on Object catch (error) {
      bridgeOnline = false;
      lastError = error.toString();
      if (!silent) {
        _appendLog('[ERROR] $lastError');
      }
    }
    if (hasChanged || !silent) {
      notifyListeners();
    }
  }

  Future<void> resetDemo() async {
    try {
      snapshot = await bridge.reset();
      bridgeOnline = true;
      _appendLog('[AUTH] Demo state reset');
    } on Object catch (error) {
      snapshot = AppSnapshot.seeded();
      bridgeOnline = false;
      lastError = error.toString();
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      return;
    }

    final optimistic = Message(
      id: newId('msg_local'),
      chatId: SeedData.chatId,
      senderId: currentUser.id,
      receiverId: peer.id,
      text: clean,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    snapshot = snapshot.copyWith(messages: [...snapshot.messages, optimistic]);
    notifyListeners();

    try {
      final sent = await bridge.sendMessage(
        senderId: currentUser.id,
        receiverId: peer.id,
        text: clean,
      );
      final messages = snapshot.messages
          .where((message) => message.id != optimistic.id)
          .toList();
      snapshot = snapshot.copyWith(messages: [...messages, sent]);
      bridgeOnline = true;
      _appendLog('[CHAT] ${currentUser.name} sent message to ${peer.name}');
    } on Object catch (error) {
      bridgeOnline = false;
      lastError = error.toString();
      final messages = snapshot.messages.map((message) {
        return message.id == optimistic.id
            ? message.copyWith(status: MessageStatus.sent)
            : message;
      }).toList();
      snapshot = snapshot.copyWith(messages: messages);
      _appendLog('[CHAT] Local fallback message stored');
    }
    notifyListeners();
  }

  Future<void> markChatRead() async {
    final messages = snapshot.messages.map((message) {
      if (message.receiverId == currentUser.id &&
          message.chatId == SeedData.chatId) {
        return message.copyWith(status: MessageStatus.read);
      }
      return message;
    }).toList();
    snapshot = snapshot.copyWith(messages: messages);
    notifyListeners();

    try {
      await bridge.markRead(userId: currentUser.id, chatId: SeedData.chatId);
      await refresh(silent: true);
    } on Object catch (error) {
      bridgeOnline = false;
      lastError = error.toString();
    }
    notifyListeners();
  }

  Future<String?> requestCall({
    required DateTime scheduledFor,
    required String note,
  }) async {
    final validation = ScheduleValidator.validateSlot(
      scheduledFor,
      snapshot.requests,
    );
    if (validation != null) {
      return validation;
    }

    try {
      final request = await bridge.createCallRequest(
        scheduledFor: scheduledFor,
        note: note,
      );
      snapshot = snapshot.copyWith(requests: [...snapshot.requests, request]);
      bridgeOnline = true;
      _appendLog('[SCHEDULE] DK requested a call');
    } on Object catch (error) {
      bridgeOnline = false;
      lastError = error.toString();
      final request = CallRequest(
        id: newId('req_local'),
        memberId: SeedData.memberId,
        trainerId: SeedData.trainerId,
        requestedAt: DateTime.now(),
        scheduledFor: scheduledFor,
        note: note,
        status: CallRequestStatus.pending,
      );
      snapshot = snapshot.copyWith(requests: [...snapshot.requests, request]);
      _appendLog('[SCHEDULE] Local fallback request created');
    }
    notifyListeners();
    return null;
  }

  Future<void> approveRequest(CallRequest request) async {
    await _reviewRequest(request, approved: true);
  }

  Future<void> declineRequest(CallRequest request, String reason) async {
    await _reviewRequest(request, approved: false, reason: reason);
  }

  Future<void> _reviewRequest(
    CallRequest request, {
    required bool approved,
    String? reason,
  }) async {
    try {
      final updated = await bridge.reviewCallRequest(
        requestId: request.id,
        approved: approved,
        reason: reason,
      );
      _replaceRequest(updated);
      bridgeOnline = true;
      _appendLog(
        approved
            ? '[SCHEDULE] Trainer approved call'
            : '[SCHEDULE] Trainer declined call',
      );
    } on Object catch (error) {
      bridgeOnline = false;
      lastError = error.toString();
      final updated = request.copyWith(
        status: approved
            ? CallRequestStatus.approved
            : CallRequestStatus.declined,
        declineReason: reason,
        roomMeta: approved
            ? RoomMeta(
                id: newId('room_local'),
                callRequestId: request.id,
                hmsRoomId: 'dev_${request.id}',
                hmsRoleMember: 'member',
                hmsRoleTrainer: 'trainer',
              )
            : request.roomMeta,
      );
      _replaceRequest(updated);
      _appendLog('[SCHEDULE] Local fallback review saved');
    }
    notifyListeners();
  }

  Future<void> simulateNow(CallRequest request) async {
    try {
      final updated = await bridge.simulateNow(request.id);
      _replaceRequest(updated);
      bridgeOnline = true;
      _appendLog('[RTC] Upcoming call moved into join window');
    } on Object catch (error) {
      bridgeOnline = false;
      lastError = error.toString();
      _replaceRequest(
        request.copyWith(
          scheduledFor: DateTime.now().add(const Duration(minutes: 1)),
        ),
      );
      _appendLog('[RTC] Local fallback join simulation applied');
    }
    notifyListeners();
  }

  Future<SessionLog> completeSession({
    required CallRequest request,
    required DateTime startedAt,
    required DateTime endedAt,
    String? trainerNotes,
    String? memberNotes,
  }) async {
    try {
      final session = await bridge.completeSession(
        requestId: request.id,
        startedAt: startedAt,
        endedAt: endedAt,
        trainerNotes: trainerNotes,
        memberNotes: memberNotes,
      );
      snapshot = snapshot.copyWith(sessions: _upsertSession(session));
      bridgeOnline = true;
      _appendLog('[RTC] Session saved to logs');
      notifyListeners();
      return session;
    } on Object catch (error) {
      bridgeOnline = false;
      lastError = error.toString();
      final session = SessionLog(
        id: newId('session_local'),
        memberId: SeedData.memberId,
        trainerId: SeedData.trainerId,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSec: SessionLog.calculateDurationSec(startedAt, endedAt),
        trainerNotes: trainerNotes,
        memberNotes: memberNotes,
      );
      snapshot = snapshot.copyWith(sessions: _upsertSession(session));
      _appendLog('[RTC] Local fallback session saved');
      notifyListeners();
      return session;
    }
  }

  Future<void> updateSession({
    required SessionLog session,
    int? rating,
    String? trainerNotes,
    String? memberNotes,
  }) async {
    try {
      final updated = await bridge.updateSession(
        sessionId: session.id,
        rating: rating,
        trainerNotes: trainerNotes,
        memberNotes: memberNotes,
      );
      snapshot = snapshot.copyWith(sessions: _upsertSession(updated));
      bridgeOnline = true;
      _appendLog('[RTC] Session feedback updated');
    } on Object catch (error) {
      bridgeOnline = false;
      lastError = error.toString();
      final updated = session.copyWith(
        rating: rating,
        trainerNotes: trainerNotes,
        memberNotes: memberNotes,
      );
      snapshot = snapshot.copyWith(sessions: _upsertSession(updated));
      _appendLog('[RTC] Local fallback feedback saved');
    }
    notifyListeners();
  }

  void _replaceRequest(CallRequest updated) {
    final requests = snapshot.requests.map((request) {
      return request.id == updated.id ? updated : request;
    }).toList();
    snapshot = snapshot.copyWith(requests: requests);
  }

  List<SessionLog> _upsertSession(SessionLog session) {
    final existing = snapshot.sessions
        .where((item) => item.id != session.id)
        .toList();
    return [...existing, session];
  }

  void _appendLog(String message) {
    final logs = [...snapshot.logs, message];
    snapshot = snapshot.copyWith(
      logs: logs.length > 20 ? logs.sublist(logs.length - 20) : logs,
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    bridge.close();
    super.dispose();
  }
}
