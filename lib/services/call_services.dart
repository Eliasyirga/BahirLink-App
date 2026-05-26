import 'dart:io';
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
  String toString() => 'CallInvite(emergencyId: $emergencyId, '
      'fromSocketId: $fromSocketId, '
      'reporterUserId: $reporterUserId)';
}

typedef IncomingCallHandler = void Function(CallInvite invite);

class CallService {
  CallService._();
  static final CallService I = CallService._();

  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // ─── WebSocket Server URL Router ───────────────────────────────────────────
  static String get wsServerUrl {
    if (!useLocalBackup) {
      // Direct live WebSocket instance URL targeting production containers
      return "https://bahirlink-backend-1.onrender.com";
    }
    if (kIsWeb) return "http://localhost:5000";
    if (Platform.isAndroid)
      return "http://10.0.2.2:5000"; // Android Emulator address
    return "http://localhost:5000"; // iOS Simulator or Desktop
  }

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  String? _apiBaseUrl;
  String? _cleanedToken;

  CallInvite? pendingInvite;
  IncomingCallHandler? onIncomingCall;

  bool _connecting = false;
  int _sessionId = 0;

  Set<String> _seenInCurrentRegistration = {};

  // ── Public getters ────────────────────────────────────────────────────────
  bool get isConnected => _socket?.connected == true;
  bool get isConfigured => _sessionId > 0;

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _cleanToken(String token) => token
      .replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '')
      .trim();

  // ── connect ───────────────────────────────────────────────────────────────
  void connect({String? apiBaseUrl, required String token}) {
    final clean = _cleanToken(token);

    // Fall back to our centralized wsServerUrl if no custom base URL parameter is supplied
    final targetUrl = (apiBaseUrl != null && apiBaseUrl.isNotEmpty)
        ? apiBaseUrl
        : wsServerUrl;

    if (isConnected) {
      debugPrint('📞 CallService.connect() — already connected, skipping');
      if (_socket != null) _registerIncomingListener(_socket!);
      return;
    }

    if (isConfigured || _connecting) {
      debugPrint(
          '📞 CallService.connect() — session $_sessionId active, skipping');
      return;
    }

    _connecting = true;
    _apiBaseUrl = targetUrl;
    _cleanedToken = clean;
    _sessionId++;

    debugPrint('📞 CallService.connect() → $targetUrl [session $_sessionId]');

    _destroySocket();

    final s = IO.io(
      targetUrl,
      IO.OptionBuilder()
          .setTransports(
              ['websocket']) // Force pure WebSockets over slow long-polling
          .setAuth({'token': 'Bearer $clean'})
          .enableAutoConnect()
          // ✅ FIX: Moved timeout configurations here to satisfy compiler restrictions on socket_io_client v2.x
          .setExtraHeaders({
            'pingTimeout': 30000,
            'pingInterval': 10000,
            'connectionTimeout':
                60000, // 60s timeout accommodates Render spin-ups safely
          })
          .build(),
    );

    _socket = s;

    s.onConnect((_) {
      _connecting = false;
      debugPrint('📞 CallService connected — socket.id: ${s.id}');
      _registerIncomingListener(s);
    });

    s.onConnectError((e) {
      _connecting = false;
      debugPrint('📞 CallService connect error: $e');
    });

    s.onDisconnect((reason) {
      _connecting = false;
      debugPrint('📞 CallService disconnected: $reason');
    });
  }

  // ── ensureConnected ───────────────────────────────────────────────────────
  void ensureConnected() {
    if (_cleanedToken == null) {
      debugPrint('📞 ensureConnected: no credentials — call connect() first');
      return;
    }
    if (_socket == null) {
      connect(apiBaseUrl: _apiBaseUrl, token: _cleanedToken!);
      return;
    }
    if (isConnected) return;
    if (!_connecting) {
      debugPrint(
          '📞 ensureConnected: socket exists but disconnected — reconnecting');
      _socket!.connect();
    }
  }

  // ── disconnect ────────────────────────────────────────────────────────────
  void disconnect() {
    _destroySocket();
    _sessionId = 0;
    pendingInvite = null;
    _seenInCurrentRegistration = {};
    debugPrint('📞 CallService disconnected (logout)');
  }

  // ── clearCall ─────────────────────────────────────────────────────────────
  void clearCall(int emergencyId) {
    _seenInCurrentRegistration
        .removeWhere((fp) => fp.startsWith('$emergencyId|'));
    pendingInvite = null;
  }

  // ── Private ───────────────────────────────────────────────────────────────
  void _destroySocket() {
    try {
      _socket?.off('call:incoming');
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _connecting = false;
  }

  void _registerIncomingListener(IO.Socket s) {
    s.off('call:incoming');
    _seenInCurrentRegistration = {};

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

      if (_seenInCurrentRegistration.contains(invite.fingerprint)) {
        debugPrint(
            '📞 call:incoming ignored — duplicate: ${invite.fingerprint}');
        return;
      }

      _seenInCurrentRegistration.add(invite.fingerprint);
      pendingInvite = invite;

      debugPrint(
          '📞 onIncomingCall is ${onIncomingCall == null ? "NULL ❌" : "set ✅"}');
      debugPrint('📞 call:incoming dispatching: $invite');

      onIncomingCall?.call(invite);
    });
  }

  // ── Signalling ────────────────────────────────────────────────────────────
  void joinCallRoom(int emergencyId) {
    debugPrint(
        '📞 joinCallRoom($emergencyId) — connected: ${_socket?.connected}');
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
