import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http_parser/http_parser.dart';
// Audio
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

// Call
import '../../services/call_services.dart';
import '../call/call_page.dart';
import '../../main.dart' show appMessengerKey;

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _T {
  static const primary    = Color(0xFF1A3BAA);
  static const primaryMid = Color(0xFF2252CC);
  static const accent     = Color(0xFF4B83F0);
  static const accentSoft = Color(0xFFD6E4FF);
  static const surface    = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF2F6FF);
  static const textDark   = Color(0xFF0C1A45);
  static const textMid    = Color(0xFF5569A0);
  static const divider    = Color(0xFFE5ECFF);
  static const green      = Color(0xFF0DB87A);
  static const orange     = Color(0xFFF59E0B);
  static const red        = Color(0xFFEF4444);
  static const bubbleMe   = Color(0xFF1A3BAA);
  static const bubbleThem = Color(0xFFFFFFFF);
  static const chatBg     = Color(0xFFF0F5FF);
}

// ─── ChatPage ─────────────────────────────────────────────────────────────────
class ChatPage extends StatefulWidget {
  final int    emergencyId;
  final String token;
  final int    userId;

  const ChatPage({
    super.key,
    required this.emergencyId,
    required this.token,
    required this.userId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  static const String _serverUrl = "http://localhost:5000";

  // ── Disposed flag ─────────────────────────────────────────────────────────
  bool _disposed = false;

  // ── Socket ────────────────────────────────────────────────────────────────
  IO.Socket? _socket;

  // ── State ─────────────────────────────────────────────────────────────────
  bool   _isLoading      = true;
  String _status         = "idle";
  bool   _isChatEnabled  = false;
  bool   _isComposing    = false;
  bool   _isRecording    = false;
  bool   _isUploading    = false;

  // Stores the temp file path between _startRecording and _stopAndSend
  String? _recordingPath;

  // ── Audio ─────────────────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer   _player   = AudioPlayer();
  dynamic _playingKey;

  // ── Messages ──────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _messages = [];
  final Set<dynamic> _seenKeys = {};

  // ── Controllers ───────────────────────────────────────────────────────────
  final TextEditingController _msgCtrl    = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _cleanToken {
    final t = widget.token.trim();
    return t.startsWith("Bearer ") ? t.substring(7) : t;
  }

  String _absoluteUrl(String url) =>
      url.startsWith("http") ? url : "$_serverUrl$url";

  Color _statusColor() => switch (_status) {
        "ready"      => _isChatEnabled ? _T.green : _T.orange,
        "connecting" => _T.orange,
        "error"      => _T.red,
        _            => _T.textMid,
      };

  String _statusLabel() => switch (_status) {
        "ready"      => _isChatEnabled ? "Online" : "Waiting for responder…",
        "connecting" => "Connecting…",
        "error"      => "Offline",
        _            => "Idle",
      };

  bool _isMe(Map<String, dynamic> msg) =>
      msg["senderType"] == "user" && msg["senderId"] == widget.userId;

  bool _isAudio(Map<String, dynamic> msg) =>
      msg["messageType"]?.toString() == "audio" ||
      (msg["audioUrl"] != null && msg["audioUrl"].toString().isNotEmpty);

  DateTime? _parseTime(Map<String, dynamic> msg) {
    final raw = msg["createdAt"] ?? msg["created_at"] ??
                msg["timestamp"] ?? msg["time"];
    if (raw == null) return null;
    if (raw is int) {
      return raw > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(raw)
          : DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    return DateTime.tryParse(raw.toString());
  }

  String _formatTime(DateTime dt) {
    final h  = dt.hour;
    final hh = ((h + 11) % 12) + 1;
    final mm = dt.minute.toString().padLeft(2, "0");
    return "$hh:$mm ${h >= 12 ? 'PM' : 'AM'}";
  }

  void _showError(String message) {
    if (_disposed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      behavior:        SnackBarBehavior.floating,
      backgroundColor: _T.textDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _scrollToBottom({bool force = false}) {
    Future.delayed(const Duration(milliseconds: 180), () {
      if (_disposed || !_scrollCtrl.hasClients) return;
      force
          ? _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent)
          : _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 260),
              curve:    Curves.easeOut,
            );
    });
  }

  void _addMessage(Map<String, dynamic> msg) {
    if (_disposed || !mounted) return;
    final key = msg["id"] ?? msg["createdAt"] ?? msg["created_at"];
    if (key != null && _seenKeys.contains(key)) return;
    if (key != null) _seenKeys.add(key);
    setState(() => _messages.add(msg));
  }

  // ── Socket teardown ───────────────────────────────────────────────────────
  void _teardownSocket() {
    if (_disposed) return;
    _disposed = true;
    final s = _socket;
    _socket = null;
    s?.clearListeners();
    s?.disconnect();
    s?.dispose();
  }

  void _safePop() {
    try { appMessengerKey.currentState?.clearSnackBars(); } catch (_) {}
    _teardownSocket();
    Navigator.of(context).pop();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    CallService.I.ensureConnected();
    _initChat();

    _msgCtrl.addListener(() {
      if (_disposed || !mounted) return;
      final next = _msgCtrl.text.trim().isNotEmpty;
      if (next == _isComposing) return;
      setState(() => _isComposing = next);
    });

    _player.onPlayerComplete.listen((_) {
      if (_disposed || !mounted) return;
      setState(() => _playingKey = null);
    });
  }

  @override
  void deactivate() {
    _teardownSocket();
    try { appMessengerKey.currentState?.clearSnackBars(); } catch (_) {}
    super.deactivate();
  }

  @override
  void dispose() {
    _teardownSocket();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _player.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> _initChat() async {
    if (_disposed || !mounted) return;
    setState(() { _isLoading = true; _status = "connecting"; });

    try {
      final res = await http.get(
        Uri.parse("$_serverUrl/api/message/${widget.emergencyId}"),
        headers: {
          "Authorization": "Bearer $_cleanToken",
          "Content-Type":  "application/json",
        },
      );

      if (_disposed || !mounted) return;

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode != 200 || body["success"] != true) {
        _showError(body["message"]?.toString() ?? "Failed to load chat history");
        setState(() => _status = "error");
        return;
      }

      final list = (body["data"] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      for (final m in list) {
        final k = m["id"] ?? m["createdAt"] ?? m["created_at"];
        if (k != null) _seenKeys.add(k);
      }

      // If any message from a responder exists in history, chat is already
      // open — unlock immediately so the user doesn't have to wait.
      final alreadyEnabled = list.any((m) => m["senderType"] == "responderTeam");

      setState(() {
        _messages..clear()..addAll(list);
        if (alreadyEnabled) _isChatEnabled = true;
      });

      _connectSocket();
      _scrollToBottom(force: true);
      _fadeCtrl.forward();
    } catch (e) {
      debugPrint("_initChat error: $e");
      if (_disposed || !mounted) return;
      setState(() => _status = "error");
      _showError("Could not reach server.");
    } finally {
      if (!_disposed && mounted) setState(() => _isLoading = false);
    }
  }

  // ── Socket ────────────────────────────────────────────────────────────────
  void _connectSocket() {
    final old = _socket;
    _socket = null;
    old?.clearListeners();
    old?.disconnect();
    old?.dispose();

    if (_disposed) return;

    final s = IO.io(
      _serverUrl,
      IO.OptionBuilder()
          .setTransports(["websocket"])
          .setAuth({"token": "Bearer $_cleanToken"})
          .disableAutoConnect()
          .build(),
    );
    _socket = s;

    s.onConnect((_) {
      if (_disposed || !mounted) return;
      s.emit("chat:join",      {"emergencyId": widget.emergencyId});
      s.emit("join_emergency", widget.emergencyId);
    });

    // One-way ratchet — only ever goes true, never back to false.
    s.on("chat:joined", (data) {
      if (_disposed || !mounted) return;
      final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      setState(() {
        _status = "ready";
        if (map["isChatEnabled"] == true) _isChatEnabled = true;
      });
    });

    s.on("chat:new", _onIncoming);

    // Fired by the server the moment a responder enables chat.
    s.on("chat:enabled", (data) {
      if (_disposed || !mounted) return;
      setState(() => _isChatEnabled = true);
    });

    s.on("error_alert", (e) {
      if (_disposed) return;
      final raw = e is Map ? (e["message"] ?? e["error"] ?? e.toString()) : e.toString();
      _showError(raw.toString());
    });

    s.onConnectError((_) {
      if (_disposed || !mounted) return;
      setState(() => _status = "error");
      _showError("Socket connection failed.");
    });

    s.connect();
  }

  void _onIncoming(dynamic data) {
    if (_disposed || !mounted) return;
    try {
      final msg = Map<String, dynamic>.from(data as Map);

      // Any incoming message means chat is open — unlock if not already.
      if (!_isChatEnabled) setState(() => _isChatEnabled = true);

      final isOwnText = msg["senderId"]   == widget.userId &&
                        msg["senderType"] == "user" &&
                        (msg["messageType"] == "text" ||
                         msg["audioUrl"] == null ||
                         msg["audioUrl"] == "");
      if (isOwnText) return;

      _addMessage(msg);
      _scrollToBottom();
    } catch (e) {
      debugPrint("Bad socket payload: $e");
    }
  }

  // ── Send text ─────────────────────────────────────────────────────────────
  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    if (!_isChatEnabled) {
      _showError("Chat not yet opened by a responder. Please wait.");
      return;
    }

    final s = _socket;
    if (s == null || !s.connected) {
      _showError("Not connected to chat.");
      return;
    }

    final optimisticKey = "opt_${DateTime.now().millisecondsSinceEpoch}";
    _addMessage(<String, dynamic>{
      "id":          optimisticKey,
      "emergencyId": widget.emergencyId,
      "senderId":    widget.userId,
      "senderType":  "user",
      "messageType": "text",
      "text":        text,
      "audioUrl":    null,
      "createdAt":   DateTime.now().toIso8601String(),
    });

    s.emit("chat:send", {"emergencyId": widget.emergencyId, "text": text});
    _msgCtrl.clear();
    _scrollToBottom();
  }

  // ── Video call ────────────────────────────────────────────────────────────
  void _openCallOrExplain() {
    final invite = CallService.I.pendingInvite;
    if (invite != null && invite.emergencyId == widget.emergencyId) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CallPage(invite: invite),
      ));
      return;
    }
    _showError("No incoming call right now. Wait for the responder.");
  }

  // ── Audio recording ───────────────────────────────────────────────────────
  Future<void> _toggleRecord() async {
    if (!_isChatEnabled) {
      _showError("Chat not yet opened by a responder. Please wait.");
      return;
    }
    if (_status != "ready") { _showError("Chat not connected yet."); return; }
    if (_isUploading) return;
    _isRecording ? await _stopAndSend() : await _startRecording();
  }

  Future<void> _startRecording() async {
    final ok = await _recorder.hasPermission();
    if (!ok) { _showError("Microphone permission denied."); return; }
    try {
      // FIX: use the system temp directory — a bare filename is not writable
      // on Android/iOS. Store the path so _stopAndSend can find the file.
      final dir  = Directory.systemTemp;
      final path = '${dir.path}/bahirlink_'
                   '${widget.emergencyId}_'
                   '${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder:    AudioEncoder.aacLc,
          bitRate:    128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _recordingPath = path;
      if (!_disposed && mounted) setState(() => _isRecording = true);
    } catch (e) {
      _showError("Failed to start recording: $e");
    }
  }

  Future<void> _stopAndSend() async {
    try {
      // FIX: _recorder.stop() returns the path but on some platforms it
      // returns null even on success. Fall back to the path we stored at
      // start time so we never lose the file.
      final stoppedPath = await _recorder.stop();
      final path = stoppedPath ?? _recordingPath;
      _recordingPath = null;

      if (!_disposed && mounted) setState(() => _isRecording = false);

      if (path == null || path.isEmpty) {
        _showError("Recording finished but no file was saved.");
        return;
      }

      // Verify the file actually exists before trying to upload it.
      final file = File(path);
      if (!file.existsSync()) {
        _showError("Recording file not found at: $path");
        return;
      }

      final size = file.lengthSync();
      if (size == 0) {
        _showError("Recording is empty — please try again.");
        return;
      }

      debugPrint("🎙 Uploading audio: $path ($size bytes)");
      await _uploadAudio(path);
    } catch (e) {
      if (!_disposed && mounted) setState(() => _isRecording = false);
      _recordingPath = null;
      _showError("Failed to stop recording: $e");
    }
  }

  Future<void> _uploadAudio(String path) async {
    if (_disposed || !mounted) return;
    setState(() => _isUploading = true);

    try {
      // FIX: explicitly set the content-type so the server multer middleware
      // recognises the file as audio regardless of the file extension.
      final file     = File(path);
      final filename = path.split('/').last;

      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$_serverUrl/api/message/audio"),
      )
        ..headers["Authorization"] = "Bearer $_cleanToken"
        ..fields["emergencyId"]    = widget.emergencyId.toString()
        ..files.add(
          http.MultipartFile(
            "audio",                        // must match upload.single("audio")
            file.openRead(),
            file.lengthSync(),
            filename:    filename,
            contentType: MediaType("audio", "mp4"), // m4a is audio/mp4
          ),
        );

      debugPrint("📤 POST ${ _serverUrl}/api/message/audio "
                 "| file=$filename | size=${file.lengthSync()}");

      final streamed = await req.send();
      if (_disposed || !mounted) return;

      final res  = await http.Response.fromStream(streamed);
      debugPrint("📥 Audio upload response: ${res.statusCode} ${res.body}");

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      // FIX: accept both 200 and 201 — some server configs return 200.
      if ((res.statusCode != 200 && res.statusCode != 201) ||
          body["success"] != true) {
        _showError(body["message"]?.toString() ?? "Audio upload failed");
        return;
      }

      final saved = Map<String, dynamic>.from(body["data"] as Map);
      _addMessage(saved);
      _scrollToBottom();

      // Clean up the temp file after a successful upload.
      try { file.deleteSync(); } catch (_) {}
    } catch (e) {
      debugPrint("❌ _uploadAudio error: $e");
      _showError("Failed to upload audio: $e");
    } finally {
      if (!_disposed && mounted) setState(() => _isUploading = false);
    }
  }

  // ── Audio playback ────────────────────────────────────────────────────────
  Future<void> _togglePlay(Map<String, dynamic> msg, dynamic key) async {
    final audioUrl = msg["audioUrl"]?.toString();
    if (audioUrl == null || audioUrl.isEmpty) return;
    final src = _absoluteUrl(audioUrl);
    try {
      if (_playingKey == key) {
        await _player.pause();
        if (!_disposed && mounted) setState(() => _playingKey = null);
        return;
      }
      await _player.stop();
      await _player.play(UrlSource(src));
      if (!_disposed && mounted) setState(() => _playingKey = key);
    } catch (e) {
      _showError("Audio playback failed: $e");
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final canType     = _status == "ready" && _isChatEnabled && !_isRecording && !_isUploading;
    final sendEnabled = canType && _isComposing;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.chatBg,
        body: Column(children: [
          _buildHeader(),
          if (_isUploading)
            LinearProgressIndicator(
              minHeight:       2,
              color:           _T.accent,
              backgroundColor: _T.accentSoft,
            ),
          if (_status == "ready" && !_isChatEnabled)
            _buildChatDisabledBanner(),
          Expanded(
            child: _isLoading
                ? _buildSplash()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: Stack(children: [
                      Positioned.fill(child: _buildBgPattern()),
                      _messages.isEmpty
                          ? _buildEmptyState()
                          : _buildMessageList(),
                    ]),
                  ),
          ),
          _buildInputBar(canType: canType, sendEnabled: sendEnabled),
        ]),
      ),
    );
  }

  Widget _buildChatDisabledBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: _T.orange.withOpacity(0.12),
        child: Row(children: [
          const Icon(Icons.hourglass_top_rounded, color: _T.orange, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Waiting for a responder to open this chat before you can send messages.",
              style: TextStyle(
                color:      _T.orange,
                fontSize:   12,
                fontWeight: FontWeight.w600,
                height:     1.4,
              ),
            ),
          ),
        ]),
      );

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final sColor = _statusColor();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
          stops:  [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -20, child: _blob(110, Colors.white, 0.05)),
        Positioned(bottom: -14, left: -20, child: _blob(80, _T.accent, 0.12)),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Row(children: [
              _headerBtn(onTap: _safePop,
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16)),
              const SizedBox(width: 12),
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color:  Colors.white.withOpacity(0.18),
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.35), width: 1.5),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Case #${widget.emergencyId}",
                        style: const TextStyle(
                          color:         Colors.white,
                          fontSize:      16,
                          fontWeight:    FontWeight.w800,
                          letterSpacing: -0.2,
                        )),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                            color: sColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(_statusLabel(),
                          style: TextStyle(
                            color:      Colors.white.withOpacity(0.75),
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                          )),
                      if (_isRecording) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:        _T.red.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text("● REC",
                              style: TextStyle(
                                color:      _T.red,
                                fontSize:   9,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                      ],
                      if (_isUploading) ...[
                        const SizedBox(width: 8),
                        Text("Uploading…",
                            style: TextStyle(
                              color:      Colors.white.withOpacity(0.6),
                              fontSize:   10,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ]),
                  ],
                ),
              ),
              _headerBtn(onTap: _openCallOrExplain,
                child: const Icon(Icons.videocam_rounded,
                    color: Colors.white, size: 18)),
              const SizedBox(width: 8),
              _headerBtn(onTap: _connectSocket,
                child: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _headerBtn({required VoidCallback onTap, required Widget child}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.11),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: child,
        ),
      );

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(opacity)));

  Widget _buildSplash() => const Center(
        child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2.5));

  Widget _buildBgPattern() => IgnorePointer(
        child: Opacity(
          opacity: 0.04,
          child: CustomPaint(
            painter: _BgPatternPainter(),
            size: Size.infinite,
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color:        _T.accentSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: _T.primary, size: 30),
          ),
          const SizedBox(height: 16),
          const Text("No messages yet",
              style: TextStyle(
                color:      _T.textDark,
                fontWeight: FontWeight.w800,
                fontSize:   16,
              )),
          const SizedBox(height: 6),
          Text(
            _status == "ready"
                ? _isChatEnabled
                    ? "Send a message or voice note."
                    : "Waiting for a responder to open chat…"
                : "Connecting to chat…",
            style: const TextStyle(color: _T.textMid, fontSize: 13),
          ),
        ]),
      );

  Widget _buildMessageList() => ListView.builder(
        controller: _scrollCtrl,
        padding:    const EdgeInsets.fromLTRB(14, 16, 14, 16),
        itemCount:  _messages.length,
        itemBuilder: (context, i) {
          final msg    = _messages[i];
          final key    = msg["id"] ?? i;
          final sentAt = _parseTime(msg);
          return _ChatBubble(
            isMe:         _isMe(msg),
            time:         sentAt == null ? "" : _formatTime(sentAt.toLocal()),
            isAudio:      _isAudio(msg),
            text:         (msg["text"] ?? "").toString(),
            isPlaying:    _playingKey == key,
            onPlayToggle: _isAudio(msg) ? () => _togglePlay(msg, key) : null,
          );
        },
      );

  Widget _buildInputBar({required bool canType, required bool sendEnabled}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color:  _T.surface,
        border: const Border(top: BorderSide(color: _T.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color:      _T.primary.withOpacity(0.04),
            blurRadius: 12,
            offset:     const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          GestureDetector(
            onTap: (canType || _isRecording) && !_isUploading
                ? _toggleRecord
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _isRecording ? _T.red : _T.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isRecording ? Colors.white : _T.primary,
                size:  20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:        _T.bg,
                borderRadius: BorderRadius.circular(24),
                border:       Border.all(color: _T.divider, width: 1),
              ),
              child: TextField(
                controller: _msgCtrl,
                enabled:    canType,
                minLines:   1,
                maxLines:   5,
                style: const TextStyle(
                    color: _T.textDark, fontSize: 14, height: 1.4),
                decoration: InputDecoration(
                  hintText: _isRecording
                      ? "Recording… tap stop to send"
                      : _isUploading
                          ? "Uploading audio…"
                          : !_isChatEnabled
                              ? "Waiting for responder to open chat…"
                              : canType
                                  ? "Type a message…"
                                  : "Connecting…",
                  hintStyle:      const TextStyle(color: _T.textMid, fontSize: 14),
                  border:         InputBorder.none,
                  isDense:        true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sendEnabled ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: sendEnabled
                    ? const LinearGradient(
                        colors: [_T.primary, _T.primaryMid],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      )
                    : null,
                color:     sendEnabled ? null : _T.divider,
                shape:     BoxShape.circle,
                boxShadow: sendEnabled
                    ? [BoxShadow(
                        color:      _T.primary.withOpacity(0.30),
                        blurRadius: 12,
                        offset:     const Offset(0, 4),
                      )]
                    : [],
              ),
              child: Icon(Icons.send_rounded,
                  color: sendEnabled ? Colors.white : _T.textMid,
                  size:  20),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Chat Bubble ──────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final bool          isMe;
  final String        time;
  final bool          isAudio;
  final String        text;
  final bool          isPlaying;
  final VoidCallback? onPlayToggle;

  const _ChatBubble({
    required this.isMe,
    required this.time,
    required this.isAudio,
    required this.text,
    required this.isPlaying,
    required this.onPlayToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? _T.bubbleMe    : _T.bubbleThem;
    final textColor   = isMe ? Colors.white   : _T.textDark;
    final metaColor   = isMe ? Colors.white60 : _T.textMid;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin:      const EdgeInsets.symmetric(vertical: 4),
        padding:     const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(20),
            topRight:    const Radius.circular(20),
            bottomLeft:  Radius.circular(isMe ? 20 : 5),
            bottomRight: Radius.circular(isMe ? 5  : 20),
          ),
          border: isMe ? null : Border.all(color: _T.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color:      _T.primary.withOpacity(isMe ? 0.22 : 0.05),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAudio)
              Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                  onTap: onPlayToggle,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white.withOpacity(0.18)
                          : _T.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isMe ? Colors.white : _T.primary,
                      size:  22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WaveformBars(color: isMe ? Colors.white : _T.accent),
                      const SizedBox(height: 4),
                      Text("Voice message",
                          style: TextStyle(
                            fontSize:   11,
                            color:      metaColor,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ])
            else
              Text(text,
                  style: TextStyle(
                    color:      textColor,
                    fontSize:   15,
                    height:     1.35,
                    fontWeight: FontWeight.w500,
                  )),
            const SizedBox(height: 5),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (time.isNotEmpty)
                Text(time,
                    style: TextStyle(
                      color:      metaColor,
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                    )),
              if (isMe) ...[
                const SizedBox(width: 5),
                Icon(Icons.done_all_rounded,
                    size: 13, color: Colors.white.withOpacity(0.8)),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Waveform Bars ────────────────────────────────────────────────────────────
class _WaveformBars extends StatelessWidget {
  final Color color;
  final int   bars;

  const _WaveformBars({required this.color, this.bars = 22});

  @override
  Widget build(BuildContext context) {
    final heights = List<double>.generate(
      bars,
      (i) => i % 5 == 0 ? 0.85 : i % 3 == 0 ? 0.65 : 0.45,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final h in heights)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 3,
              height: 18 * h,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Background Pattern Painter ───────────────────────────────────────────────
class _BgPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = _T.primary
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 48.0;
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        final r = Rect.fromCenter(
            center: Offset(x, y), width: 14, height: 14);
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(4)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}