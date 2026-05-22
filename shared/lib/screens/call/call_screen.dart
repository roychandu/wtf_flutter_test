import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import '../../models/wtf_models.dart';
import '../../services/app_controller.dart';
import '../../services/hms_meeting_controller.dart';
import '../../utils/wtf_theme.dart';
import '../../widgets/wtf_components.dart';
import '../wtf_app.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.request,
    required this.micOn,
    required this.cameraOn,
  });

  final CallRequest request;
  final bool micOn;
  final bool cameraOn;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final meeting = HmsMeetingController();
  late final DateTime startedAt;
  bool mockMode = false;
  bool ending = false;

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  @override
  void dispose() {
    meeting.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final app = ControllerScope.of(context);
    final roomMeta = widget.request.roomMeta;
    if (roomMeta == null) {
      setState(() => mockMode = true);
      return;
    }
    final role = app.role == AppRole.member
        ? roomMeta.hmsRoleMember
        : roomMeta.hmsRoleTrainer;
    try {
      final token = await app.bridge.fetchHmsToken(
        userId: app.currentUser.id,
        role: role,
        roomId: roomMeta.hmsRoomId,
      );
      if (token.mock || token.authToken.startsWith('mock.')) {
        setState(() => mockMode = true);
        return;
      }
      await meeting.join(
        authToken: token.authToken,
        userName: app.currentUser.name,
        startMuted: !widget.micOn,
        startCameraOff: !widget.cameraOn,
      );
    } on Object {
      setState(() => mockMode = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ControllerScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: Text(mockMode ? '100ms call • Dev mode' : '100ms call'),
        actions: [
          if (meeting.reconnecting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: meeting,
          builder: (context, _) {
            final peers = meeting.peers;
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 600;
                        return GridView.count(
                          crossAxisCount: twoColumns ? 2 : 1,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 4 / 3,
                          children: [
                            _ParticipantTile(
                              name: app.currentUser.name,
                              role: app.currentUser.role,
                              videoTrack: _firstVideoTrack(
                                peers.where((peer) => peer.isLocal),
                                meeting.videoTracks,
                              ),
                              muted: meeting.micMuted,
                              cameraOff: meeting.cameraMuted || mockMode,
                            ),
                            _ParticipantTile(
                              name: app.peer.name,
                              role: app.peer.role,
                              videoTrack: _firstVideoTrack(
                                peers.where((peer) => !peer.isLocal),
                                meeting.videoTracks,
                              ),
                              muted: false,
                              cameraOff: mockMode || peers.length < 2,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (meeting.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StatusPill(
                      label: meeting.error!,
                      color: WtfColors.error,
                      icon: Icons.error_outline,
                    ),
                  )
                else if (mockMode)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: StatusPill(
                      label:
                          'Using local mock tiles until 100ms credentials are configured',
                      color: WtfColors.warning,
                      icon: Icons.info_outline,
                    ),
                  ),
                const SizedBox(height: 12),
                _CallControls(
                  micMuted: meeting.micMuted,
                  cameraMuted: meeting.cameraMuted || mockMode,
                  ending: ending,
                  onMic: mockMode
                      ? () =>
                            setState(() => meeting.micMuted = !meeting.micMuted)
                      : meeting.toggleMic,
                  onCamera: mockMode
                      ? () => setState(
                          () => meeting.cameraMuted = !meeting.cameraMuted,
                        )
                      : meeting.toggleCamera,
                  onFlip: mockMode ? () {} : meeting.switchCamera,
                  onEnd: () => _endCall(app),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _endCall(AppController app) async {
    if (ending) {
      return;
    }
    setState(() => ending = true);
    await meeting.leave();
    final endedAt = DateTime.now();
    final session = await app.completeSession(
      request: widget.request,
      startedAt: startedAt,
      endedAt: endedAt,
    );
    if (!mounted) {
      return;
    }
    await _showPostCallSheet(context, app, session);
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Session saved to your logs.')),
      );
    }
  }
}

HMSVideoTrack? _firstVideoTrack(
  Iterable<HMSPeer> peers,
  Map<String, HMSVideoTrack> tracks,
) {
  for (final peer in peers) {
    final track = tracks[peer.peerId];
    if (track != null) {
      return track;
    }
  }
  return null;
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.name,
    required this.role,
    required this.videoTrack,
    required this.muted,
    required this.cameraOff,
  });

  final String name;
  final AppRole role;
  final HMSVideoTrack? videoTrack;
  final bool muted;
  final bool cameraOff;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(role);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFF111827),
            child: videoTrack != null && !cameraOff
                ? HMSVideoView(track: videoTrack!)
                : Center(
                    child: InitialsAvatar(
                      label: name
                          .substring(0, name.length >= 2 ? 2 : 1)
                          .toUpperCase(),
                      color: color,
                      size: 72,
                    ),
                  ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (muted)
                  const Icon(Icons.mic_off, color: Colors.white, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.micMuted,
    required this.cameraMuted,
    required this.ending,
    required this.onMic,
    required this.onCamera,
    required this.onFlip,
    required this.onEnd,
  });

  final bool micMuted;
  final bool cameraMuted;
  final bool ending;
  final VoidCallback onMic;
  final VoidCallback onCamera;
  final VoidCallback onFlip;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundCallButton(
            tooltip: micMuted ? 'Unmute' : 'Mute',
            icon: micMuted ? Icons.mic_off : Icons.mic,
            onPressed: onMic,
          ),
          const SizedBox(width: 10),
          _RoundCallButton(
            tooltip: cameraMuted ? 'Video on' : 'Video off',
            icon: cameraMuted ? Icons.videocam_off : Icons.videocam,
            onPressed: onCamera,
          ),
          const SizedBox(width: 10),
          _RoundCallButton(
            tooltip: 'Flip camera',
            icon: Icons.cameraswitch,
            onPressed: onFlip,
          ),
          const SizedBox(width: 10),
          _RoundCallButton(
            tooltip: 'End call',
            icon: ending ? Icons.hourglass_empty : Icons.call_end,
            color: WtfColors.error,
            onPressed: ending ? null : onEnd,
          ),
        ],
      ),
    );
  }
}

class _RoundCallButton extends StatelessWidget {
  const _RoundCallButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: IconButton.filled(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: color ?? Colors.white.withValues(alpha: 0.12),
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

Future<void> showPreJoinSheet(BuildContext context, CallRequest request) async {
  var micOn = true;
  var cameraOn = true;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to join? Check mic and camera.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: WtfColors.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    cameraOn
                        ? Icons.videocam_outlined
                        : Icons.videocam_off_outlined,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: micOn,
                onChanged: (value) => setModalState(() => micOn = value),
                title: const Text('Microphone'),
                secondary: const Icon(Icons.mic_outlined),
              ),
              SwitchListTile(
                value: cameraOn,
                onChanged: (value) => setModalState(() => cameraOn = value),
                title: const Text('Camera'),
                secondary: const Icon(Icons.videocam_outlined),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CallScreen(
                        request: request,
                        micOn: micOn,
                        cameraOn: cameraOn,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.video_call),
                label: const Text('Join room'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _showPostCallSheet(
  BuildContext context,
  AppController app,
  SessionLog session,
) async {
  final noteController = TextEditingController();
  var rating = 5;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        final member = app.role == AppRole.member;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member ? 'Rate session' : 'Complete session',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              if (member)
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        tooltip: '$i star',
                        onPressed: () => setModalState(() => rating = i),
                        icon: Icon(
                          i <= rating ? Icons.star : Icons.star_border,
                          color: WtfColors.warning,
                        ),
                      ),
                  ],
                ),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: member ? 'Optional note' : 'Trainer notes',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await app.updateSession(
                    session: session,
                    rating: member ? rating : session.rating,
                    memberNotes: member
                        ? noteController.text.trim()
                        : session.memberNotes,
                    trainerNotes: member
                        ? session.trainerNotes
                        : noteController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(member ? 'Save rating' : 'Mark as complete'),
              ),
            ],
          ),
        );
      },
    ),
  );
  noteController.dispose();
}
