import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
          ? Map<String, dynamic>.from(m['fromIdentity'] as Map)
          : null,
      reporterUserId: m['reporterUserId'] == null
          ? null
          : int.tryParse('${m['reporterUserId']}'),
    );
  }

  String get fingerprint => '$emergencyId|$fromSocketId';

  @override
  String toString() =>
      'CallInvite(emergencyId: $emergencyId, fromSocketId: $fromSocketId, '
      'reporterUserId: $reporterUserId)';
}

typedef IncomingCallHandler = void Function(CallInvite invite);

class CallService {
  CallService._();
  static final CallService I = CallService._();

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  String? _apiBaseUrl;
  String? _cleanedToken;

  CallInvite? pendingInvite;
  IncomingCallHandler? onIncomingCall;

  bool _connecting = false;

  // Cleared only on logout, never on reconnect.
  final Set<String> _dispatchedFingerprints = {};

  String _cleanToken(String token) =>
      token.replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '').trim();

  bool get isConnected => _socket?.connected == true;

  // ---------------------------------------------------------------------------
  // connect — call once after login.
  // ---------------------------------------------------------------------------
  void connect({required String apiBaseUrl, required String token}) {
    if (_connecting) return;
    _connecting = true;

    final clean = _cleanToken(token);
    _apiBaseUrl = apiBaseUrl;
    _cleanedToken = clean;

    debugPrint('📞 CallService.connect() → $apiBaseUrl');

    _destroySocket();

    final s = IO.io(
      apiBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $clean'})
          .enableAutoConnect()
          .build(),
    );

    _socket = s;

    // Register call:incoming immediately — socket_io_client buffers events
    // registered before connect, so this is safe and avoids any race where
    // the server sends call:incoming before onConnect fires.
    _registerIncomingListener(s);

    s.onConnect((_) {
      _connecting = false;
      debugPrint('📞 CallService connected — socket.id: ${s.id}');
      // Re-register after every (re)connect to guarantee the listener
      // survives transport-level reconnects.
      _registerIncomingListener(s);
    });

    s.onConnectError((e) {
      _connecting = false;
      debugPrint('📞 CallService connect error: $e');
    });

    s.onDisconnect((reason) {
      debugPrint('📞 CallService disconnected: $reason');
    });
  }

  // ---------------------------------------------------------------------------
  // ensureConnected — safe to call from any page's initState.
  // ---------------------------------------------------------------------------
  void ensureConnected() {
    if (_apiBaseUrl == null || _cleanedToken == null) {
      debugPrint('📞 ensureConnected: no credentials — call connect() first');
      return;
    }
    if (_socket == null) {
      connect(apiBaseUrl: _apiBaseUrl!, token: _cleanedToken!);
      return;
    }
    if (!_socket!.connected) {
      debugPrint('📞 ensureConnected: socket exists but disconnected — reconnecting');
      _connecting = false;
      _socket!.connect();
    }
    // Always re-register to survive hot restarts and reconnects.
    _registerIncomingListener(_socket!);
  }

  // ---------------------------------------------------------------------------
  // disconnect — logout only.
  // ---------------------------------------------------------------------------
  void disconnect() {
    _destroySocket();
    pendingInvite = null;
    _dispatchedFingerprints.clear();
    debugPrint('📞 CallService disconnected (logout)');
  }

  // ---------------------------------------------------------------------------
  // clearCall — call on hangup so the same emergency can ring again.
  // ---------------------------------------------------------------------------
  void clearCall(int emergencyId) {
    _dispatchedFingerprints.removeWhere((fp) => fp.startsWith('$emergencyId|'));
    pendingInvite = null;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  void _destroySocket() {
    try {
      _socket?.off('call:incoming');
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _connecting = false;
  }

  /// off() before on() guarantees exactly one listener no matter how many
  /// times this is called. Safe to call before and after connect.
  void _registerIncomingListener(IO.Socket s) {
    s.off('call:incoming');
    debugPrint('📞 _registerIncomingListener — socket.id: ${s.id}');

    s.on('call:incoming', (data) {
      debugPrint('📞 call:incoming raw: $data');

      if (data is! Map) {
        debugPrint('📞 call:incoming ignored — not a Map');
        return;
      }

      final invite = CallInvite.fromMap(data);

      if (invite.emergencyId == 0 || invite.fromSocketId.isEmpty) {
        debugPrint('📞 call:incoming ignored — invalid payload');
        return;
      }

      debugPrint('📞 dedup set: $_dispatchedFingerprints');

      if (_dispatchedFingerprints.contains(invite.fingerprint)) {
        debugPrint('📞 call:incoming ignored — duplicate: ${invite.fingerprint}');
        return;
      }

      _dispatchedFingerprints.add(invite.fingerprint);
      pendingInvite = invite;

      debugPrint('📞 onIncomingCall is ${onIncomingCall == null ? "NULL ❌" : "set ✅"}');
      debugPrint('📞 call:incoming dispatching: $invite');

      onIncomingCall?.call(invite);
    });
  }

  // ---------------------------------------------------------------------------
  // Signalling
  // ---------------------------------------------------------------------------

  void joinCallRoom(int emergencyId) {
    debugPrint('📞 joinCallRoom($emergencyId) — connected: ${_socket?.connected}');
    _socket?.emit('call:join', {'emergencyId': emergencyId});
  }

  void sendOffer({
    required int emergencyId,
    required String? toSocketId,
    required Map<String, dynamic> sdp,
  }) {
    if (toSocketId == null || toSocketId.isEmpty) return;
    _socket?.emit('call:offer', {
      'emergencyId': emergencyId,
      'toSocketId': toSocketId,
      'sdp': sdp,
    });
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

  void hangup({required int emergencyId, String? toSocketId}) {
    _socket?.emit('call:hangup', {
      'emergencyId': emergencyId,
      if (toSocketId != null && toSocketId.isNotEmpty) 'toSocketId': toSocketId,
    });
    clearCall(emergencyId);
  }
}