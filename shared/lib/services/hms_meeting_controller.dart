import 'package:flutter/foundation.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

class HmsMeetingController extends ChangeNotifier
    implements HMSUpdateListener, HMSActionResultListener {
  HMSSDK? _hmsSDK;

  bool joining = false;
  bool joined = false;
  bool reconnecting = false;
  bool micMuted = false;
  bool cameraMuted = false;
  String? error;
  List<HMSPeer> peers = const [];
  Map<String, HMSVideoTrack> videoTracks = const {};

  Future<void> join({
    required String authToken,
    required String userName,
    bool startMuted = false,
    bool startCameraOff = false,
  }) async {
    if (joining || joined) {
      return;
    }

    joining = true;
    error = null;
    micMuted = startMuted;
    cameraMuted = startCameraOff;
    notifyListeners();

    try {
      final trackSetting = HMSTrackSetting(
        audioTrackSetting: HMSAudioTrackSetting(
          trackInitialState: startMuted
              ? HMSTrackInitState.MUTED
              : HMSTrackInitState.UNMUTED,
        ),
        videoTrackSetting: HMSVideoTrackSetting(
          trackInitialState: startCameraOff
              ? HMSTrackInitState.MUTED
              : HMSTrackInitState.UNMUTED,
        ),
      );
      final hmsSDK = HMSSDK(hmsTrackSetting: trackSetting);
      _hmsSDK = hmsSDK;
      await hmsSDK.build();
      hmsSDK.addUpdateListener(listener: this);
      await hmsSDK.join(
        config: HMSConfig(authToken: authToken, userName: userName),
      );
    } on Object catch (exception) {
      error = exception.toString();
      joining = false;
      notifyListeners();
    }
  }

  Future<void> toggleMic() async {
    micMuted = !micMuted;
    notifyListeners();
    await _hmsSDK?.toggleMicMuteState();
  }

  Future<void> toggleCamera() async {
    cameraMuted = !cameraMuted;
    notifyListeners();
    await _hmsSDK?.toggleCameraMuteState();
  }

  Future<void> switchCamera() async {
    await _hmsSDK?.switchCamera(hmsActionResultListener: this);
  }

  Future<void> leave() async {
    try {
      await _hmsSDK?.leave(hmsActionResultListener: this);
    } finally {
      _hmsSDK?.destroy();
      _hmsSDK = null;
      joining = false;
      joined = false;
      reconnecting = false;
      peers = const [];
      videoTracks = const {};
      notifyListeners();
    }
  }

  Future<void> _refreshPeers() async {
    final sdkPeers = await _hmsSDK?.getPeers();
    peers = sdkPeers ?? const [];
    notifyListeners();
  }

  @override
  void onJoin({required HMSRoom room}) {
    joining = false;
    joined = true;
    reconnecting = false;
    _refreshPeers();
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    if (update == HMSPeerUpdate.peerLeft) {
      final tracks = Map<String, HMSVideoTrack>.from(videoTracks)
        ..remove(peer.peerId);
      videoTracks = tracks;
    }
    _refreshPeers();
  }

  @override
  void onTrackUpdate({
    required HMSTrack track,
    required HMSTrackUpdate trackUpdate,
    required HMSPeer peer,
  }) {
    if (track.kind != HMSTrackKind.kHMSTrackKindVideo ||
        track is! HMSVideoTrack) {
      return;
    }
    final tracks = Map<String, HMSVideoTrack>.from(videoTracks);
    if (trackUpdate == HMSTrackUpdate.trackRemoved) {
      tracks.remove(peer.peerId);
    } else {
      tracks[peer.peerId] = track;
    }
    videoTracks = tracks;
    notifyListeners();
  }

  @override
  void onReconnecting() {
    reconnecting = true;
    notifyListeners();
  }

  @override
  void onReconnected() {
    reconnecting = false;
    notifyListeners();
  }

  @override
  void onHMSError({required HMSException error}) {
    this.error = error.message;
    joining = false;
    notifyListeners();
  }

  @override
  void onSuccess({
    HMSActionResultListenerMethod methodType =
        HMSActionResultListenerMethod.unknown,
    Map<String, dynamic>? arguments,
  }) {}

  @override
  void onException({
    HMSActionResultListenerMethod methodType =
        HMSActionResultListenerMethod.unknown,
    Map<String, dynamic>? arguments,
    required HMSException hmsException,
  }) {
    error = hmsException.message;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void dispose() {
    _hmsSDK?.destroy();
    super.dispose();
  }
}
