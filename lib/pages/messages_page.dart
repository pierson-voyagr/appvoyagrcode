import 'dart:ui';
import 'package:flutter/material.dart';
import 'message_thread_page.dart';
import '../services/messaging_service.dart';
import '../models/conversation.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Conversation> _conversations = [];
  List<Map<String, dynamic>> _matchedUsersWithoutConversation = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load conversations and matched users in parallel
      final results = await Future.wait([
        MessagingService.getConversations(),
        MessagingService.getMatchedUsersWithoutConversation(),
      ]);

      if (mounted) {
        setState(() {
          _conversations = results[0] as List<Conversation>;
          _matchedUsersWithoutConversation = results[1] as List<Map<String, dynamic>>;

          // Add a demo profile if no real matches exist
          if (_matchedUsersWithoutConversation.isEmpty) {
            _matchedUsersWithoutConversation.add({
              'id': 'demo-user-sarah',
              'name': 'Sarah',
              'city': 'London',
              'isDemo': true,
            });
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading messages data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Placeholder conversations for the design
    final List<Map<String, String>> placeholderMessages = [
      {'name': 'GREEN TORTOISE', 'message': 'Hey I hope your stay is going great, do you need anything?', 'time': '23m', 'image': 'lib/assets/green_tortoise.png'},
      {'name': 'BRODY', 'message': 'Hey, whats up, when are you going to arrive at Green Turtle?', 'time': '23m', 'image': 'lib/assets/AUSTIN/Austin 2.jpg'},
      {'name': 'ALDRIC', 'message': 'Hey, whats up, when are you going to arrive at Green Turtle?', 'time': '23m', 'image': 'lib/assets/AUSTIN/Austin 3.jpg'},
      {'name': 'ARTHUR', 'message': 'Hey, whats up, when are you going to arrive at Green Turtle?', 'time': '23m', 'image': 'lib/assets/AUSTIN/Austin 4.jpg'},
      {'name': 'NATHAN', 'message': 'Hey, whats up, when are you going to arrive at Green Turtle?', 'time': '23m', 'image': 'lib/assets/AUSTIN/Austin 5.jpg'},
      {'name': 'BRODY', 'message': 'Hey, whats up, when are you going to arrive at Green Turtle?', 'time': '23m', 'image': 'lib/assets/AUSTIN/Austin 6.jpg'},
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // White background
        Positioned.fill(
          child: Container(color: Colors.white),
        ),
        // Voyagr star icon - top left, behind content
        Positioned(
          top: -20,
          left: -45,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateZ(0.26),
            child: Image.asset(
              'lib/assets/voyagr_star_light_blue.png',
              width: 156.98,
              height: 210.50,
            ),
          ),
        ),
        // Main content
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "YOUR CONNECTIONS" header
              Transform.translate(
                offset: const Offset(0, -5),
                child: const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 11),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'YOUR CONNECTIONS',
                    style: TextStyle(
                      color: Color(0xFF2E55C6),
                      fontSize: 48,
                      fontFamily: 'Mona Sans SemiCondensed',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              ),
              // Message list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(17, 0, 17, 130),
                  itemCount: placeholderMessages.length,
                  itemBuilder: (context, index) {
                    final msg = placeholderMessages[index];
                    return _buildPlaceholderMessageCard(
                      name: msg['name']!,
                      message: msg['message']!,
                      time: msg['time']!,
                      imagePath: msg['image']!,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderMessageCard({
    required String name,
    required String message,
    required String time,
    required String imagePath,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _PlaceholderChatPage(
              name: name,
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 124,
      decoration: ShapeDecoration(
        color: const Color(0xFFC3DAF4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 6,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Profile photo
          Container(
            width: 92,
            height: 92,
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name banner + message
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name on blue banner with star
                  Transform(
                    transform: Matrix4.identity()..rotateZ(-0.03),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Blue box behind name
                        Padding(
                          padding: const EdgeInsets.only(top: 0.57),
                          child: Container(
                            padding: const EdgeInsets.only(left: 5, right: 18, top: 2, bottom: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2355C6),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontFamily: 'Mona Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // Yellow star overlapping right edge of blue box
                        Positioned(
                          right: -15,
                          top: 1.25,
                          child: Transform(
                            transform: Matrix4.identity()..rotateZ(0.18),
                            child: Image.asset(
                              'lib/assets/voyagr_star_yellow.png',
                              width: 26.54,
                              height: 36.33,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Message preview + time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Mona Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> user) {
    final name = user['name'] as String? ?? 'Unknown';
    final city = user['city'] as String?;
    final userId = user['id'] as String;
    final isDemo = user['isDemo'] as bool? ?? false;

    return GestureDetector(
      onTap: () async {
        // Handle demo user differently
        if (isDemo) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This is a demo profile. Match with real users to start a conversation!'),
              backgroundColor: Color(0xFF2E55C6),
            ),
          );
          return;
        }

        // Create conversation and navigate to thread
        try {
          final conversation = await MessagingService.getOrCreateConversation(
            otherUserId: userId,
          );

          // Create city match messages if there's a city
          if (city != null) {
            await MessagingService.createCityMatchMessages(
              conversationId: conversation.id,
              otherUserId: userId,
              city: city,
            );
          }

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessageThreadPage(
                  conversationId: conversation.id,
                  name: name,
                  city: city ?? 'Unknown',
                ),
              ),
            ).then((_) {
              // Reload data when returning from thread
              _loadData();
            });
          }
        } catch (e) {
          print('Error creating conversation: $e');
        }
      },
      child: Column(
        children: [
          Container(
            width: 90,
            height: 108,
            decoration: BoxDecoration(
              color: const Color(0xFF2E55C6),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E55C6).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E55C6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(Conversation conversation) {
    final name = conversation.otherUserName ?? 'Unknown';
    final city = conversation.otherUserCity ?? '';
    final message = conversation.lastMessage ?? '';
    final time = _formatTime(conversation.lastMessageAt);
    final photoUrl = conversation.otherUserProfileImage;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageThreadPage(
              conversationId: conversation.id,
              name: name,
              city: city,
            ),
          ),
        ).then((_) {
          _loadData();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 124,
        decoration: ShapeDecoration(
          color: const Color(0xFFC3DAF4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 6,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            // Profile photo
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFF2E55C6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.person, color: Colors.white, size: 40),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 40),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Name banner + message
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name on blue banner
                    Transform(
                      transform: Matrix4.identity()..rotateZ(-0.03),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2355C6),
                        ),
                        child: Text(
                          name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Message preview + time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Mona Sans',
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderChatPage extends StatefulWidget {
  final String name;
  final String imagePath;

  const _PlaceholderChatPage({
    required this.name,
    required this.imagePath,
  });

  @override
  State<_PlaceholderChatPage> createState() => _PlaceholderChatPageState();
}

class _PlaceholderChatPageState extends State<_PlaceholderChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Seed with a placeholder message
    _messages.add({
      'text': 'Hey, whats up, when are you going to arrive at Green Turtle?',
      'isMe': false,
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'isMe': true});
    });
    _controller.clear();
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
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'Profile',
                  barrierColor: Colors.transparent,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    widget.imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF2E55C6)
                              : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          msg['text'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Mona Sans',
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
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
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Mona Sans',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E55C6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
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
}
