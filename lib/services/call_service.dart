import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class CallService extends ChangeNotifier {
  RtcEngine? _engine;
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  String? _channelName;
  final String _appId = "204bc030230e488ba433b27db2a78aac";

  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  String? get channelName => _channelName;

  Future<void> initializeAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _isInCall = true;
          notifyListeners();
        },
        onUserJoined: (connection, uid, elapsed) {
          notifyListeners();
        },
        onUserOffline: (connection, uid, reason) {
          notifyListeners();
        },
      ),
    );

    await _engine!.enableAudio();
    await _engine!.startPreview();
  }

  Future<void> startOneToOneCall(String channelName) async {
    _channelName = channelName;

    await _engine!.joinChannel(
      token:
          "007eJxTYJgjYFGl970j19GHo7owIqJVT2VNR4i/efmb3IRVrbNctRQYjAxMkpINjA2MjA1STSwskhJNjI2TjMxTkowSzS0SE5OvhAVmNQQyMsT0srAwMrAyMDIwMYD4DAwAqBcaWw==",
      channelId: channelName,
      uid: 123,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
      ),
    );
  }

  Future<void> startGroupCall(String channelName) async {
    _channelName = channelName;

    await _engine!.joinChannel(
      token:
          "007eJxTYJgjYFGl970j19GHo7owIqJVT2VNR4i/efmb3IRVrbNctRQYjAxMkpINjA2MjA1STSwskhJNjI2TjMxTkowSzS0SE5OvhAVmNQQyMsT0srAwMrAyMDIwMYD4DAwAqBcaWw==",
      channelId: channelName,
      uid: 123,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
      ),
    );
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _engine!.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine!.setEnableSpeakerphone(_isSpeakerOn);
    notifyListeners();
  }

  Future<void> endCall() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      _isInCall = false;
      _channelName = null;
      notifyListeners();
    }
  }

  String generateChannelName() {
    return 'call_${const Uuid().v4().substring(0, 8)}';
  }

  @override
  void dispose() {
    _engine?.release();
    super.dispose();
  }
}
