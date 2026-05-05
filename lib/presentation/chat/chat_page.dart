import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Audio
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

// Call
import '../../services/call_services.dart';
import '../call/call_page.dart';

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

  // Chat-specific
  static const bubbleMe   = Color(0xFF1A3BAA);
  static const bubbleThem = Color(0xFFFFFFFF);
  static const chatBg     = Color(0xFFF0F5FF);
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class ChatPage extends StatefulWidget {
  final int emergencyId;
  final String token;
  final int userId;

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
  final String serverUrl = "http://localhost:5000";

  IO.Socket? socket;

  bool _isLoading = true;
  String _status = "idle";
  bool _isComposing = false;

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploadingAudio = false;

  final AudioPlayer _player = AudioPlayer();
  dynamic _playingKey;

  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  // ── Token ─────────────────────────────────────────────────────────────────
  String get _cleanToken {
    final t = widget.token.trim();
    return t.startsWith("Bearer ") ? t.substring(7) : t;
  }

  String _absoluteMediaUrl(String url) =>
      url.startsWith("http") ? url : "$serverUrl$url";

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    CallService.I.connect(apiBaseUrl: serverUrl, token: _cleanToken);
    CallService.I.ensureConnected();
    _initializeChat();

    _messageController.addListener(() {
      final next = _messageController.text.trim().isNotEmpty;
      if (next == _isComposing || !mounted) return;
      setState(() => _isComposing = next);
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playingKey = null);
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _player.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> _initializeChat() async {
    try {
      setState(() { _isLoading = true; _status = "connecting"; });

      final res = await http.get(
        Uri.parse("$serverUrl/api/message/${widget.emergencyId}"),
        headers: {
          "Authorization": "Bearer $_cleanToken",
          "Content-Type": "application/json",
        },
      );

      final body = jsonDecode(res.body);
      if (res.statusCode != 200 || body["success"] != true) {
        _showError(body["message"]?.toString() ?? "Failed to load chat history");
        setState(() => _status = "error");
        return;
      }

      final list = (body["data"] as List<dynamic>? ?? []);
      final mapped = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (!mounted) return;
      setState(() { _messages..clear()..addAll(mapped); });
      _connectSocket();
      _scrollToBottom(force: true);
      _fadeCtrl.forward();
    } catch (e) {
      debugPrint("Init Error: $e");
      if (!mounted) return;
      setState(() => _status = "error");
      _showError("Could not reach server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Socket ────────────────────────────────────────────────────────────────
  void _connectSocket() {
    socket?.disconnect();
    socket?.dispose();

    socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(["websocket"])
          .setAuth({"token": "Bearer $_cleanToken"})
          .disableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      if (!mounted) return;
      setState(() => _status = "ready");
      socket!.emit("chat:join", {"emergencyId": widget.emergencyId});
      socket!.emit("join_emergency", widget.emergencyId);
    });

    void onIncoming(dynamic data) {
      try {
        final msg = Map<String, dynamic>.from(data as Map);
        if (!mounted) return;
        setState(() => _messages.add(msg));
        _scrollToBottom();
      } catch (e) {
        debugPrint("Bad message payload: $e");
      }
    }

    socket!.on("chat:new", onIncoming);
    socket!.on("receive_message", onIncoming);
    socket!.on("error_alert", (e) {
      final msg = (e is Map && e["message"] != null)
          ? e["message"].toString()
          : e.toString();
      _showError(msg);
    });
    socket!.onConnectError((_) {
      if (!mounted) return;
      setState(() => _status = "error");
      _showError("Socket connection failed.");
    });

    socket!.connect();
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final s = socket;
    if (s == null || !s.connected) {
      _showError("Not connected to chat.");
      return;
    }
    s.emit("chat:send", {"emergencyId": widget.emergencyId, "text": text});
    _messageController.clear();
    _scrollToBottom();
  }

  // ── Video call ─────────────────────────────────────────────────────────────
  void _openPendingCallOrExplain() {
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

  // ── Audio recording ────────────────────────────────────────────────────────
  Future<void> _toggleRecord() async {
    if (_status != "ready") { _showError("Chat not connected yet."); return; }
    if (_isUploadingAudio) return;
    _isRecording ? await _stopRecordingAndSend() : await _startRecording();
  }

  Future<void> _startRecording() async {
    final ok = await _recorder.hasPermission();
    if (!ok) { _showError("Microphone permission denied."); return; }
    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: "bahirlink_${widget.emergencyId}_${DateTime.now().millisecondsSinceEpoch}.m4a",
      );
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      _showError("Failed to start recording: $e");
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final path = await _recorder.stop();
      if (mounted) setState(() => _isRecording = false);
      if (path != null && path.isNotEmpty) {
        await _uploadAudioFromPath(path);
      } else {
        _showError("Recording finished but no file path returned.");
      }
    } catch (e) {
      if (mounted) setState(() => _isRecording = false);
      _showError("Failed to stop recording: $e");
    }
  }

  Future<void> _uploadAudioFromPath(String path) async {
    try {
      setState(() => _isUploadingAudio = true);
      final req = http.MultipartRequest("POST",
          Uri.parse("$serverUrl/api/message/audio"));
      req.headers["Authorization"] = "Bearer $_cleanToken";
      req.fields["emergencyId"] = widget.emergencyId.toString();
      req.files.add(await http.MultipartFile.fromPath("audio", path));

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body);

      if (res.statusCode != 201 || body["success"] != true) {
        _showError(body["message"]?.toString() ?? "Audio upload failed");
        return;
      }

      final saved = Map<String, dynamic>.from(body["data"]);
      final audioUrl = saved["audioUrl"]?.toString();
      if (audioUrl != null && socket != null && socket!.connected) {
        socket!.emit("chat:send", {
          "emergencyId": widget.emergencyId,
          "audioUrl": audioUrl,
        });
      }
      if (mounted) setState(() => _messages.add(saved));
      _scrollToBottom();
    } catch (e) {
      _showError("Failed to upload audio: $e");
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
    }
  }

  // ── Audio playback ─────────────────────────────────────────────────────────
  Future<void> _togglePlay(Map<String, dynamic> msg, dynamic key) async {
    final audioUrl = msg["audioUrl"]?.toString();
    if (audioUrl == null || audioUrl.isEmpty) return;
    final src = _absoluteMediaUrl(audioUrl);
    try {
      if (_playingKey == key) {
        await _player.pause();
        if (mounted) setState(() => _playingKey = null);
        return;
      }
      await _player.stop();
      await _player.play(UrlSource(src));
      if (mounted) setState(() => _playingKey = key);
    } catch (e) {
      _showError("Audio playback failed: $e");
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _statusColor() {
    switch (_status) {
      case "ready":     return _T.green;
      case "connecting":return _T.orange;
      case "error":     return _T.red;
      default:          return _T.textMid;
    }
  }

  String _statusLabel() {
    switch (_status) {
      case "ready":     return "Online";
      case "connecting":return "Connecting…";
      case "error":     return "Offline";
      default:          return "Idle";
    }
  }

  DateTime? _tryParseMessageTime(Map<String, dynamic> msg) {
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
    final h = dt.hour;
    final hh = ((h + 11) % 12) + 1;
    final mm = dt.minute.toString().padLeft(2, "0");
    return "$hh:$mm ${h >= 12 ? 'PM' : 'AM'}";
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _T.textDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _scrollToBottom({bool force = false}) {
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!_scrollController.hasClients) return;
      force
          ? _scrollController.jumpTo(_scrollController.position.maxScrollExtent)
          : _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut);
    });
  }

  bool _isMe(Map<String, dynamic> msg) =>
      msg["senderType"] == "user" && msg["senderId"] == widget.userId;

  bool _isAudioMsg(Map<String, dynamic> msg) =>
      msg["messageType"]?.toString() == "audio" ||
      (msg["audioUrl"] != null && msg["audioUrl"].toString().isNotEmpty);

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final canType = _status == "ready" && !_isRecording && !_isUploadingAudio;
    final sendEnabled = canType && _isComposing;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.chatBg,
        body: Column(children: [
          _buildHeader(context),
          if (_isUploadingAudio)
            LinearProgressIndicator(
              minHeight: 2,
              color: _T.accent,
              backgroundColor: _T.accentSoft,
            ),
          Expanded(
            child: _isLoading
                ? _buildSplash()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: Stack(children: [
                      Positioned.fill(child: _buildBgPattern()),
                      _messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final mine = _isMe(msg);
                                final isAudio = _isAudioMsg(msg);
                                final sentAt = _tryParseMessageTime(msg);
                                final time = sentAt == null
                                    ? ""
                                    : _formatTime(sentAt.toLocal());
                                final key = msg["id"] ?? index;
                                return _ChatBubble(
                                  isMe: mine,
                                  time: time,
                                  isAudio: isAudio,
                                  text: (msg["text"] ?? "").toString(),
                                  isPlaying: _playingKey == key,
                                  onPlayToggle:
                                      isAudio ? () => _togglePlay(msg, key) : null,
                                );
                              },
                            ),
                    ]),
                  ),
          ),
          _buildInputBar(canType: canType, sendEnabled: sendEnabled),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final sColor = _statusColor();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2580), _T.primary, _T.primaryMid],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
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
              // Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.35), width: 1.5),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),

              // Title + status
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text("Case #${widget.emergencyId}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                            color: sColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(_statusLabel(),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    if (_isRecording) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: _T.red.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text("● REC",
                            style: TextStyle(
                                color: _T.red,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                    if (_isUploadingAudio) ...[
                      const SizedBox(width: 8),
                      Text("Uploading…",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ]),
              ),

              // Actions
              GestureDetector(
                onTap: _openPendingCallOrExplain,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(Icons.videocam_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _connectSocket,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(opacity)));

  // ── Splash ────────────────────────────────────────────────────────────────
  Widget _buildSplash() {
    return const Center(
      child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2.5),
    );
  }

  // ── Background pattern ────────────────────────────────────────────────────
  Widget _buildBgPattern() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.04,
        child: CustomPaint(
          painter: _BgPatternPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: _T.accentSoft,
              borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: _T.primary, size: 30),
        ),
        const SizedBox(height: 16),
        const Text("No messages yet",
            style: TextStyle(
                color: _T.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          _status == "ready"
              ? "Send a message or voice note."
              : "Connecting to chat…",
          style: const TextStyle(color: _T.textMid, fontSize: 13),
        ),
      ]),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar({required bool canType, required bool sendEnabled}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border(top: BorderSide(color: _T.divider, width: 1)),
        boxShadow: [
          BoxShadow(
              color: _T.primary.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          // Mic
          GestureDetector(
            onTap: (canType && !_isUploadingAudio) ? _toggleRecord : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _isRecording
                    ? _T.red
                    : _T.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isRecording ? Colors.white : _T.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _T.bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _T.divider, width: 1),
              ),
              child: TextField(
                controller: _messageController,
                enabled: canType,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(
                    color: _T.textDark, fontSize: 14, height: 1.4),
                decoration: InputDecoration(
                  hintText: _isRecording
                      ? "Recording… tap stop to send"
                      : _isUploadingAudio
                          ? "Uploading audio…"
                          : canType
                              ? "Type a message…"
                              : "Connecting…",
                  hintStyle: const TextStyle(
                      color: _T.textMid, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send
          GestureDetector(
            onTap: sendEnabled ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: sendEnabled
                    ? const LinearGradient(
                        colors: [_T.primary, _T.primaryMid],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: sendEnabled ? null : _T.divider,
                shape: BoxShape.circle,
                boxShadow: sendEnabled
                    ? [
                        BoxShadow(
                            color: _T.primary.withOpacity(0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ]
                    : [],
              ),
              child: Icon(Icons.send_rounded,
                  color: sendEnabled ? Colors.white : _T.textMid,
                  size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Chat Bubble ──────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final bool isMe;
  final String time;
  final bool isAudio;
  final String text;
  final bool isPlaying;
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
    final bubbleColor = isMe ? _T.bubbleMe : _T.bubbleThem;
    final textColor   = isMe ? Colors.white : _T.textDark;
    final metaColor   = isMe ? Colors.white60 : _T.textMid;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 20),
          ),
          border: isMe ? null : Border.all(color: _T.divider, width: 1),
          boxShadow: [
            BoxShadow(
                color: _T.primary.withOpacity(isMe ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _WaveformBars(
                      color: isMe ? Colors.white : _T.accent),
                  const SizedBox(height: 4),
                  Text("Voice message",
                      style: TextStyle(
                          fontSize: 11,
                          color: metaColor,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ])
          else
            Text(text,
                style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500)),

          const SizedBox(height: 5),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (time.isNotEmpty)
              Text(time,
                  style: TextStyle(
                      color: metaColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            if (isMe) ...[
              const SizedBox(width: 5),
              Icon(Icons.done_all_rounded,
                  size: 13, color: Colors.white.withOpacity(0.8)),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ─── Waveform Bars ────────────────────────────────────────────────────────────
class _WaveformBars extends StatelessWidget {
  final Color color;
  final int bars;

  const _WaveformBars({required this.color, this.bars = 22});

  @override
  Widget build(BuildContext context) {
    final heights = List<double>.generate(
        bars, (i) => (i % 5 == 0) ? 0.85 : (i % 3 == 0) ? 0.65 : 0.45);
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
                color: color.withOpacity(0.8),
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
      ..color = _T.primary
      ..style = PaintingStyle.stroke
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
