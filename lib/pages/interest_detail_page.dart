import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/post.dart';
import '../supabase_config.dart';
import '../services/posts_service.dart';
import 'create_post/photo_selection_page.dart';
import 'post_detail_page.dart';

class InterestDetailPage extends StatefulWidget {
  final String interest;
  final Trip trip;

  const InterestDetailPage({
    super.key,
    required this.interest,
    required this.trip,
  });

  @override
  State<InterestDetailPage> createState() => _InterestDetailPageState();
}

class _InterestDetailPageState extends State<InterestDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Post> _posts = [];
  bool _isLoading = true;
  final Map<String, int> _currentPhotoIndexes = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await PostsService.getPostsByTag(tag: widget.interest);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: Stack(
        children: [
          // Header with background image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'lib/assets/homepage_logo2.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                // Back button
                Positioned(
                  top: 50,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Header text
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Text(
                    '${widget.interest} in ${widget.trip.city}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content card
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Search bar and add button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search posts...',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2E),
                              prefixIcon: const Icon(Icons.search, color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PhotoSelectionPage(),
                              ),
                            );
                            // Reload posts after returning
                            _loadPosts();
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E55C6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Posts list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        return _buildPostCard(index);
                      },
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

  Widget _buildPostCard(int postIndex) {
    final post = _posts[postIndex];
    final currentPhotoIndex = _currentPhotoIndexes[post.id] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo card with 4:5 aspect ratio
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Photo display
                    GestureDetector(
                      onTapUp: (details) {
                        final width = MediaQuery.of(context).size.width;
                        final tapX = details.localPosition.dx;

                        // If tapped in center 40%, open detail page
                        if (tapX > width * 0.3 && tapX < width * 0.7) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(
                                postId: post.id,
                                initialPost: post,
                              ),
                            ),
                          );
                        } else {
                          // Navigate photos if tapped on sides
                          setState(() {
                            if (tapX < width * 0.3) {
                              // Tapped left - previous photo
                              if (currentPhotoIndex > 0) {
                                _currentPhotoIndexes[post.id] = currentPhotoIndex - 1;
                              }
                            } else {
                              // Tapped right - next photo
                              if (currentPhotoIndex < post.photoUrls.length - 1) {
                                _currentPhotoIndexes[post.id] = currentPhotoIndex + 1;
                              }
                            }
                          });
                        }
                      },
                      child: Image.network(
                        post.photoUrls[currentPhotoIndex],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF2C2C2E),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white,
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
                                color: const Color(0xFF2E55C6),
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
                    // User profile in top left
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Profile picture
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: post.userProfileImageUrl != null
                                    ? Image.network(
                                        post.userProfileImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFF2E55C6),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: const Color(0xFF2E55C6),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Username
                            Text(
                              post.userName ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Photo indicators (pills)
                    if (post.photoUrls.length > 1)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: List.generate(
                            post.photoUrls.length,
                            (index) {
                              return Expanded(
                                child: Container(
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: index <= currentPhotoIndex
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Interaction section (heart, comments, and caption)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heart count, comments, and share in one row
                Row(
                  children: [
                    // Heart icon and count
                    GestureDetector(
                      onTap: () async {
                        await PostsService.toggleLike(postId: post.id);
                        // Reload posts to get updated like count
                        _loadPosts();
                      },
                      child: Row(
                        children: [
                          Icon(
                            post.isLikedByCurrentUser == true ? Icons.favorite : Icons.favorite_border,
                            color: post.isLikedByCurrentUser == true ? Colors.red : Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likeCount ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Comments icon and count
                    GestureDetector(
                      onTap: () {
                        _showCommentsBottomSheet(context, postIndex);
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.comment_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.commentCount ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Pin button
                    GestureDetector(
                      onTap: () async {
                        await PostsService.togglePin(postId: post.id);
                        _loadPosts();
                      },
                      child: Icon(
                        post.isPinnedByCurrentUser == true
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        color: post.isPinnedByCurrentUser == true
                            ? const Color(0xFFFFC107)
                            : Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Share button
                    GestureDetector(
                      onTap: () {
                        _showShareBottomSheet(context, postIndex);
                      },
                      child: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                // Caption
                if (post.caption != null && post.caption!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    post.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMatchedUsersForTrip() async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      print('❌ VOYAGR SHARE: No current user');
      return [];
    }

    try {
      print('🔍 VOYAGR SHARE: Fetching matches for trip to ${widget.trip.city}');

      // Get all matches for current user
      final matchesResponse = await SupabaseConfig.client
          .from('matches')
          .select()
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

      final List<Map<String, dynamic>> matchedUsers = [];

      for (var match in matchesResponse as List) {
        final otherUserId = match['user1_id'] == currentUserId
            ? match['user2_id']
            : match['user1_id'];

        // Get the conversation for this match
        final userId1 = currentUserId.compareTo(otherUserId) < 0 ? currentUserId : otherUserId;
        final userId2 = currentUserId.compareTo(otherUserId) < 0 ? otherUserId : currentUserId;

        final conversationResponse = await SupabaseConfig.client
            .from('conversations')
            .select('id')
            .eq('user1_id', userId1)
            .eq('user2_id', userId2)
            .maybeSingle();

        if (conversationResponse == null) continue;

        final conversationId = conversationResponse['id'] as String;

        // Check if there's a city divider for THIS city in the conversation
        final cityDividerResponse = await SupabaseConfig.client
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .eq('message_type', 'city_divider')
            .eq('city', widget.trip.city)
            .maybeSingle();

        // Only include if they've matched in THIS city
        if (cityDividerResponse != null) {
          // Get user details
          final userResponse = await SupabaseConfig.client
              .from('users')
              .select('id, name, photo_urls')
              .eq('id', otherUserId)
              .single();

          final photoUrls = userResponse['photo_urls'] as List?;
          matchedUsers.add({
            'id': userResponse['id'],
            'name': userResponse['name'] ?? 'Unknown',
            'photo_url': (photoUrls != null && photoUrls.isNotEmpty) ? photoUrls[0] : null,
            'conversation_id': conversationId,
          });
        }
      }

      return matchedUsers;
    } catch (e) {
      print('❌ VOYAGR SHARE: Error fetching matched users: $e');
      return [];
    }
  }

  Future<void> _sharePostWithUser(Map<String, dynamic> user, int postIndex) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) return;

    final post = _posts[postIndex];
    final conversationId = user['conversation_id'] as String;

    try {
      // Send message with shared post
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'receiver_id': user['id'],
        'content': 'Shared a post',
        'message_type': 'shared_post',
        'shared_post_image': post.photoUrls.isNotEmpty ? post.photoUrls[0] : null,
        'shared_post_caption': post.caption ?? '',
        'shared_post_likes': post.likeCount ?? 0,
        'shared_post_comments': post.commentCount ?? 0,
      });

      print('✅ VOYAGR SHARE: Shared post with ${user['name']}');
    } catch (e) {
      print('❌ VOYAGR SHARE: Error sharing post: $e');
      rethrow;
    }
  }

  void _showShareBottomSheet(BuildContext context, int postIndex) async {
    // Show loading indicator first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E55C6),
          ),
        ),
      ),
    );

    // Fetch matched users
    final matchedUsers = await _fetchMatchedUsersForTrip();

    if (!context.mounted) return;

    // Close loading sheet
    Navigator.pop(context);

    // Show actual share sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Share with',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'People matched for ${widget.trip.city}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            // Users grid or empty state
            Expanded(
              child: matchedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No matches for ${widget.trip.city} yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: matchedUsers.length,
                itemBuilder: (context, index) {
                  final user = matchedUsers[index];
                  return GestureDetector(
                    onTap: () async {
                      try {
                        await _sharePostWithUser(user, postIndex);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Shared with ${user['name']}'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF2E55C6),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to share: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Column(
                      children: [
                        // Profile picture
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2E55C6),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: user['photo_url'] != null
                                ? Image.network(
                                    user['photo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFF2C2C2E),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF2E55C6),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: const Color(0xFF2C2C2E),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF2E55C6),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Name
                        Expanded(
                          child: Text(
                            user['name'],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, int postIndex) async {
    final TextEditingController commentController = TextEditingController();
    final post = _posts[postIndex];

    // Fetch comments
    final comments = await PostsService.getComments(postId: post.id);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${comments.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF2C2C2E), height: 1),
              // Comments list
              Expanded(
                child: comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _buildCommentItem(
                            comment.userName ?? 'Unknown',
                            comment.content,
                            _formatCommentTime(comment.createdAt),
                          );
                        },
                      ),
              ),
              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1C1C1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        if (commentController.text.isNotEmpty) {
                          await PostsService.addComment(
                            postId: post.id,
                            content: commentController.text,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _loadPosts();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Comment added!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(String name, String comment, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  color: Color(0xFF2E55C6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }
}
