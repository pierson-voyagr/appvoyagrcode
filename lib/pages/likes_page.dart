import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:developer' as developer;
import 'dart:ui';
import '../models/post.dart';
import '../supabase_config.dart';
import 'post_detail_page.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  bool _showLiked = false; // false = "Likes" (posts I liked), true = "Liked" (posts that liked me)
  List<Post> _posts = [];
  bool _isLoading = true;

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
      final currentUserId = SupabaseConfig.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_showLiked) {
        // Fetch posts where others liked my posts
        // Get all my posts that have been liked
        final myPostsResponse = await SupabaseConfig.client
            .from('posts')
            .select('id')
            .eq('user_id', currentUserId);

        final myPostIds = (myPostsResponse as List).map((p) => p['id'] as String).toList();

        if (myPostIds.isEmpty) {
          setState(() {
            _posts = [];
            _isLoading = false;
          });
          return;
        }

        // Get all likes on my posts
        final likesResponse = await SupabaseConfig.client
            .from('post_likes')
            .select('post_id, user_id')
            .inFilter('post_id', myPostIds);

        final likedPostIds = (likesResponse as List)
            .map((like) => like['post_id'] as String)
            .toSet()
            .toList();

        if (likedPostIds.isEmpty) {
          setState(() {
            _posts = [];
            _isLoading = false;
          });
          return;
        }

        // Fetch the actual posts
        final postsResponse = await SupabaseConfig.client
            .from('posts')
            .select()
            .inFilter('id', likedPostIds)
            .order('created_at', ascending: false);

        final posts = (postsResponse as List).map((json) => Post.fromJson(json)).toList();

        // Enrich with metadata
        for (var post in posts) {
          // Get like count
          final likeCountResponse = await SupabaseConfig.client
              .from('post_likes')
              .select()
              .eq('post_id', post.id);
          post.likeCount = (likeCountResponse as List).length;

          // Get comment count
          final commentCountResponse = await SupabaseConfig.client
              .from('post_comments')
              .select()
              .eq('post_id', post.id);
          post.commentCount = (commentCountResponse as List).length;

          // Check if current user liked
          final userLikeResponse = await SupabaseConfig.client
              .from('post_likes')
              .select()
              .eq('post_id', post.id)
              .eq('user_id', currentUserId)
              .maybeSingle();
          post.isLikedByCurrentUser = userLikeResponse != null;

          // Get user info
          final userResponse = await SupabaseConfig.client
              .from('users')
              .select('name, photo_urls')
              .eq('id', post.userId)
              .single();

          post.userName = userResponse['name'] as String?;
          final photoUrls = userResponse['photo_urls'] as List?;
          if (photoUrls != null && photoUrls.isNotEmpty) {
            post.userProfileImageUrl = photoUrls[0] as String?;
          }
        }

        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      } else {
        // Fetch posts I liked
        final likesResponse = await SupabaseConfig.client
            .from('post_likes')
            .select('post_id')
            .eq('user_id', currentUserId);

        final likedPostIds = (likesResponse as List).map((like) => like['post_id'] as String).toList();

        if (likedPostIds.isEmpty) {
          setState(() {
            _posts = [];
            _isLoading = false;
          });
          return;
        }

        // Fetch the actual posts
        final postsResponse = await SupabaseConfig.client
            .from('posts')
            .select()
            .inFilter('id', likedPostIds)
            .order('created_at', ascending: false);

        final posts = (postsResponse as List).map((json) => Post.fromJson(json)).toList();

        // Enrich with metadata
        for (var post in posts) {
          // Get like count
          final likeCountResponse = await SupabaseConfig.client
              .from('post_likes')
              .select()
              .eq('post_id', post.id);
          post.likeCount = (likeCountResponse as List).length;

          // Get comment count
          final commentCountResponse = await SupabaseConfig.client
              .from('post_comments')
              .select()
              .eq('post_id', post.id);
          post.commentCount = (commentCountResponse as List).length;

          post.isLikedByCurrentUser = true; // We know they liked it

          // Get user info
          final userResponse = await SupabaseConfig.client
              .from('users')
              .select('name, photo_urls')
              .eq('id', post.userId)
              .single();

          post.userName = userResponse['name'] as String?;
          final photoUrls = userResponse['photo_urls'] as List?;
          if (photoUrls != null && photoUrls.isNotEmpty) {
            post.userProfileImageUrl = photoUrls[0] as String?;
          }
        }

        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Likes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Toggle between Likes and Liked
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_showLiked) {
                          setState(() {
                            _showLiked = false;
                          });
                          _loadPosts();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showLiked ? const Color(0xFF2E55C6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Likes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: !_showLiked ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!_showLiked) {
                          setState(() {
                            _showLiked = true;
                          });
                          _loadPosts();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showLiked ? const Color(0xFF2E55C6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Liked',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: _showLiked ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Posts grid
          Expanded(
            child: _isLoading
                ? Center(
                    child: Lottie.asset(
                      'lib/assets/VOYAGR STAR YELLOW.json',
                      width: 60,
                      height: 60,
                    ),
                  )
                : _posts.isEmpty
                    ? Center(
                        child: Text(
                          _showLiked
                              ? 'No one has liked your posts yet'
                              : 'You haven\'t liked any posts yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 3 / 5,
                        ),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return _buildPostCard(index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(int index) {
    final post = _posts[index];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              postId: post.id,
              initialPost: post,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Photo with heavy blur
              Image.asset(
                'lib/assets/IMG_5026.WEBP',
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
              ),
              // Heavy blur overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
