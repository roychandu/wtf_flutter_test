import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/wtf_models.dart';

class DevBridgeException implements Exception {
  const DevBridgeException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HmsTokenResponse {
  const HmsTokenResponse({
    required this.authToken,
    required this.roomId,
    required this.role,
    required this.mock,
  });

  final String authToken;
  final String roomId;
  final String role;
  final bool mock;

  factory HmsTokenResponse.fromJson(Map<String, dynamic> json) =>
      HmsTokenResponse(
        authToken: json['authToken'] as String? ?? '',
        roomId: json['roomId'] as String? ?? '',
        role: json['role'] as String? ?? '',
        mock: json['mock'] as bool? ?? false,
      );
}

class DevBridgeClient {
  DevBridgeClient({String? baseUrl, this.timeout = const Duration(seconds: 3)})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'WTF_BRIDGE_URL',
            defaultValue: 'http://10.0.2.2:8787',
          );

  final String baseUrl;
  final Duration timeout;
  final HttpClient _client = HttpClient();

  Future<AppSnapshot> fetchState() async {
    final json = await _request('GET', '/state');
    return AppSnapshot.fromJson(json);
  }

  Future<AppSnapshot> reset() async {
    final json = await _request('POST', '/reset');
    return AppSnapshot.fromJson(json);
  }

  Future<Message> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final json = await _request(
      'POST',
      '/messages',
      body: {'senderId': senderId, 'receiverId': receiverId, 'text': text},
    );
    return Message.fromJson(json);
  }

  Future<void> markRead({
    required String userId,
    required String chatId,
  }) async {
    await _request(
      'POST',
      '/messages/read',
      body: {'userId': userId, 'chatId': chatId},
    );
  }

  Future<CallRequest> createCallRequest({
    required DateTime scheduledFor,
    required String note,
  }) async {
    final json = await _request(
      'POST',
      '/requests',
      body: {
        'memberId': SeedData.memberId,
        'trainerId': SeedData.trainerId,
        'scheduledFor': encodeDate(scheduledFor),
        'note': note,
      },
    );
    return CallRequest.fromJson(json);
  }

  Future<CallRequest> reviewCallRequest({
    required String requestId,
    required bool approved,
    String? reason,
  }) async {
    final json = await _request(
      'POST',
      '/requests/review',
      body: {'requestId': requestId, 'approved': approved, 'reason': reason},
    );
    return CallRequest.fromJson(json);
  }

  Future<CallRequest> simulateNow(String requestId) async {
    final json = await _request(
      'POST',
      '/requests/simulate-now',
      body: {'requestId': requestId},
    );
    return CallRequest.fromJson(json);
  }

  Future<SessionLog> completeSession({
    required String requestId,
    required DateTime startedAt,
    required DateTime endedAt,
    String? trainerNotes,
    String? memberNotes,
  }) async {
    final json = await _request(
      'POST',
      '/sessions',
      body: {
        'requestId': requestId,
        'startedAt': encodeDate(startedAt),
        'endedAt': encodeDate(endedAt),
        'trainerNotes': trainerNotes,
        'memberNotes': memberNotes,
      },
    );
    return SessionLog.fromJson(json);
  }

  Future<SessionLog> updateSession({
    required String sessionId,
    int? rating,
    String? trainerNotes,
    String? memberNotes,
  }) async {
    final json = await _request(
      'POST',
      '/sessions/update',
      body: {
        'sessionId': sessionId,
        'rating': rating,
        'trainerNotes': trainerNotes,
        'memberNotes': memberNotes,
      },
    );
    return SessionLog.fromJson(json);
  }

  Future<HmsTokenResponse> fetchHmsToken({
    required String userId,
    required String role,
    required String roomId,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: '/token',
      queryParameters: {'userId': userId, 'role': role, 'roomId': roomId},
    );
    final json = await _requestUri('GET', uri);
    return HmsTokenResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _requestUri(method, uri, body: body);
  }

  Future<Map<String, dynamic>> _requestUri(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = await _client.openUrl(method, uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(timeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(timeout);
      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(responseBody) as Map);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DevBridgeException(
          decoded['error'] as String? ??
              'Bridge request failed (${response.statusCode}).',
        );
      }
      return decoded;
    } on DevBridgeException {
      rethrow;
    } on Object catch (error) {
      throw DevBridgeException('Local bridge unavailable at $baseUrl: $error');
    }
  }

  void close() {
    _client.close(force: true);
  }
}
