import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/trip.dart';
import '../models/post.dart';
import '../supabase_config.dart';
import 'interest_detail_page.dart';
import 'post_detail_page.dart';

class CityDetailsPage extends StatefulWidget {
  final Trip trip;

  const CityDetailsPage({super.key, required this.trip});

  @override
  State<CityDetailsPage> createState() => _CityDetailsPageState();
}

class _CityDetailsPageState extends State<CityDetailsPage> {
  int _currentPhotoIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Post> _pinnedPosts = [];
  bool _isLoadingPosts = true;

  // Selected interests (yellow-filled pins)
  final Set<String> _selectedInterests = {'Food', 'Museums', 'Nature', 'Nightlife'};

  @override
  void initState() {
    super.initState();
    _loadPinnedPosts();
  }

  Future<void> _loadPinnedPosts() async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      setState(() {
        _isLoadingPosts = false;
      });
      return;
    }

    try {
      // Get all pinned post IDs for current user
      final pinnedResponse = await SupabaseConfig.client
          .from('post_pins')
          .select('post_id')
          .eq('user_id', currentUserId);

      final pinnedPostIds = (pinnedResponse as List)
          .map((pin) => pin['post_id'] as String)
          .toList();

      if (pinnedPostIds.isEmpty) {
        setState(() {
          _pinnedPosts = [];
          _isLoadingPosts = false;
        });
        return;
      }

      // Fetch the actual posts
      final postsResponse = await SupabaseConfig.client
          .from('posts')
          .select()
          .inFilter('id', pinnedPostIds)
          .order('created_at', ascending: false);

      final posts = (postsResponse as List)
          .map((json) => Post.fromJson(json))
          .toList();

      // Enrich with metadata
      for (var post in posts) {
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
        _pinnedPosts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      print('❌ Error loading pinned posts: $e');
      setState(() {
        _isLoadingPosts = false;
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.trip.city,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo slider at the top with 4:5 aspect ratio - shows pinned posts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _isLoadingPosts
                        ? Container(
                            color: const Color(0xFF2C2C2E),
                            child: Center(
                              child: Lottie.asset(
                                'lib/assets/VOYAGR STAR YELLOW.json',
                                width: 60,
                                height: 60,
                              ),
                            ),
                          )
                        : _pinnedPosts.isEmpty
                            ? Container(
                                color: const Color(0xFF2C2C2E),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.push_pin_outlined,
                                        size: 64,
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No pinned posts yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Pin posts to see them here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTapUp: (details) {
                                  final width = MediaQuery.of(context).size.width;
                                  final tapX = details.localPosition.dx;

                                  // If tapped in center 40%, open post detail page
                                  if (tapX > width * 0.3 && tapX < width * 0.7) {
                                    final currentPost = _pinnedPosts[_currentPhotoIndex];
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostDetailPage(
                                          postId: currentPost.id,
                                          initialPost: currentPost,
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Navigate photos if tapped on sides
                                    setState(() {
                                      if (tapX < width * 0.3) {
                                        // Tapped left - previous photo
                                        if (_currentPhotoIndex > 0) {
                                          _currentPhotoIndex--;
                                        }
                                      } else {
                                        // Tapped right - next photo
                                        if (_currentPhotoIndex < _pinnedPosts.length - 1) {
                                          _currentPhotoIndex++;
                                        }
                                      }
                                    });
                                  }
                                },
                                child: Stack(
                                  children: [
                                    // Photo display - first photo of pinned post
                                    Image.network(
                                      _pinnedPosts[_currentPhotoIndex].photoUrls.isNotEmpty
                                          ? _pinnedPosts[_currentPhotoIndex].photoUrls[0]
                                          : '',
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
                                    // Progress bar at the top
                                    if (_pinnedPosts.length > 1)
                                      Positioned(
                                        top: 8,
                                        left: 12,
                                        right: 12,
                                        child: Row(
                                          children: List.generate(
                                            _pinnedPosts.length,
                                            (index) {
                                              return Expanded(
                                                child: Container(
                                                  height: 4,
                                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                                  decoration: BoxDecoration(
                                                    color: index <= _currentPhotoIndex
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
              ),
            ),

            const SizedBox(height: 24),

            // Selected interests (yellow-filled pins)
            if (_selectedInterests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _selectedInterests.map((interest) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InterestDetailPage(
                              interest: interest,
                              trip: widget.trip,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107), // Yellow fill
                          border: Border.all(
                            color: const Color(0xFF2E55C6), // Dark blue stroke
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E55C6), // Dark blue text
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // Search for interests section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search For',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search interests...',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
