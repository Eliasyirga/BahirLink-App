import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

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

class _ChatPageState extends State<ChatPage> {
  // Use your computer's local IP (e.g. 192.168.x.x) for physical devices!
  final String serverUrl = "http://localhost:5000";

  IO.Socket? socket;
  int? _chatId;
  bool _isLoading = true;
  bool _isPartnerTyping = false;
  String _partnerName = "Support";

  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 1. Initialize Chat & Fetch Metadata
  Future<void> _initializeChat() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/chat/emergency/${widget.emergencyId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded != null && decoded['data'] != null) {
          setState(() {
            _chatId = decoded['data']['id'];
          });
          // Connect socket ONLY after we have the chatId
          _connectSocket();
          _fetchHistory();
        }
      }
    } catch (e) {
      debugPrint("Init Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 2. Fetch History
  Future<void> _fetchHistory() async {
    if (_chatId == null) return;
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/message/$_chatId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            _messages.clear(); // Avoid duplicates on reconnect
            _messages.addAll(List<Map<String, dynamic>>.from(decoded['data']));
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint("History Error: $e");
    }
  }

  /// 3. Socket Setup with Connection Verification
  void _connectSocket() {
    if (_chatId == null) return;

    socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': widget.token})
          .enableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      debugPrint("✅ Flutter connected to Socket");
      socket!.emit('joinChat', _chatId);
    });

    socket!.on('newMessage', (data) {
      if (mounted) {
        setState(() => _messages.add(data));
        _scrollToBottom();
      }
    });

    socket!.on('userTyping', (data) {
      if (mounted && data['chatId'] == _chatId) {
        setState(() {
          _isPartnerTyping = data['isTyping'];
          _partnerName = data['user']['name'] ?? "Responder";
        });
      }
    });

    socket!.onConnectError((err) => debugPrint("❌ Connection Error: $err"));
  }

  void _onTypingChanged(String text) {
    if (socket != null && socket!.connected) {
      socket!.emit('typing', {
        'chatId': _chatId,
        'isTyping': text.isNotEmpty,
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    // Add logging to debug in VS Code/Android Studio console
    debugPrint(
        "Attempting to send message. Socket Connected: ${socket?.connected}");

    if (text.isEmpty ||
        socket == null ||
        !socket!.connected ||
        _chatId == null) {
      if (socket != null && !socket!.connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connecting to server... please wait")),
        );
      }
      return;
    }

    final payload = {
      'chatId': _chatId,
      'message': text,
    };

    socket!.emit('sendMessage', payload);

    socket!.emit('typing', {'chatId': _chatId, 'isTyping': false});
    _messageController.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... (Keep the build method from your previous snippet, it was UI-perfect)
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Emergency Response",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_isPartnerTyping)
              Text("$_partnerName is typing...",
                  style: const TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['senderId'] == widget.userId;
                      return _buildMessageBubble(msg['message'] ?? "", isMe);
                    },
                  ),
                ),
                _buildInputArea(),
              ],
            ),
    );
  }

  // ... (Keep _buildMessageBubble and _buildInputArea as they were)
  Widget _buildMessageBubble(String content, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          content,
          style: TextStyle(
              color: isMe ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                onChanged: _onTypingChanged,
                decoration: InputDecoration(
                  hintText: "Type message...",
                  filled: true,
                  fillColor: const Color(0xFFF1F3F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: const CircleAvatar(
                backgroundColor: Color(0xFF1E88E5),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
