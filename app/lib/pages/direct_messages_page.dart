import 'dart:async';
import 'package:app/services/auth_service.dart';
import 'package:app/utils/constants.dart';
import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/material.dart';

class DirectMessagesPage extends StatefulWidget {
  const DirectMessagesPage({super.key});

  @override
  State<DirectMessagesPage> createState() => _DirectMessagesPageState();
}

class _DirectMessagesPageState extends State<DirectMessagesPage> {
  final ChatService _chatService = ChatPlugin.chatService;
  bool _isLoading = true;
  List<ChatRoom> _rooms = [];

  @override
  void initState() {
    super.initState();
    _registerEventListeners();
    _loadRooms();
  }

  void _registerEventListeners() {
    _chatService.addEventListener(
      ChatEventType.chatRoomsChanged,
      'direct_messages_rooms',
      (_) {
        if (!mounted) return;
        setState(() {
          _rooms = List.from(_chatService.chatRooms);
          _isLoading = false;
        });
      },
    );

    _chatService.addEventListener(
      ChatEventType.connectionStatusChanged,
      'direct_messages_conn',
      (isConnected) {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      await _chatService.loadChatRooms();
    } catch (_) {
      // Handled gracefully
    } finally {
      if (mounted) {
        setState(() {
          _rooms = List.from(_chatService.chatRooms);
          _isLoading = false;
        });
      }
    }
  }

  void _showNewChatDialog() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<dynamic>>(
          future: AuthService.fetchUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No other registered users found.\nRegister a second account to start chatting!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                    ),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New Conversation',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userId = (user['userId'] ?? user['_id'] ?? '').toString();
                        final username = (user['username'] ?? user['userName'] ?? 'User').toString();
                        final isOnline = user['isOnline'] == true;

                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFE5D5FF),
                                child: Text(
                                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: AppColor.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            username,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            isOnline ? 'Online' : 'Tap to start chat',
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatDetailPage(
                                  receiverId: userId,
                                  receiverName: username,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _chatService.removeEventListener(ChatEventType.chatRoomsChanged, 'direct_messages_rooms');
    _chatService.removeEventListener(ChatEventType.connectionStatusChanged, 'direct_messages_conn');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _chatService.isSocketConnected;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Messages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isConnected ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => AuthService.logoutUser(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRooms,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _rooms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start chatting by tapping the button below',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showNewChatDialog,
                            icon: const Icon(Icons.add_comment),
                            label: const Text('Start New Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _rooms.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      final name = room.username.isNotEmpty ? room.username : 'User';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFE5D5FF),
                          backgroundImage: room.avatarUrl != null && room.avatarUrl!.isNotEmpty
                              ? NetworkImage(room.avatarUrl!)
                              : null,
                          child: room.avatarUrl == null || room.avatarUrl!.isEmpty
                              ? Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColor.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        subtitle: Row(
                          children: [
                            if (room.latestMessageStatus != null) ...[
                              _buildStatusIcon(room.latestMessageStatus!),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                room.latestMessage.isEmpty
                                    ? 'Start a conversation'
                                    : room.latestMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: room.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                                  fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(room.latestMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: room.unreadCount > 0 ? AppColor.primaryColor : Colors.grey,
                                fontWeight: room.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (room.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColor.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  room.unreadCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailPage(
                                receiverId: room.userId,
                                receiverName: name,
                                avatarUrl: room.avatarUrl,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppColor.primaryColor,
        tooltip: 'New Conversation',
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return const Icon(Icons.check, size: 14, color: Colors.grey);
      case 'delivered':
        return const Icon(Icons.done_all, size: 14, color: Colors.grey);
      case 'read':
        return const Icon(Icons.done_all, size: 14, color: Colors.blue);
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day && time.month == now.month && time.year == now.year) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    final diff = now.difference(time);
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${time.day}/${time.month}/${time.year}';
  }
}

class ChatDetailPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? avatarUrl;

  const ChatDetailPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.avatarUrl,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> with WidgetsBindingObserver {
  final ChatService _chatService = ChatPlugin.chatService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  bool _isTyping = false;
  DateTime _lastTypingTime = DateTime.now();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerEventListeners();
    _initChat();
    _messageController.addListener(_onTextChanged);
  }

  void _registerEventListeners() {
    _chatService.addEventListener(
      ChatEventType.messagesChanged,
      'chat_screen_messages',
      (_) {
        if (!mounted) return;
        setState(() {
          _messages = List.from(_chatService.messages);
          _isLoading = false;
        });
        _scrollToBottom();
      },
    );

    _chatService.addEventListener(
      ChatEventType.typingStatusChanged,
      'chat_screen_typing',
      (_) {
        if (!mounted) return;
        setState(() {});
      },
    );

    _chatService.addEventListener(
      ChatEventType.onlineStatusChanged,
      'chat_screen_online',
      (_) {
        if (!mounted) return;
        setState(() {});
      },
    );

    _chatService.addEventListener(
      ChatEventType.messageStatusChanged,
      'chat_screen_status',
      (_) {
        if (!mounted) return;
        setState(() {
          _messages = List.from(_chatService.messages);
        });
      },
    );
  }

  Future<void> _initChat() async {
    setState(() => _isLoading = true);
    try {
      await _chatService.initChat(widget.receiverId);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _messages = List.from(_chatService.messages);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _onTextChanged() {
    final now = DateTime.now();
    _debounceTimer?.cancel();

    if (_messageController.text.trim().isNotEmpty) {
      if (!_isTyping || now.difference(_lastTypingTime).inSeconds >= 2) {
        _isTyping = true;
        _lastTypingTime = now;
        _chatService.sendTypingIndicator(true);
      }

      _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
        if (_isTyping) {
          _isTyping = false;
          _chatService.sendTypingIndicator(false);
        }
      });
    } else if (_messageController.text.trim().isEmpty && _isTyping) {
      _isTyping = false;
      _chatService.sendTypingIndicator(false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chatService.updateUserStatus(true);
    } else if (state == AppLifecycleState.paused) {
      _chatService.updateUserStatus(false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    _isTyping = false;
    _chatService.sendTypingIndicator(false);

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(text);
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();

    _chatService.removeEventListener(ChatEventType.messagesChanged, 'chat_screen_messages');
    _chatService.removeEventListener(ChatEventType.typingStatusChanged, 'chat_screen_typing');
    _chatService.removeEventListener(ChatEventType.onlineStatusChanged, 'chat_screen_online');
    _chatService.removeEventListener(ChatEventType.messageStatusChanged, 'chat_screen_status');

    _chatService.leaveChat(widget.receiverId);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _chatService.isReceiverOnline;
    final lastSeen = _chatService.lastSeen;
    final isTyping = _chatService.isReceiverTyping;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE5D5FF),
              backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Text(
                      widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isOnline
                        ? 'Online'
                        : lastSeen != null
                            ? 'Last seen ${_formatLastSeen(lastSeen)}'
                            : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.green : Colors.grey,
                      fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mark_chat_unread_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Say hello to ${widget.receiverName}!',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          // Real-time typing indicator
          if (isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColor.primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.receiverName} is typing...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Message input bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColor.primaryColor,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColor.primaryColor : const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatBubbleTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine ? Colors.white70 : Colors.black45,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _buildMessageStatus(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatus(String status) {
    switch (status) {
      case 'sent':
        return const Icon(Icons.check, size: 13, color: Colors.white70);
      case 'delivered':
        return const Icon(Icons.done_all, size: 13, color: Colors.white70);
      case 'read':
        return const Icon(Icons.done_all, size: 13, color: Color(0xFF80D8FF));
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatBubbleTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatLastSeen(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
