import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../services/call_services.dart';

class CallPage extends StatefulWidget {
  final CallInvite invite;
  const CallPage({super.key, required this.invite});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final RTCVideoRenderer _local  = RTCVideoRenderer();
  final RTCVideoRenderer _remote = RTCVideoRenderer();
  bool _renderersInitialized = false;

  RTCPeerConnection? _pc;
  MediaStream?       _localStream;
  MediaStream?       _remoteStream;

  bool   _accepted           = false;
  bool   _starting           = false;
  bool   _remoteOfferApplied = false;
  bool   _cleanedUp          = false;
  bool   _popping            = false;
  String _status             = 'Incoming call…';
  String? _peerSocketId;

  // Queue ICE candidates that arrive before remote description is set
  final List<RTCIceCandidate> _pendingIce = [];

  dynamic get _socket => CallService.I.socket;

  // ── Helpers ────────────────────────────────────────────────────────────────
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
    if (idx is int) mline = idx;
    if (idx is num) mline = idx.toInt();
    return RTCIceCandidate(c, mid, mline);
  }

  /// Safely add [track] to [stream], skipping if already present.
  void _addTrackSafe(MediaStreamTrack track, MediaStream stream) {
    try {
      final existing = stream.getTracks();
      if (!existing.any((e) => e.id == track.id)) {
        stream.addTrack(track);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _peerSocketId = widget.invite.fromSocketId;
  }

  @override
  void dispose() {
    unawaited(_cleanup());
    super.dispose();
  }

  void _safePop() {
    if (_popping) return;
    final nav = Navigator.of(context, rootNavigator: false);
    if (nav.canPop()) {
      _popping = true;
      nav.pop();
    }
  }

  // ── Listeners ──────────────────────────────────────────────────────────────
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

  Future<void> _onCallOffer(dynamic data) async {
    if (!_accepted || _pc == null || _remoteOfferApplied) return;
    if (data is! Map) return;
    if (_readEmergencyId(data) != widget.invite.emergencyId) return;

    final map  = Map<String, dynamic>.from(data as Map);
    final from = map['fromSocketId']?.toString();
    if (from != null && from.isNotEmpty) _peerSocketId = from;

    final offer = _parseSdp(map['sdp']);
    if (offer == null) {
      if (mounted) setState(() => _status = 'Failed: invalid offer');
      return;
    }

    try {
      if (mounted) setState(() => _status = 'Answering…');
      await _pc!.setRemoteDescription(offer);
      _remoteOfferApplied = true;

      // Drain any ICE candidates that arrived before the offer
      for (final c in _pendingIce) {
        try { await _pc!.addCandidate(c); } catch (_) {}
      }
      _pendingIce.clear();

      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);

      final to = _peerSocketId;
      if (to == null || to.isEmpty) {
        if (mounted) setState(() => _status = 'Failed: no peer socket');
        return;
      }

      CallService.I.sendAnswer(
        emergencyId: widget.invite.emergencyId,
        toSocketId:  to,
        sdp:         answer.toMap(),
      );

      if (mounted) setState(() => _status = 'In call');
    } catch (e) {
      if (mounted) setState(() => _status = 'Failed: $e');
    }
  }

  Future<void> _onCallIce(dynamic data) async {
    if (data is! Map) return;
    if (_readEmergencyId(data) != widget.invite.emergencyId) return;

    final map  = Map<String, dynamic>.from(data as Map);
    final cand = _parseIce(map['candidate']);
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
      // 1) Init renderers
      await _local.initialize();
      await _remote.initialize();
      _renderersInitialized = true;

      // 2) Remote stream container
      _remoteStream     = await createLocalMediaStream('remote');
      _remote.srcObject = _remoteStream;

      // 3) Attach listeners before joining so we never miss the offer
      _attachListeners();

      // 4) Create PC before joining so it's ready when offer arrives
      _pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      });

      // ── FIX GAP 7 ────────────────────────────────────────────────────────
      // flutter_webrtc on Android/iOS often delivers event.streams as an
      // EMPTY LIST even when tracks are present — only event.track is reliable.
      // Strategy: try streams first (web path), then fall back to event.track.
      _pc!.onTrack = (RTCTrackEvent event) {
        final rs = _remoteStream;
        if (rs == null) return;

        bool trackAdded = false;

        // Path A: streams populated (web, some desktop builds)
        for (final s in event.streams) {
          for (final t in s.getTracks()) {
            _addTrackSafe(t, rs);
            trackAdded = true;
          }
        }

        // Path B: streams empty (Android, iOS native — the common case)
        // event.track is always populated per the WebRTC spec.
        if (!trackAdded) {
          _addTrackSafe(event.track, rs);
        }

        // Re-assign srcObject so the RTCVideoRenderer re-renders
        if (mounted) setState(() => _remote.srcObject = rs);
      };
      // ─────────────────────────────────────────────────────────────────────

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

      // 5) Open local media with NotReadableError recovery
      if (mounted) setState(() => _status = 'Opening camera…');
      await _openLocalMedia();

      if (!mounted) return;
      _local.srcObject = _localStream;
      setState(() {});

      // 6) Add tracks to PC
      for (final track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }

      // 7) Join room last — triggers call:peer-joined on React which sends offer
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
          _status   = 'Failed: $e';
        });
      }
    }
  }

  // ── getUserMedia with NotReadableError recovery ────────────────────────────
  Future<void> _openLocalMedia() async {
    await _forceReleaseLocalTracks();

    if (kIsWeb) {
      await _openLocalMediaWeb();
    } else {
      await _openLocalMediaNative();
    }

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
      await Future<void>.delayed(const Duration(milliseconds: 400));
    } catch (_) {}
    _localStream = null;
  }

  bool _isDeviceBusy(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('notreadable')        ||
           msg.contains('could not start')    ||
           msg.contains('device in use')      ||
           msg.contains('failed to allocate') ||
           msg.contains('hardware error')     ||
           msg.contains('not readable');
  }

  Future<void> _openLocalMediaWeb() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'width':     {'ideal': 640},
          'height':    {'ideal': 480},
          'frameRate': {'ideal': 30},
        },
      });
      return;
    } catch (e) {
      if (!_isDeviceBusy(e)) rethrow;
    }

    if (mounted) setState(() => _status = 'Retrying camera…');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': true,
      });
      return;
    } catch (e) {
      if (!_isDeviceBusy(e)) rethrow;
    }

    if (mounted) setState(() => _status = 'Camera busy — audio only');
    await Future<void>.delayed(const Duration(milliseconds: 200));

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
  }

  Future<void> _openLocalMediaNative() async {
    final granted = await Helper.requestCapturePermission();
    if (!granted) throw Exception('Camera/microphone permission denied');

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width':      {'ideal': 640},
          'height':     {'ideal': 480},
          'frameRate':  {'ideal': 30},
        },
      });
      try { await Helper.setSpeakerphoneOn(true); } catch (_) {}
      return;
    } catch (e) {
      if (!_isDeviceBusy(e)) rethrow;
    }

    if (mounted) setState(() => _status = 'Retrying camera…');
    await Future<void>.delayed(const Duration(milliseconds: 800));

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'width':  {'ideal': 320},
          'height': {'ideal': 240},
        },
      });
      try { await Helper.setSpeakerphoneOn(true); } catch (_) {}
      return;
    } catch (e) {
      if (!_isDeviceBusy(e)) rethrow;
    }

    if (mounted) setState(() => _status = 'Camera busy — audio only');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    try { await Helper.setSpeakerphoneOn(true); } catch (_) {}
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

  Future<void> _cleanup() async {
    if (_cleanedUp) return;
    _cleanedUp = true;
    _pendingIce.clear();
    _detachListeners();

    try { await _pc?.close(); } catch (_) {}
    _pc = null;

    try {
      for (final t in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        t.stop();
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
    if (!_accepted) return _buildIncomingUI();
    return _buildCallUI();
  }

  Widget _buildIncomingUI() {
    return Scaffold(
      backgroundColor: const Color(0xCC000000),
      body: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color:        const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.5),
                blurRadius: 24,
                offset:     const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade800,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white70,
                  size:  36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Incoming video call',
                style: TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize:   17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Case #${widget.invite.emergencyId}',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _CallButton(
                      label: 'Decline',
                      icon:  Icons.call_end_rounded,
                      color: const Color(0xFFD32F2F),
                      onTap: _reject,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _CallButton(
                      label: 'Accept',
                      icon:  Icons.videocam_rounded,
                      color: const Color(0xFF2E7D32),
                      onTap: _accept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation:       0,
        title: Text(
          'Case #${widget.invite.emergencyId}',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          IconButton(
            icon:      const Icon(Icons.call_end_rounded, color: Colors.red, size: 28),
            onPressed: _hangup,
            tooltip:   'Hang up',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _starting ? _buildLoader() : _buildVideo(),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white38, strokeWidth: 2.5),
          const SizedBox(height: 20),
          Text(
            _status,
            style:     const TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    final bool hasLocalVideo =
        _localStream != null && _localStream!.getVideoTracks().isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Remote full-screen
        RTCVideoView(
          _remote,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),

        // Local PiP — hidden if audio-only fallback
        if (hasLocalVideo)
          Positioned(
            right: 16, bottom: 24, width: 110, height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.blueGrey.shade900,
                child: RTCVideoView(_local, mirror: true),
              ),
            ),
          ),

        // Badge shown when camera is unavailable
        if (!hasLocalVideo && _accepted && !_starting)
          Positioned(
            right: 16, bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color:        Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Cam\nbusy',
                    style:     TextStyle(color: Colors.white38, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // Status pill
        Positioned(
          left: 16, bottom: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:        Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: _status == 'In call'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── _CallButton ────────────────────────────────────────────────────────────
class _CallButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;

  const _CallButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon:      Icon(icon, size: 19),
      label:     Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: onTap,
    );
  }
}