import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Backend event payload: call:incoming
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
      // Robust parse: handles int, String, double from any backend serialisation
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
  String? _token; // clean jwt — no "Bearer " prefix

  /// Latest unhandled invite. ChatPage checks this in initState to avoid
  /// missing an event that fired before the screen was pushed.
  CallInvite? pendingInvite;

  /// Registered by ChatPage.initState; cleared in ChatPage.dispose.
  IncomingCallHandler? onIncomingCall;

  bool _incomingAttached = false;
  bool _connecting = false;

  // Deduplicate rapid duplicate events (reconnect storms fire twice).
  String? _lastFp;
  DateTime? _lastFpAt;

  // FIX: correct regex — single backslash so \s matches whitespace properly.
  String _cleanToken(String token) =>
      token.replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '').trim();

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

  // ---------------------------------------------------------------------------
  // connect — call this right after login, before any chat screen opens.
  // Uses websocket transport only; polling fails auth on Flutter Web.
  // ---------------------------------------------------------------------------
  void connect({required String apiBaseUrl, required String token}) {
    if (_connecting) return;
    _connecting = true;

    final clean = _cleanToken(token);
    _apiBaseUrl = apiBaseUrl;
    _token = clean;

    debugPrint('📞 CallService.connect() → $apiBaseUrl');

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

    s.onConnect((_) {
      _connecting = false;
      debugPrint('📞 CallService connected — socket.id: ${s.id}');
    });

    s.onConnectError((e) {
      _connecting = false;
      debugPrint('📞 CallService connect error: $e');
    });

    s.onDisconnect((reason) {
      debugPrint('📞 CallService disconnected: $reason');
    });

    _attachIncomingOnce();
  }

  void _attachIncomingOnce() {
    final s = _socket;
    if (s == null || _incomingAttached) return;
    _incomingAttached = true;

    s.on('call:incoming', (data) {
      debugPrint('📞 call:incoming raw: $data');

      if (data is! Map) {
        debugPrint('📞 call:incoming ignored — not a Map');
        return;
      }

      final invite = CallInvite.fromMap(data);

      if (invite.emergencyId == 0) {
        debugPrint('📞 call:incoming ignored — emergencyId parsed as 0');
        return;
      }
      if (invite.fromSocketId.isEmpty) {
        debugPrint('📞 call:incoming ignored — empty fromSocketId');
        return;
      }
      if (_ignoreDuplicate(invite)) {
        debugPrint('📞 call:incoming ignored — duplicate within 2 s');
        return;
      }

      debugPrint('📞 call:incoming accepted: $invite');

      // Store before firing the callback so ChatPage.initState can consume it
      // even if the screen was not open when the event arrived.
      pendingInvite = invite;
      onIncomingCall?.call(invite);
    });
  }

  // ---------------------------------------------------------------------------
  // disconnect — call on logout.
  // ---------------------------------------------------------------------------
  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _incomingAttached = false;
    _connecting = false;
    pendingInvite = null;
    _lastFp = null;
    _lastFpAt = null;
  }

  // ---------------------------------------------------------------------------
  // ensureConnected — called by ChatPage.initState as a safety net.
  // If connect() was already called this is nearly a no-op.
  // ---------------------------------------------------------------------------
  void ensureConnected() {
    if (_apiBaseUrl == null || _token == null) {
      debugPrint(
          '📞 ensureConnected: no credentials — call connect() after login first');
      return;
    }
    if (_socket == null) {
      connect(apiBaseUrl: _apiBaseUrl!, token: _token!);
      return;
    }
    if (_socket!.connected != true) {
      debugPrint(
          '📞 ensureConnected: socket exists but disconnected — reconnecting');
      _socket!.connect();
    }
    // Re-attach listener in case it was cleared (e.g. after a hot restart).
    _attachIncomingOnce();
  }

  // ---------------------------------------------------------------------------
  // Call room helpers
  // ---------------------------------------------------------------------------
  void joinCallRoom(int emergencyId) {
    debugPrint(
        '📞 joinCallRoom($emergencyId) — socket: ${_socket?.id}, '
        'connected: ${_socket?.connected}');
    _socket?.emit('call:join', {'emergencyId': emergencyId});
  }

  // ---------------------------------------------------------------------------
  // Signalling helpers
  // ---------------------------------------------------------------------------
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

  void hangup({
    required int emergencyId,
    String? toSocketId,
  }) {
    _socket?.emit('call:hangup', {
      'emergencyId': emergencyId,
      if (toSocketId != null && toSocketId.isNotEmpty)
        'toSocketId': toSocketId,
    });
  }
}