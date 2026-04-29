import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Audio
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

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
  final String serverUrl = "http://localhost:5000";

  IO.Socket? socket;

  bool _isLoading = true;
  String _status = "idle"; // idle|connecting|ready|error
  bool _isComposing = false;

  // Recording / upload
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploadingAudio = false;

  // Audio playback (single player is enough)
  final AudioPlayer _player = AudioPlayer();
  int? _playingMessageId;

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

    _initializeChat();

    _messageController.addListener(() {
      final next = _messageController.text.trim().isNotEmpty;
      if (next == _isComposing) return;
      if (!mounted) return;
      setState(() => _isComposing = next);
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playingMessageId = null);
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
        _showError(body["message"]?.toString() ?? "Failed to load chat history");
        setState(() => _status = "error");
        return;
      }

      final list = (body["data"] as List<dynamic>? ?? []);
      final mapped =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();

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
      // record package stores internally (web uses browser recording)
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

      // On web, `path` can be null; record supports `stop()` returning a path on mobile.
      // We handle both by using record's `stop()` result if present, else fallback to bytes.
      if (path != null && path.isNotEmpty) {
        await _uploadAudioFromPath(path);
        return;
      }

      // Web fallback: getBytes() only available if you used startStream (not used here),
      // so we show a clear message if path is not returned.
      _showError(
        "Recording finished but no file path returned (Web). "
        "If this happens, run on Android/iOS or switch to record.startStream().",
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

      // realtime notify responder
      final audioUrl = saved["audioUrl"]?.toString();
      if (audioUrl != null && socket != null && socket!.connected) {
        socket!.emit("chat:send", {
          "emergencyId": widget.emergencyId,
          "audioUrl": audioUrl,
        });
      }

      // add locally too
      if (!mounted) return;
      setState(() => _messages.add(saved));
      _scrollToBottom();
    } catch (e) {
      _showError("Failed to upload audio: $e");
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
    }
  }

  Future<void> _togglePlay(Map<String, dynamic> msg) async {
    final id = msg["id"];
    final audioUrl = msg["audioUrl"]?.toString();
    if (audioUrl == null || audioUrl.isEmpty) return;

    final src = _absoluteMediaUrl(audioUrl);

    try {
      if (_playingMessageId == id) {
        await _player.pause();
        if (mounted) setState(() => _playingMessageId = null);
        return;
      }

      await _player.stop();
      await _player.play(UrlSource(src));
      if (mounted) setState(() => _playingMessageId = id is int ? id : null);
    } catch (e) {
      _showError("Audio playback failed: $e");
    }
  }

  // =========================
  // UI helpers
  // =========================

  Color _statusColor(ThemeData theme) {
    switch (_status) {
      case "ready":
        return const Color(0xFF16A34A);
      case "connecting":
        return const Color(0xFF2563EB);
      case "error":
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _statusLabel() {
    switch (_status) {
      case "ready":
        return "Connected";
      case "connecting":
        return "Connecting…";
      case "error":
        return "Connection issue";
      default:
        return "Idle";
    }
  }

  DateTime? _tryParseMessageTime(Map<String, dynamic> msg) {
    final raw =
        msg["createdAt"] ?? msg["created_at"] ?? msg["timestamp"] ?? msg["time"];
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _scrollToBottom({bool force = false}) {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!_scrollController.hasClients) return;
      if (force) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme);

    final canType = _status == "ready" && !_isRecording && !_isUploadingAudio;
    final sendEnabled = canType && _isComposing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE2E8F0),
              child: Icon(
                Icons.support_agent_rounded,
                color: const Color(0xFF0F172A).withOpacity(0.85),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Incident Support",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isUploadingAudio)
                        const Text(
                          "• uploading audio…",
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      if (_isRecording)
                        const Text(
                          "• recording…",
                          style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w700),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        "• #${widget.emergencyId}",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Reconnect",
            onPressed: _connectSocket,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                      ),
                    ),
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final mine = _isMe(msg);
                              final sentAt = _tryParseMessageTime(msg);
                              return _buildMessageBubble(
                                msg: msg,
                                isMe: mine,
                                sentAt: sentAt,
                              );
                            },
                          ),
                  ),
                ),
                _buildInputArea(
                  canType: canType,
                  sendEnabled: sendEnabled,
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 14),
            Text(
              "Start the conversation",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _status == "ready"
                  ? "Send a message or a voice note."
                  : "Connecting you to a responder…",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required Map<String, dynamic> msg,
    required bool isMe,
    required DateTime? sentAt,
  }) {
    final theme = Theme.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    final bubbleColor = isMe ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isMe ? Colors.white : const Color(0xFF0F172A);
    final metaColor = isMe ? Colors.white70 : const Color(0xFF64748B);

    final isAudio = _isAudioMsg(msg);
    final id = msg["id"];
    final playing = (_playingMessageId != null && _playingMessageId == id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE2E8F0),
              child: Icon(
                Icons.shield_rounded,
                size: 16,
                color: const Color(0xFF0F172A).withOpacity(0.75),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isMe ? const Radius.circular(6) : null,
                  bottomLeft: !isMe ? const Radius.circular(6) : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAudio) ...[
                      Row(
                        children: [
                          Icon(Icons.mic_rounded, color: textColor.withOpacity(0.95), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Voice message",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _togglePlay(msg),
                            icon: Icon(
                              playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                              color: isMe ? Colors.white : const Color(0xFF0F172A),
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SelectableText(
                        (msg["text"] ?? "").toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          sentAt == null ? "" : _formatTime(sentAt.toLocal()),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: metaColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF0F172A),
              child: Icon(Icons.person_rounded, size: 16, color: Colors.white.withOpacity(0.95)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea({
    required bool canType,
    required bool sendEnabled,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // MIC button (tap to start, tap again to stop + send)
            IconButton(
              tooltip: _isRecording ? "Stop & Send" : "Record audio",
              onPressed: (canType && !_isUploadingAudio) ? _toggleRecord : null,
              icon: Icon(
                _isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                color: _isRecording ? Colors.red : const Color(0xFF334155),
              ),
            ),

            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: canType,
                decoration: InputDecoration(
                  hintText: canType
                      ? (_isRecording
                          ? "Recording… tap stop to send"
                          : _isUploadingAudio
                              ? "Uploading audio…"
                              : "Send a message…")
                      : "Connecting to responder…",
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                minLines: 1,
                maxLines: 5,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: sendEnabled ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: sendEnabled ? _sendMessage : null,
                  child: Icon(
                    Icons.send_rounded,
                    color: sendEnabled ? Colors.white : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}