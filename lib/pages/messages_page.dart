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
    return Stack(
      children: [
        // Background image with gradient overlay
        Positioned.fill(
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'lib/assets/homepage_logo1.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              // White gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.92),
                        Colors.white,
                      ],
                      stops: const [0.26, 0.34, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main content with SafeArea
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: const Text(
                  'Messages',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              // Horizontal scrollable cards - matches without conversations
              if (_matchedUsersWithoutConversation.isNotEmpty) ...[
                SizedBox(
                  height: 140,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: _matchedUsersWithoutConversation.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;
                        return Row(
                          children: [
                            _buildMatchCard(user),
                            if (index < _matchedUsersWithoutConversation.length - 1)
                              const SizedBox(width: 12),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // "Recent" section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Recent',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E55C6).withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Message list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E55C6),
                        ),
                      )
                    : _conversations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: const Color(0xFF2E55C6).withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontFamily: 'Mona Sans',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2E55C6).withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start a conversation with your matches!',
                                  style: TextStyle(
                                    fontFamily: 'Mona Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF2E55C6).withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFF2E55C6),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                              itemCount: _conversations.length,
                              itemBuilder: (context, index) {
                                final conversation = _conversations[index];
                                return _buildMessageRow(conversation);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ],
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
          // Reload data when returning from thread
          _loadData();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E55C6).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile photo or placeholder
            Container(
              width: 60,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2E55C6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and location row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Mona Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A8A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (city.isNotEmpty)
                        Text(
                          city,
                          style: TextStyle(
                            fontFamily: 'Mona Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E55C6).withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Message preview and time row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontFamily: 'Mona Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF2E55C6).withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E55C6).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
