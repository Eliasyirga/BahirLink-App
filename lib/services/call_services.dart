import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Backend event: call:incoming { emergencyId, fromSocketId, fromIdentity, reporterUserId }
class CallInvite {
  final int emergencyId;
  final String fromSocketId;
  final Map<String, dynamic>? fromIdentity;
  final int? reporterUserId;

  CallInvite({
    required this.emergencyId,
    required this.fromSocketId,
    this.fromIdentity,
    this.reporterUserId,
  });

  factory CallInvite.fromMap(Map data) {
    final m = Map<String, dynamic>.from(data);
    return CallInvite(
      emergencyId: int.tryParse('${m['emergencyId']}') ?? 0,
      fromSocketId: '${m['fromSocketId'] ?? ''}',
      fromIdentity: m['fromIdentity'] is Map
          ? Map<String, dynamic>.from(m['fromIdentity'])
          : null,
      reporterUserId: m['reporterUserId'] == null
          ? null
          : int.tryParse('${m['reporterUserId']}'),
    );
  }
}

typedef IncomingCallHandler = void Function(CallInvite invite);

class CallService {
  CallService._();
  static final CallService I = CallService._();

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  String? _apiBaseUrl;
  String? _token; // raw jwt (no Bearer)

  /// Latest invite (so the video icon can open it).
  CallInvite? pendingInvite;

  /// Called when backend emits `call:incoming`.
  IncomingCallHandler? onIncomingCall;

  bool _incomingAttached = false;

  // Debounce duplicates (reconnects can fire twice).
  String? _lastFp;
  DateTime? _lastFpAt;

  String _cleanToken(String token) =>
      token.replaceFirst(RegExp(r'^Bearer\\s+', caseSensitive: false), '').trim();

  bool _ignoreDuplicate(CallInvite i) {
    final fp = '${i.emergencyId}|${i.fromSocketId}';
    final now = DateTime.now();
    if (_lastFp == fp && _lastFpAt != null) {
      if (now.difference(_lastFpAt!) < const Duration(seconds: 2)) return true;
    }
    _lastFp = fp;
    _lastFpAt = now;
    return false;
  }

  bool get isConnected => _socket?.connected == true;

  /// Call this as soon as you have user token (after login).
  void connect({required String apiBaseUrl, required String token}) {
    final clean = _cleanToken(token);
    _apiBaseUrl = apiBaseUrl;
    _token = clean;

    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _incomingAttached = false;

    final s = IO.io(
      apiBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $clean'})
          .enableAutoConnect()
          .build(),
    );

    _socket = s;

    s.onConnect((_) => debugPrint('📞 Call socket connected'));
    s.onConnectError((e) => debugPrint('📞 Call socket error: $e'));

    _attachIncomingOnce();
  }

  void _attachIncomingOnce() {
    final s = _socket;
    if (s == null || _incomingAttached) return;
    _incomingAttached = true;

    s.on('call:incoming', (data) {
      if (data is! Map) return;
      final invite = CallInvite.fromMap(data);
      if (invite.emergencyId == 0 || invite.fromSocketId.isEmpty) return;
      if (_ignoreDuplicate(invite)) return;

      pendingInvite = invite;
      onIncomingCall?.call(invite);
    });
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _incomingAttached = false;
    pendingInvite = null;
    _lastFp = null;
    _lastFpAt = null;
  }

  void ensureConnected() {
    if (_apiBaseUrl == null || _token == null) return;
    if (_socket == null) {
      connect(apiBaseUrl: _apiBaseUrl!, token: _token!);
      return;
    }
    if (_socket!.connected != true) _socket!.connect();
  }

  void joinCallRoom(int emergencyId) {
    _socket?.emit('call:join', {'emergencyId': emergencyId});
  }

  void sendAnswer({
    required int emergencyId,
    required String? toSocketId,
    required Map<String, dynamic> sdp,
  }) {
    if (toSocketId == null || toSocketId.isEmpty) return;
    _socket?.emit('call:answer', {
      'emergencyId': emergencyId,
      'toSocketId': toSocketId,
      'sdp': sdp,
    });
  }

  void sendIce({
    required int emergencyId,
    required String? toSocketId,
    required Map<String, dynamic> candidate,
  }) {
    if (toSocketId == null || toSocketId.isEmpty) return;
    _socket?.emit('call:ice', {
      'emergencyId': emergencyId,
      'toSocketId': toSocketId,
      'candidate': candidate,
    });
  }

  void hangup({
    required int emergencyId,
    String? toSocketId,
  }) {
    _socket?.emit('call:hangup', {
      'emergencyId': emergencyId,
      if (toSocketId != null && toSocketId.isNotEmpty) 'toSocketId': toSocketId,
    });
  }
}