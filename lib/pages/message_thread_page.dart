import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';
import '../supabase_config.dart';
import 'shared_post_view_page.dart';

class MessageThreadPage extends StatefulWidget {
  final String conversationId;
  final String name;
  final String? profileImage;
  final String city;

  const MessageThreadPage({
    super.key,
    required this.conversationId,
    required this.name,
    this.profileImage,
    required this.city,
  });

  @override
  State<MessageThreadPage> createState() => _MessageThreadPageState();
}

class _MessageThreadPageState extends State<MessageThreadPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  String? _otherUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final messages = await MessagingService.getMessages(
        conversationId: widget.conversationId,
      );

      // Determine the other user ID from the first message
      final currentUserId = SupabaseConfig.auth.currentUser?.id;
      if (messages.isNotEmpty && currentUserId != null) {
        final firstMessage = messages.first;
        _otherUserId = firstMessage.senderId == currentUserId
            ? firstMessage.receiverId
            : firstMessage.senderId;
      }

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await MessagingService.markMessagesAsRead(
        conversationId: widget.conversationId,
      );
    } catch (e) {
      // Silently fail, not critical
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      // Get other user ID from conversation
      if (_otherUserId == null) {
        // Fetch conversation to get other user ID
        final currentUserId = SupabaseConfig.auth.currentUser?.id;
        if (currentUserId == null) {
          throw Exception('No user logged in');
        }

        final conversationData = await SupabaseConfig.client
            .from('conversations')
            .select()
            .eq('id', widget.conversationId)
            .single();

        _otherUserId = conversationData['user1_id'] == currentUserId
            ? conversationData['user2_id']
            : conversationData['user1_id'];
      }

      final message = await MessagingService.sendMessage(
        conversationId: widget.conversationId,
        receiverId: _otherUserId!,
        content: content,
      );

      if (mounted) {
        setState(() {
          _messages.add(message);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E55C6)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF2E55C6)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Report User
                        ListTile(
                          leading: const Icon(Icons.flag, color: Colors.red),
                          title: const Text(
                            'Report User',
                            style: TextStyle(
                              fontFamily: 'Mona Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Report user functionality coming soon'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        // Block User
                        ListTile(
                          leading: const Icon(Icons.block, color: Colors.orange),
                          title: const Text(
                            'Block User',
                            style: TextStyle(
                              fontFamily: 'Mona Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Block functionality coming soon'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        title: Row(
          children: [
            // Profile picture
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2E55C6),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Text(
              widget.name,
              style: const TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E55C6),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E55C6),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Error loading messages',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E55C6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet. Start the conversation!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final currentUserId = SupabaseConfig.auth.currentUser?.id;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == currentUserId;

        // Handle city divider messages
        if (message.isCityDivider) {
          return _buildCityDivider(message);
        }

        // Handle match notification messages
        if (message.isMatchNotification) {
          return _buildMatchNotification(message);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              message.isSharedPost
                  ? _buildSharedPostMessage(message, isMe)
                  : _buildTextMessage(message, isMe),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCityDivider(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Divider line
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF2E55C6).withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  message.city ?? message.content,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E55C6),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2E55C6).withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchNotification(Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFC3DAF4).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2E55C6).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E55C6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTextMessage(Message message, bool isMe) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF2E55C6) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 16,
          color: isMe ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildSharedPostMessage(Message message, bool isMe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedPostViewPage(
              photoPath: message.sharedPostImage!,
              caption: message.sharedPostCaption ?? '',
              initialLikeCount: message.sharedPostLikes ?? 0,
              initialCommentCount: message.sharedPostComments ?? 0,
              initialIsLiked: false,
            ),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2E55C6) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with 4:5 aspect ratio
            AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  message.sharedPostImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF2C2C2E),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFF2C2C2E),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: isMe ? Colors.white : const Color(0xFF2E55C6),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Divider line
            Container(
              height: 1,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            // Caption section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                message.sharedPostCaption ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? Colors.white : Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                  ),
                  style: const TextStyle(fontSize: 16),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isSending
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF2E55C6),
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
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
