import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Audio
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

// Call
import '../../services/call_services.dart';
import '../call/call_page.dart';

class ChatPage extends StatefulWidget {
  final int emergencyId;
  final String token; // citizen/user JWT (may or may not already include Bearer)
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

class _ChatPageState extends State<ChatPage> {
  // Use your LAN IP on real devices (NOT localhost)
  final String serverUrl = "http://localhost:5000";

  IO.Socket? socket;

  bool _isLoading = true;
  String _status = "idle"; // idle|connecting|ready|error
  bool _isComposing = false;

  // Recording / upload
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploadingAudio = false;

  // Audio playback
  final AudioPlayer _player = AudioPlayer();
  dynamic _playingKey; // msg id if present, else list index

  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _cleanToken {
    final t = widget.token.trim();
    return t.startsWith("Bearer ") ? t.substring(7) : t;
  }

  String _absoluteMediaUrl(String relativeOrAbsolute) {
    if (relativeOrAbsolute.startsWith("http")) return relativeOrAbsolute;
    return "$serverUrl$relativeOrAbsolute";
  }

  @override
  void initState() {
    super.initState();

    // Call socket should be online so incoming call can pop ANYWHERE
    CallService.I.connect(apiBaseUrl: serverUrl, token: _cleanToken);
    CallService.I.ensureConnected();

    _initializeChat();

    _messageController.addListener(() {
      final next = _messageController.text.trim().isNotEmpty;
      if (next == _isComposing) return;
      if (!mounted) return;
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

    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isLoading = true;
        _status = "connecting";
      });

      final res = await http.get(
        Uri.parse("$serverUrl/api/message/${widget.emergencyId}"),
        headers: {
          "Authorization": "Bearer $_cleanToken",
          "Content-Type": "application/json",
        },
      );

      final body = jsonDecode(res.body);

      if (res.statusCode != 200 || body["success"] != true) {
        _showError(
          body["message"]?.toString() ?? "Failed to load chat history",
        );
        setState(() => _status = "error");
        return;
      }

      final list = (body["data"] as List<dynamic>? ?? []);
      final mapped = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(mapped);
      });

      _connectSocket();
      _scrollToBottom(force: true);
    } catch (e) {
      debugPrint("Init Error: $e");
      if (!mounted) return;
      setState(() => _status = "error");
      _showError("Could not reach server. Check backend and CORS settings.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      socket!.emit("join_emergency", widget.emergencyId); // legacy
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

    socket!.onConnectError((err) {
      if (!mounted) return;
      setState(() => _status = "error");
      _showError("Socket connection failed. Please login again.");
    });

    socket!.connect();
  }

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

  // =========================
  // VIDEO ICON: open current ringing call for this emergency
  // (responder initiates; user only answers)
  // =========================
  void _openPendingCallOrExplain() {
    final invite = CallService.I.pendingInvite;
    if (invite != null && invite.emergencyId == widget.emergencyId) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => CallPage(invite: invite),
        ),
      );
      return;
    }

    _showError(
      "No incoming call right now. Wait for the responder to start the call.",
    );
  }

  // =========================
  // AUDIO: RECORD + UPLOAD + SEND
  // =========================

  Future<void> _toggleRecord() async {
    if (_status != "ready") {
      _showError("Chat not connected yet.");
      return;
    }
    if (_isUploadingAudio) return;

    if (_isRecording) {
      await _stopRecordingAndSend();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final ok = await _recorder.hasPermission();
    if (!ok) {
      _showError("Microphone permission denied.");
      return;
    }

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path:
            "bahirlink_${widget.emergencyId}_${DateTime.now().millisecondsSinceEpoch}.m4a",
      );

      if (!mounted) return;
      setState(() => _isRecording = true);
    } catch (e) {
      _showError("Failed to start recording: $e");
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() => _isRecording = false);

      if (path != null && path.isNotEmpty) {
        await _uploadAudioFromPath(path);
        return;
      }

      _showError(
        "Recording finished but no file path returned (Web). "
        "Run on Android/iOS or switch to record.startStream().",
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      _showError("Failed to stop recording: $e");
    }
  }

  Future<void> _uploadAudioFromPath(String path) async {
    try {
      setState(() => _isUploadingAudio = true);

      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$serverUrl/api/message/audio"),
      );

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

      if (!mounted) return;
      setState(() => _messages.add(saved));
      _scrollToBottom();
    } catch (e) {
      _showError("Failed to upload audio: $e");
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
    }
  }

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

  // =========================
  // UI helpers (Telegram-ish)
  // =========================

  Color _statusColor() {
    switch (_status) {
      case "ready":
        return const Color(0xFF22C55E);
      case "connecting":
        return const Color(0xFFFB923C);
      case "error":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _statusLabel() {
    switch (_status) {
      case "ready":
        return "online";
      case "connecting":
        return "connecting…";
      case "error":
        return "offline";
      default:
        return "idle";
    }
  }

  DateTime? _tryParseMessageTime(Map<String, dynamic> msg) {
    final raw = msg["createdAt"] ?? msg["created_at"] ?? msg["timestamp"] ?? msg["time"];
    if (raw == null) return null;
    if (raw is int) {
      if (raw > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    return DateTime.tryParse(raw.toString());
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final hh = ((h + 11) % 12) + 1;
    final mm = dt.minute.toString().padLeft(2, "0");
    final ap = h >= 12 ? "PM" : "AM";
    return "$hh:$mm $ap";
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scrollToBottom({bool force = false}) {
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!_scrollController.hasClients) return;
      if (force) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isMe(Map<String, dynamic> msg) {
    return (msg["senderType"] == "user") && (msg["senderId"] == widget.userId);
  }

  bool _isAudioMsg(Map<String, dynamic> msg) {
    return (msg["messageType"]?.toString() == "audio") ||
        (msg["audioUrl"] != null && msg["audioUrl"].toString().isNotEmpty);
  }

  Widget _bgPattern() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.06,
        child: CustomPaint(
          painter: _TelegramBgPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final canType = _status == "ready" && !_isRecording && !_isUploadingAudio;
    final sendEnabled = canType && _isComposing;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF2F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        surfaceTintColor: Colors.white,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF24A1DE), Color(0xFF2B9DF0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.shield_rounded, size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Case #${widget.emergencyId}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_isUploadingAudio) ...[
                        const SizedBox(width: 8),
                        const Text(
                          "• uploading audio…",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (_isRecording) ...[
                        const SizedBox(width: 8),
                        const Text(
                          "• recording…",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Video call",
            onPressed: _openPendingCallOrExplain,
            icon: const Icon(Icons.videocam_rounded, color: Color(0xFF24A1DE)),
          ),
          IconButton(
            tooltip: "Reconnect",
            onPressed: _connectSocket,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _bgPattern()),
                      _messages.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final mine = _isMe(msg);
                                final isAudio = _isAudioMsg(msg);
                                final sentAt = _tryParseMessageTime(msg);
                                final time = sentAt == null ? "" : _formatTime(sentAt.toLocal());

                                final key = msg["id"] ?? index;
                                final playing = _playingKey == key;

                                return _TelegramBubble(
                                  isMe: mine,
                                  time: time,
                                  isAudio: isAudio,
                                  text: (msg["text"] ?? "").toString(),
                                  isPlaying: playing,
                                  onPlayToggle: isAudio ? () => _togglePlay(msg, key) : null,
                                );
                              },
                            ),
                    ],
                  ),
                ),
                if (_isUploadingAudio)
                  const LinearProgressIndicator(minHeight: 2, color: Color(0xFF24A1DE)),
                _inputBar(
                  canType: canType,
                  sendEnabled: sendEnabled,
                ),
              ],
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF334155), size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              "No messages yet",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _status == "ready" ? "Send a message or voice note." : "Connecting…",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar({required bool canType, required bool sendEnabled}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: (canType && !_isUploadingAudio) ? _toggleRecord : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _isRecording ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: TextField(
                  controller: _messageController,
                  enabled: canType,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: canType
                        ? (_isRecording
                            ? "Recording… tap stop to send"
                            : _isUploadingAudio
                                ? "Uploading audio…"
                                : "Message")
                        : "Connecting…",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: sendEnabled ? _sendMessage : null,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: sendEnabled ? const Color(0xFF24A1DE) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (sendEnabled ? const Color(0xFF24A1DE) : const Color(0xFFE2E8F0))
                          .withOpacity(sendEnabled ? 0.35 : 0.0),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: sendEnabled ? Colors.white : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelegramBubble extends StatelessWidget {
  final bool isMe;
  final String time;
  final bool isAudio;
  final String text;
  final bool isPlaying;
  final VoidCallback? onPlayToggle;

  const _TelegramBubble({
    required this.isMe,
    required this.time,
    required this.isAudio,
    required this.text,
    required this.isPlaying,
    required this.onPlayToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isMe ? Colors.white : const Color(0xFF0F172A);
    final metaColor = isMe ? Colors.white70 : const Color(0xFF64748B);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAudio)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onPlayToggle,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isMe ? Colors.white : const Color(0xFF24A1DE)).withOpacity(isMe ? 0.18 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: isMe ? Colors.white : const Color(0xFF24A1DE),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WaveformBars(color: isMe ? Colors.white : const Color(0xFF24A1DE)),
                        const SizedBox(height: 4),
                        Text(
                          "Voice message",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      color: metaColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.done_all_rounded, size: 14, color: Colors.white.withOpacity(0.85)),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  final Color color;
  final int bars;

  const _WaveformBars({required this.color, this.bars = 22});

  @override
  Widget build(BuildContext context) {
    final heights = List<double>.generate(
      bars,
      (i) => (i % 5 == 0) ? 0.85 : (i % 3 == 0) ? 0.65 : 0.45,
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
                color: color.withOpacity(0.85),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _TelegramBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF24A1DE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 46.0;
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        final r = Rect.fromCenter(center: Offset(x, y), width: 16, height: 16);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}