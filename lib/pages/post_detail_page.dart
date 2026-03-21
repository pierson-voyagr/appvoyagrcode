import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post.dart';
import '../services/posts_service.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final Post? initialPost; // Optional: if we already have the post data

  const PostDetailPage({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Post? _post;
  bool _isLoading = true;
  bool _isPinned = false;
  int _currentPhotoIndex = 0;
  final PageController _photoPageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  List<PostComment> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    if (widget.initialPost != null) {
      setState(() {
        _post = widget.initialPost;
        _isLoading = false;
      });
      await _loadComments();
    } else {
      try {
        final post = await PostsService.getPostById(postId: widget.postId);
        setState(() {
          _post = post;
          _isLoading = false;
        });
        await _loadComments();
      } catch (e) {
        print('Error loading post: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    if (_post == null) return;

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments = await PostsService.getComments(postId: _post!.id);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;

    final wasLiked = _post!.isLikedByCurrentUser ?? false;
    final currentLikes = _post!.likeCount ?? 0;

    // Optimistic update
    setState(() {
      _post = _post!.copyWith(
        isLikedByCurrentUser: !wasLiked,
        likeCount: wasLiked ? currentLikes - 1 : currentLikes + 1,
      );
    });

    try {
      await PostsService.toggleLike(postId: _post!.id);
    } catch (e) {
      // Revert on error
      setState(() {
        _post = _post!.copyWith(
          isLikedByCurrentUser: wasLiked,
          likeCount: currentLikes,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_post == null || _commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();
    _commentController.clear();

    try {
      final comment = await PostsService.addComment(
        postId: _post!.id,
        content: content,
      );

      setState(() {
        _comments.add(comment);
        _post = _post!.copyWith(
          commentCount: (_post!.commentCount ?? 0) + 1,
        );
      });
    } catch (e) {
      print('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment')),
        );
      }
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
        title: Text(
          _post?.userName ?? 'Post',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Lottie.asset(
                'lib/assets/VOYAGR STAR YELLOW.json',
                width: 60,
                height: 60,
              ),
            )
          : _post == null
              ? const Center(
                  child: Text(
                    'Post not found',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Profile picture
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2E55C6),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _post!.userProfileImageUrl != null
                                    ? Image.network(
                                        _post!.userProfileImageUrl!,
                                        fit: BoxFit.cover,
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
                            const SizedBox(width: 12),
                            // Name and time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _post!.userName ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    timeago.format(_post!.createdAt),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Photo carousel
                      if (_post!.photoUrls.isNotEmpty) ...[
                        SizedBox(
                          height: 500,
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _photoPageController,
                                itemCount: _post!.photoUrls.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPhotoIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    _post!.photoUrls[index],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: Lottie.asset(
                                          'lib/assets/VOYAGR STAR YELLOW.json',
                                          width: 60,
                                          height: 60,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              // Photo indicator dots
                              if (_post!.photoUrls.length > 1)
                                Positioned(
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _post!.photoUrls.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: index == _currentPhotoIndex
                                              ? const Color(0xFF2E55C6)
                                              : Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Action buttons row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Like button
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Row(
                                children: [
                                  Icon(
                                    _post!.isLikedByCurrentUser == true
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _post!.isLikedByCurrentUser == true
                                        ? Colors.red
                                        : Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_post!.likeCount ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Comment count
                            Row(
                              children: [
                                const Icon(
                                  Icons.comment_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_post!.commentCount ?? 0}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Share button
                            GestureDetector(
                              onTap: () async {
                                if (_post != null) {
                                  try {
                                    await PostsService.sharePost(post: _post!);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to share post: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              child: const Icon(
                                Icons.share_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const Spacer(),
                            // Pin button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPinned = !_isPinned;
                                });
                              },
                              child: Icon(
                                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: _isPinned ? const Color(0xFF2E55C6) : Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Caption
                      if (_post!.caption != null && _post!.caption!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _post!.caption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Tags
                      if (_post!.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _post!.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E55C6).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF2E55C6),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Color(0xFF2E55C6),
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Divider
                      Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),

                      // Comments section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Comments',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Comment input
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF2C2C2E),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _addComment,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E55C6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Comments list
                      _isLoadingComments
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Lottie.asset(
                                  'lib/assets/VOYAGR STAR YELLOW.json',
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            )
                          : _comments.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      'No comments yet',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = _comments[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // User avatar
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF2E55C6),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: comment.userProfileImageUrl != null
                                                  ? Image.network(
                                                      comment.userProfileImageUrl!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      color: const Color(0xFF2C2C2E),
                                                      child: const Icon(
                                                        Icons.person,
                                                        color: Color(0xFF2E55C6),
                                                        size: 20,
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
                                                      comment.userName ?? 'Unknown',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      timeago.format(comment.createdAt),
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.5),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  comment.content,
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
                                  },
                                ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}
