import 'package:flutter/material.dart';
import '../supabase_config.dart';
import '../services/messaging_service.dart';
import 'home_page.dart';
import 'message_thread_page.dart';

class MatchPage extends StatefulWidget {
  final Map<String, dynamic> matchedProfile;
  final String? city;

  const MatchPage({
    super.key,
    required this.matchedProfile,
    this.city,
  });

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> with SingleTickerProviderStateMixin {
  String? _currentUserPhotoUrl;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserPhoto();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserPhoto() async {
    final currentUser = SupabaseConfig.auth.currentUser;
    if (currentUser == null) return;

    try {
      final userData = await SupabaseConfig.client
          .from('users')
          .select('photo_urls')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userData != null && mounted) {
        final photoUrls = userData['photo_urls'];
        if (photoUrls != null && photoUrls is List && photoUrls.isNotEmpty) {
          setState(() {
            _currentUserPhotoUrl = photoUrls[0] as String;
          });
        }
      }
    } catch (e) {
      print('Error loading current user photo: $e');
    }
  }

  String? _getMatchedUserPhoto() {
    final photos = widget.matchedProfile['photos'] ?? widget.matchedProfile['photo_urls'];
    if (photos != null && photos is List && photos.isNotEmpty) {
      return photos[0] as String;
    }
    return null;
  }

  Widget _buildProfileCircle({
    required String? photoUrl,
    required bool isCurrentUser,
  }) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E55C6).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? (photoUrl.startsWith('http')
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  )
                : Image.asset(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  ))
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF2E55C6).withValues(alpha: 0.3),
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final matchedUserId = widget.matchedProfile['id'] as String?;
      final matchedName = widget.matchedProfile['name'] as String? ?? 'Someone';

      if (matchedUserId == null) {
        throw Exception('No matched user ID found');
      }

      // Create or get conversation
      final conversation = await MessagingService.getOrCreateConversation(
        otherUserId: matchedUserId,
      );

      // Create city match messages if there's a city
      if (widget.city != null) {
        await MessagingService.createCityMatchMessages(
          conversationId: conversation.id,
          otherUserId: matchedUserId,
          city: widget.city!,
        );
      }

      // Send the actual message
      await MessagingService.sendMessage(
        conversationId: conversation.id,
        receiverId: matchedUserId,
        content: message,
      );

      // Navigate to the message thread
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomePage(
              initialIndex: 2,
              navigateToThread: MessageThreadPage(
                conversationId: conversation.id,
                name: matchedName,
                city: widget.city ?? 'Unknown',
              ),
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchedName = widget.matchedProfile['name'] ?? 'Someone';
    final matchedPhoto = _getMatchedUserPhoto();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Light blue background
        color: const Color(0xFFE8F4FC),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          // Profile circles with star behind
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: SizedBox(
                              height: 240,
                              width: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Large star behind the circles
                                  Positioned(
                                    top: 0,
                                    child: Image.asset(
                                      'lib/assets/star_marker_128.png',
                                      width: 220,
                                      height: 220,
                                    ),
                                  ),
                                  // Profile circles container
                                  Positioned(
                                    bottom: 0,
                                    child: SizedBox(
                                      height: 200,
                                      width: 260,
                                      child: Stack(
                                        children: [
                                          // Top-left circle (matched user)
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            child: _buildProfileCircle(
                                              photoUrl: matchedPhoto,
                                              isCurrentUser: false,
                                            ),
                                          ),
                                          // Bottom-right circle (current user)
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: _buildProfileCircle(
                                              photoUrl: _currentUserPhotoUrl,
                                              isCurrentUser: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // "U-Matched" text
                          const Text(
                            'U-Matched',
                            style: TextStyle(
                              fontFamily: 'Mona Sans',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E55C6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // "with [name]" text
                          Text(
                            'with $matchedName',
                            style: const TextStyle(
                              fontFamily: 'Mona Sans',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E55C6),
                            ),
                          ),
                          const Spacer(flex: 2),
                          // Message input field
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2E55C6).withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: const InputDecoration(
                                        hintText: 'Send a message...',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Mona Sans',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFAAAAAA),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'Mona Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) => _sendMessage(),
                                    ),
                                  ),
                                  // Send button
                                  GestureDetector(
                                    onTap: _isSending ? null : _sendMessage,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2E55C6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: _isSending
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.arrow_upward_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // "Keep on connecting" button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF2E55C6),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                    side: const BorderSide(
                                      color: Color(0xFF2E55C6),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Keep on connecting',
                                  style: TextStyle(
                                    fontFamily: 'Mona Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E55C6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
