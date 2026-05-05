import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../services/call_services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const _kBlue900  = Color(0xFF1E3A8A);
const _kBlue800  = Color(0xFF1E40AF);
const _kBlue600  = Color(0xFF2563EB);
const _kBlue400  = Color(0xFF60A5FA);
const _kBlue100  = Color(0xFFDBEAFE);
const _kDark     = Color(0xFF060D1A);
const _kDark2    = Color(0xFF0B1629);
const _kDark3    = Color(0xFF111D33);
const _kSurface  = Color(0xFF152040);
const _kWhite    = Colors.white;
const _kGreen    = Color(0xFF22C55E);
const _kRed      = Color(0xFFEF4444);

// ─────────────────────────────────────────────────────────────────────────────
// CallPage
// ─────────────────────────────────────────────────────────────────────────────
class CallPage extends StatefulWidget {
  final CallInvite invite;
  const CallPage({super.key, required this.invite});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>
    with TickerProviderStateMixin {

  // ── Renderers ──────────────────────────────────────────────────────────────
  final RTCVideoRenderer _local  = RTCVideoRenderer();
  final RTCVideoRenderer _remote = RTCVideoRenderer();
  bool _renderersInitialized = false;

  // ── WebRTC ─────────────────────────────────────────────────────────────────
  RTCPeerConnection? _pc;
  MediaStream?       _localStream;
  MediaStream?       _remoteStream;

  // ── Call state ─────────────────────────────────────────────────────────────
  bool   _accepted           = false;
  bool   _starting           = false;
  bool   _remoteOfferApplied = false;
  bool   _cleanedUp          = false;
  bool   _popping            = false;
  bool   _micMuted           = false;
  bool   _camOff             = false;
  bool   _speakerOn          = true;
  String _status             = 'Incoming call…';
  String? _peerSocketId;
  final List<RTCIceCandidate> _pendingIce = [];

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late AnimationController _ringCtrl;
  late Animation<double>   _ringAnim;

  // ── Timer ──────────────────────────────────────────────────────────────────
  Timer?    _callTimer;
  int       _callSeconds = 0;

  dynamic get _socket => CallService.I.socket;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _peerSocketId = widget.invite.fromSocketId;

    // Pulse for incoming ring avatar
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Fade-in for call screen
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Ripple ring for incoming screen
    _ringCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);

    // Force portrait during call
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _ringCtrl.dispose();
    _callTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    unawaited(_cleanup());
    super.dispose();
  }

  // ── Call timer ─────────────────────────────────────────────────────────────
  void _startTimer() {
    _callTimer?.cancel();
    _callSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  String get _timerLabel {
    final m = _callSeconds ~/ 60;
    final s = _callSeconds  % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _safePop() {
    if (_popping) return;
    final nav = Navigator.of(context, rootNavigator: false);
    if (nav.canPop()) {
      _popping = true;
      nav.pop();
    }
  }

  // ── Parsers ────────────────────────────────────────────────────────────────
  int? _readEmergencyId(dynamic data) {
    if (data is! Map) return null;
    final v = data['emergencyId'];
    if (v == null) return null;
    return int.tryParse(v.toString());
  }

  RTCSessionDescription? _parseSdp(dynamic raw) {
    if (raw is! Map) return null;
    final m   = Map<String, dynamic>.from(raw as Map);
    final sdp = m['sdp']?.toString();
    final typ = m['type']?.toString();
    if (sdp == null || typ == null) return null;
    return RTCSessionDescription(sdp, typ);
  }

  RTCIceCandidate? _parseIce(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw as Map);
    final c = m['candidate']?.toString();
    if (c == null || c.isEmpty) return null;
    final mid = m['sdpMid']?.toString();
    final idx = m['sdpMLineIndex'];
    int? mline;
    if (idx is int)  mline = idx;
    if (idx is num)  mline = idx.toInt();
    return RTCIceCandidate(c, mid, mline);
  }

  void _addTrackSafe(MediaStreamTrack track, MediaStream stream) {
    try {
      final existing = stream.getTracks();
      if (!existing.any((e) => e.id == track.id)) {
        stream.addTrack(track);
      }
    } catch (_) {}
  }

  // ── Socket listeners ───────────────────────────────────────────────────────
  void _attachListeners() {
    final s = _socket;
    if (s == null) return;
    s.on('call:offer',     _onCallOffer);
    s.on('call:ice',       _onCallIce);
    s.on('call:hangup',    _onHangupOrPeerLeft);
    s.on('call:peer-left', _onHangupOrPeerLeft);
  }

  void _detachListeners() {
    final s = _socket;
    if (s == null) return;
    s.off('call:offer',     _onCallOffer);
    s.off('call:ice',       _onCallIce);
    s.off('call:hangup',    _onHangupOrPeerLeft);
    s.off('call:peer-left', _onHangupOrPeerLeft);
  }

  void _onHangupOrPeerLeft(dynamic _) => unawaited(_endAndPop());

  // ── call:offer ─────────────────────────────────────────────────────────────
  Future<void> _onCallOffer(dynamic data) async {
    if (!_accepted || _pc == null || _remoteOfferApplied) return;
    if (data is! Map) return;
    if (_readEmergencyId(data) != widget.invite.emergencyId) return;

    final map  = Map<String, dynamic>.from(data as Map);
    final from = map['fromSocketId']?.toString();
    if (from != null && from.isNotEmpty) _peerSocketId = from;

    final rawSdp = map.containsKey('sdp') ? map['sdp'] : map;
    final offer  = _parseSdp(rawSdp);
    if (offer == null) {
      if (mounted) setState(() => _status = 'Invalid offer SDP');
      return;
    }

    try {
      if (mounted) setState(() => _status = 'Answering…');
      await _pc!.setRemoteDescription(offer);
      _remoteOfferApplied = true;

      for (final c in List<RTCIceCandidate>.from(_pendingIce)) {
        try { await _pc!.addCandidate(c); } catch (_) {}
      }
      _pendingIce.clear();

      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);

      final to = _peerSocketId;
      if (to == null || to.isEmpty) {
        if (mounted) setState(() => _status = 'No peer socket ID');
        return;
      }

      CallService.I.sendAnswer(
        emergencyId: widget.invite.emergencyId,
        toSocketId:  to,
        sdp:         answer.toMap(),
      );

      if (mounted) {
        setState(() => _status = 'In call');
        _startTimer();
        _fadeCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: $e');
    }
  }

  // ── call:ice ───────────────────────────────────────────────────────────────
  Future<void> _onCallIce(dynamic data) async {
    if (data is! Map) return;
    if (_readEmergencyId(data) != widget.invite.emergencyId) return;

    final map     = Map<String, dynamic>.from(data as Map);
    final rawCand = map.containsKey('candidate') ? map['candidate'] : map;
    final cand    = _parseIce(rawCand);
    if (cand == null) return;

    final pc = _pc;
    if (pc == null) return;

    if (!_remoteOfferApplied) {
      _pendingIce.add(cand);
      return;
    }
    try { await pc.addCandidate(cand); } catch (_) {}
  }

  // ── Accept ─────────────────────────────────────────────────────────────────
  Future<void> _accept() async {
    if (!mounted) return;
    setState(() {
      _accepted = true;
      _starting = true;
      _status   = 'Initialising…';
    });

    try {
      await _local.initialize();
      await _remote.initialize();
      _renderersInitialized = true;

      _remoteStream     = await createLocalMediaStream('remote');
      _remote.srcObject = _remoteStream;

      _attachListeners();

      _pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
        // Improves connectivity on mobile NAT
        'iceTransportPolicy': 'all',
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
      });

      // onTrack — handles both web (streams populated) and native (streams empty)
      _pc!.onTrack = (RTCTrackEvent event) {
        final rs = _remoteStream;
        if (rs == null) return;
        bool added = false;
        for (final s in event.streams) {
          for (final t in s.getTracks()) {
            _addTrackSafe(t, rs);
            added = true;
          }
        }
        if (!added) _addTrackSafe(event.track, rs);
        if (mounted) setState(() => _remote.srcObject = rs);
      };

      // onIceCandidate
      _pc!.onIceCandidate = (RTCIceCandidate? c) {
        if (c == null || (c.candidate ?? '').isEmpty) return;
        final to = _peerSocketId;
        if (to == null || to.isEmpty) return;
        CallService.I.sendIce(
          emergencyId: widget.invite.emergencyId,
          toSocketId:  to,
          candidate:   c.toMap(),
        );
      };

      // onConnectionState — fires on all platforms
      _pc!.onConnectionState = (RTCPeerConnectionState state) {
        if (!mounted) return;
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            setState(() => _status = 'In call');
            _startTimer();
            _fadeCtrl.forward();
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            setState(() => _status = 'Connection failed');
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            setState(() => _status = 'Reconnecting…');
            break;
          default:
            break;
        }
      };

      // onIceConnectionState — fallback for browsers/devices that only fire this
      _pc!.onIceConnectionState = (RTCIceConnectionState state) {
        if (!mounted) return;
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          if (_status != 'In call') {
            setState(() => _status = 'In call');
            _startTimer();
            _fadeCtrl.forward();
          }
        }
      };

      if (mounted) setState(() => _status = 'Opening camera…');
      await _openLocalMedia();

      if (!mounted) return;
      _local.srcObject = _localStream;
      if (mounted) setState(() {});

      for (final track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }

      CallService.I.joinCallRoom(widget.invite.emergencyId);

      if (mounted) {
        setState(() {
          _starting = false;
          _status   = 'Waiting for offer…';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _starting = false;
          _status   = 'Setup failed: $e';
        });
      }
    }
  }

  // ── getUserMedia with fallback chain ───────────────────────────────────────
  Future<void> _openLocalMedia() async {
    await _forceReleaseLocalTracks();
    kIsWeb ? await _openLocalMediaWeb() : await _openLocalMediaNative();
    for (final t in _localStream?.getTracks() ?? []) {
      t.enabled = true;
    }
  }

  Future<void> _forceReleaseLocalTracks() async {
    if (_localStream == null) return;
    try {
      for (final t in _localStream!.getTracks()) {
        try { t.stop(); } catch (_) {}
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
    } catch (_) {}
    _localStream = null;
  }

  bool _isDeviceBusy(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('notreadable') ||
           msg.contains('could not start') ||
           msg.contains('device in use') ||
           msg.contains('failed to allocate') ||
           msg.contains('hardware error') ||
           msg.contains('not readable');
  }

  Future<void> _openLocalMediaWeb() async {
    for (final constraints in [
      {'audio': true, 'video': {'width': {'ideal': 640}, 'height': {'ideal': 480}, 'frameRate': {'ideal': 30}}},
      {'audio': true, 'video': true},
      {'audio': true, 'video': false},
    ]) {
      try {
        _localStream = await navigator.mediaDevices.getUserMedia(constraints);
        return;
      } catch (e) {
        if (!_isDeviceBusy(e) && constraints['video'] != false) rethrow;
        if (constraints['video'] == false) rethrow;
      }
    }
  }

  Future<void> _openLocalMediaNative() async {
    final granted = await Helper.requestCapturePermission();
    if (!granted) throw Exception('Camera/microphone permission denied');

    for (final constraints in [
      {
        'audio': true,
        'video': {'facingMode': 'user', 'width': {'ideal': 640}, 'height': {'ideal': 480}},
      },
      {
        'audio': true,
        'video': {'width': {'ideal': 320}, 'height': {'ideal': 240}},
      },
      {'audio': true, 'video': false},
    ]) {
      try {
        _localStream = await navigator.mediaDevices.getUserMedia(constraints);
        try { await Helper.setSpeakerphoneOn(_speakerOn); } catch (_) {}
        return;
      } catch (e) {
        if (!_isDeviceBusy(e) && constraints['video'] != false) rethrow;
        if (constraints['video'] == false) rethrow;
        if (mounted) setState(() => _status = 'Retrying camera…');
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
    }
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  void _toggleMic() {
    setState(() => _micMuted = !_micMuted);
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_micMuted);
  }

  void _toggleCam() {
    setState(() => _camOff = !_camOff);
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !_camOff);
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    try { Helper.setSpeakerphoneOn(_speakerOn); } catch (_) {}
  }

  void _flipCamera() {
    try { Helper.switchCamera(_localStream!.getVideoTracks().first); } catch (_) {}
  }

  // ── Reject / Hangup ────────────────────────────────────────────────────────
  void _reject() {
    CallService.I.hangup(
      emergencyId: widget.invite.emergencyId,
      toSocketId:  widget.invite.fromSocketId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _safePop());
  }

  void _hangup() {
    CallService.I.hangup(
      emergencyId: widget.invite.emergencyId,
      toSocketId:  _peerSocketId,
    );
    unawaited(_endAndPop());
  }

  Future<void> _endAndPop() async {
    await _cleanup();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _safePop());
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────
  Future<void> _cleanup() async {
    if (_cleanedUp) return;
    _cleanedUp = true;
    _callTimer?.cancel();
    _pendingIce.clear();
    _detachListeners();
    try { await _pc?.close(); } catch (_) {}
    _pc = null;
    try {
      for (final t in _localStream?.getTracks() ?? []) {
        try { t.stop(); } catch (_) {}
      }
    } catch (_) {}
    _localStream  = null;
    _remoteStream = null;
    try {
      _local.srcObject  = null;
      _remote.srcObject = null;
    } catch (_) {}
    if (_renderersInitialized) {
      try { await _local.dispose();  } catch (_) {}
      try { await _remote.dispose(); } catch (_) {}
      _renderersInitialized = false;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Edge-to-edge immersive UI
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:            Colors.transparent,
        statusBarIconBrightness:   Brightness.light,
        systemNavigationBarColor:  _kDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: _accepted ? _buildCallUI() : _buildIncomingUI(),
    );
  }

  // ── INCOMING SCREEN ────────────────────────────────────────────────────────
  Widget _buildIncomingUI() {
    return Scaffold(
      backgroundColor: _kDark,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle radial blue glow at top
            Positioned(
              top: -80, left: 0, right: 0,
              child: Container(
                height: 360,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.9,
                    colors: [Color(0x401E40AF), Colors.transparent],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 48),

                // Top label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kBlue800.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kBlue600.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulseDot(color: _kGreen, size: 7),
                      SizedBox(width: 7),
                      Text(
                        'BahirLink · Emergency Call',
                        style: TextStyle(
                          color: _kBlue100,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Ripple + Avatar
                SizedBox(
                  width: 200, height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ripple ring
                      AnimatedBuilder(
                        animation: _ringAnim,
                        builder: (_, __) => Opacity(
                          opacity: (1 - _ringAnim.value).clamp(0, 1),
                          child: Container(
                            width:  180 + 40 * _ringAnim.value,
                            height: 180 + 40 * _ringAnim.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _kBlue600.withOpacity(.35),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Mid ring
                      AnimatedBuilder(
                        animation: _ringAnim,
                        builder: (_, __) {
                          final t = (_ringAnim.value + 0.3) % 1.0;
                          return Opacity(
                            opacity: (1 - t).clamp(0, 1),
                            child: Container(
                              width:  160 + 40 * t,
                              height: 160 + 40 * t,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _kBlue600.withOpacity(.25),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Inner glow circle
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kBlue800.withOpacity(.3),
                          border: Border.all(color: _kBlue600.withOpacity(.6), width: 1.5),
                        ),
                      ),
                      // Pulse avatar
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end:   Alignment.bottomRight,
                              colors: [_kBlue600, _kBlue900],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kBlue600.withOpacity(.45),
                                blurRadius: 24, spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.videocam_rounded,
                            color: _kWhite, size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Incoming Video Call',
                  style: TextStyle(
                    color: _kWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Case #${widget.invite.emergencyId}',
                    style: const TextStyle(
                      color: _kBlue400, fontSize: 13,
                      fontWeight: FontWeight.w600, letterSpacing: .3,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Text(
                  'Responder Dashboard',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),

                const Spacer(),

                // Accept / Decline row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundCallButton(
                        icon:    Icons.call_end_rounded,
                        label:   'Decline',
                        bg:      _kRed.withOpacity(.15),
                        border:  _kRed.withOpacity(.5),
                        iconBg:  _kRed,
                        onTap:   _reject,
                      ),
                      _RoundCallButton(
                        icon:    Icons.videocam_rounded,
                        label:   'Accept',
                        bg:      _kGreen.withOpacity(.12),
                        border:  _kGreen.withOpacity(.5),
                        iconBg:  _kGreen,
                        onTap:   _accept,
                        large:   true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── CALL SCREEN ────────────────────────────────────────────────────────────
  Widget _buildCallUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _starting ? _buildSetupLoader() : _buildVideoCall(),
    );
  }

  Widget _buildSetupLoader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [_kDark, _kDark2],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kBlue800.withOpacity(.2),
                border: Border.all(color: _kBlue600.withOpacity(.4), width: 1.5),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: _kBlue400,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _status,
              style: const TextStyle(
                color: _kWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Case #${widget.invite.emergencyId}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCall() {
    final hasLocalVideo =
        _localStream != null && _localStream!.getVideoTracks().isNotEmpty && !_camOff;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Remote video (full screen) ──────────────────────────────────────
        RTCVideoView(
          _remote,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),

        // Dark overlay when remote is not yet streaming
        if (_status != 'In call')
          Container(
            color: _kDark.withOpacity(.75),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56, height: 56,
                    child: CircularProgressIndicator(
                      color: _kBlue400,
                      strokeWidth: 2.5,
                      backgroundColor: _kBlue800.withOpacity(.2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _status,
                    style: const TextStyle(
                      color: _kWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Top bar (status + timer) ────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Logo badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kBlue800.withOpacity(.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBlue600.withOpacity(.5)),
                      ),
                      child: const Text(
                        'BahirLink',
                        style: TextStyle(
                          color: _kWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Case #${widget.invite.emergencyId}',
                      style: const TextStyle(
                        color: Color(0xAAFFFFFF),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulseDot(
                            color: _status == 'In call' ? _kGreen : Colors.orange,
                            size: 6,
                            animate: _status != 'In call',
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _status == 'In call' ? _timerLabel : _status,
                            style: const TextStyle(
                              color: _kWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Local PiP ──────────────────────────────────────────────────────
        Positioned(
          right: 16, top: 100, width: 104, height: 148,
          child: AnimatedOpacity(
            opacity: hasLocalVideo ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: _kDark3,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBlue600.withOpacity(.5), width: 1.5),
                ),
                child: hasLocalVideo
                    ? RTCVideoView(_local, mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                    : const Center(
                        child: Icon(Icons.videocam_off_rounded,
                            color: Color(0x80FFFFFF), size: 24),
                      ),
              ),
            ),
          ),
        ),

        // ── Cam-off badge ──────────────────────────────────────────────────
        if (!hasLocalVideo && !_starting)
          Positioned(
            right: 16, top: 100, width: 104, height: 148,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: _kDark3,
                  border: Border.all(color: _kBlue600.withOpacity(.3), width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off_rounded,
                        color: Color(0x60FFFFFF), size: 26),
                    SizedBox(height: 6),
                    Text('Camera off',
                        style: TextStyle(color: Color(0x60FFFFFF), fontSize: 10),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),

        // ── Bottom control bar ──────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end:   Alignment.topCenter,
                colors: [Color(0xEE000000), Colors.transparent],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon:    _micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label:   _micMuted ? 'Unmute' : 'Mute',
                      active:  _micMuted,
                      onTap:   _toggleMic,
                    ),
                    _ControlButton(
                      icon:    _camOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                      label:   _camOff ? 'Cam on' : 'Cam off',
                      active:  _camOff,
                      onTap:   _toggleCam,
                    ),
                    // Hang up (prominent red)
                    GestureDetector(
                      onTap: _hangup,
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: _kRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _kRed.withOpacity(.5),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: _kWhite, size: 28,
                        ),
                      ),
                    ),
                    if (!kIsWeb)
                      _ControlButton(
                        icon:  Icons.flip_camera_ios_rounded,
                        label: 'Flip',
                        onTap: _flipCamera,
                      )
                    else
                      _ControlButton(
                        icon:    _speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        label:   _speakerOn ? 'Speaker' : 'Earpiece',
                        active:  !_speakerOn,
                        onTap:   _toggleSpeaker,
                      ),
                    _ControlButton(
                      icon:  Icons.info_outline_rounded,
                      label: 'Info',
                      onTap: () => _showCallInfo(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCallInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kDark2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Call info',
              style: TextStyle(
                color: _kWhite, fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow('Case', '#${widget.invite.emergencyId}'),
            _InfoRow('Status', _status),
            _InfoRow('Duration', _timerLabel),
            _InfoRow('Peer socket', _peerSocketId ?? '—'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Animated pulsing status dot
class _PulseDot extends StatefulWidget {
  final Color  color;
  final double size;
  final bool   animate;
  const _PulseDot({required this.color, required this.size, this.animate = true});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.5 + _c.value * 0.5,
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Large rounded button for incoming screen (Accept/Decline)
class _RoundCallButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        bg;
  final Color        border;
  final Color        iconBg;
  final VoidCallback onTap;
  final bool         large;
  const _RoundCallButton({
    required this.icon,
    required this.label,
    required this.bg,
    required this.border,
    required this.iconBg,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 60.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  bg,
              border: Border.all(color: border, width: 1.5),
              boxShadow: large
                  ? [BoxShadow(color: iconBg.withOpacity(.35), blurRadius: 18, spreadRadius: 1)]
                  : null,
            ),
            child: Icon(icon, color: iconBg, size: large ? 30 : 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: large ? _kWhite : const Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: large ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// In-call control pill button (mute, cam, flip, etc.)
class _ControlButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         active;
  final VoidCallback onTap;
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? _kBlue800.withOpacity(.8)
                  : Colors.white.withOpacity(.12),
              border: Border.all(
                color: active
                    ? _kBlue400.withOpacity(.7)
                    : Colors.white.withOpacity(.18),
                width: 1.2,
              ),
            ),
            child: Icon(
              icon,
              color: active ? _kBlue100 : _kWhite,
              size: 22,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xBBFFFFFF),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info row for the bottom sheet
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
          Text(value,
              style: const TextStyle(
                color: _kWhite, fontSize: 13, fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
