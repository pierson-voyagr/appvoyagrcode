import 'dart:io';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../supabase_config.dart';
import '../models/post.dart';

class PostsService {
  /// Creates a new post with photos, caption, and tags
  static Future<Post> createPost({
    required List<File> photos,
    String? caption,
    List<String> tags = const [],
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      print('📸 VOYAGR POST: Creating post with ${photos.length} photos');

      // Upload photos to Supabase Storage
      final List<String> photoUrls = [];
      for (int i = 0; i < photos.length; i++) {
        final photoUrl = await _uploadPhoto(photos[i], currentUserId, i);
        photoUrls.add(photoUrl);
        print('✅ VOYAGR POST: Uploaded photo ${i + 1}/${photos.length}');
      }

      print('✅ VOYAGR POST: All photos uploaded, creating post record');

      // Create post record in database
      final response = await SupabaseConfig.client.from('posts').insert({
        'user_id': currentUserId,
        'caption': caption,
        'photo_urls': photoUrls,
        'tags': tags,
      }).select().single();

      print('✅ VOYAGR POST: Post created successfully');

      return Post.fromJson(response);
    } catch (e) {
      print('❌ VOYAGR POST: Error creating post: $e');
      developer.log('Error creating post: $e');
      rethrow;
    }
  }

  /// Uploads a photo to Supabase Storage
  static Future<String> _uploadPhoto(File photo, String userId, int index) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
      final path = 'posts/$userId/$fileName';

      // Upload file to Supabase Storage
      await SupabaseConfig.client.storage.from('post-photos').upload(
            path,
            photo,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final url = SupabaseConfig.client.storage.from('post-photos').getPublicUrl(path);

      return url;
    } catch (e) {
      developer.log('Error uploading photo: $e');
      rethrow;
    }
  }

  /// Gets posts filtered by tag
  static Future<List<Post>> getPostsByTag({
    required String tag,
    int limit = 20,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;

    try {
      print('🔍 VOYAGR POST: Fetching posts for tag: $tag');

      // Query posts that contain the tag
      final response = await SupabaseConfig.client
          .from('posts')
          .select()
          .contains('tags', [tag])
          .order('created_at', ascending: false)
          .limit(limit);

      final posts = (response as List).map((json) => Post.fromJson(json)).toList();

      // Fetch additional metadata for each post
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

        // Check if current user liked the post
        if (currentUserId != null) {
          final userLikeResponse = await SupabaseConfig.client
              .from('post_likes')
              .select()
              .eq('post_id', post.id)
              .eq('user_id', currentUserId)
              .maybeSingle();
          post.isLikedByCurrentUser = userLikeResponse != null;

          // Check if current user pinned the post
          final userPinResponse = await SupabaseConfig.client
              .from('post_pins')
              .select()
              .eq('post_id', post.id)
              .eq('user_id', currentUserId)
              .maybeSingle();
          post.isPinnedByCurrentUser = userPinResponse != null;
        }

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

      print('✅ VOYAGR POST: Found ${posts.length} posts for tag: $tag');

      return posts;
    } catch (e) {
      print('❌ VOYAGR POST: Error fetching posts: $e');
      developer.log('Error fetching posts by tag: $e');
      rethrow;
    }
  }

  /// Likes or unlikes a post
  static Future<void> toggleLike({
    required String postId,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      // Check if user already liked the post
      final existingLike = await SupabaseConfig.client
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await SupabaseConfig.client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUserId);
        print('👎 VOYAGR POST: Unliked post $postId');
      } else {
        // Like
        await SupabaseConfig.client.from('post_likes').insert({
          'post_id': postId,
          'user_id': currentUserId,
        });
        print('👍 VOYAGR POST: Liked post $postId');
      }
    } catch (e) {
      print('❌ VOYAGR POST: Error toggling like: $e');
      developer.log('Error toggling like: $e');
      rethrow;
    }
  }

  /// Pins or unpins a post
  static Future<void> togglePin({
    required String postId,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      // Check if user already pinned the post
      final existingPin = await SupabaseConfig.client
          .from('post_pins')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingPin != null) {
        // Unpin
        await SupabaseConfig.client
            .from('post_pins')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUserId);
        print('📌 VOYAGR POST: Unpinned post $postId');
      } else {
        // Pin
        await SupabaseConfig.client.from('post_pins').insert({
          'post_id': postId,
          'user_id': currentUserId,
        });
        print('📍 VOYAGR POST: Pinned post $postId');
      }
    } catch (e) {
      print('❌ VOYAGR POST: Error toggling pin: $e');
      developer.log('Error toggling pin: $e');
      rethrow;
    }
  }

  /// Adds a comment to a post
  static Future<PostComment> addComment({
    required String postId,
    required String content,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      final response = await SupabaseConfig.client.from('post_comments').insert({
        'post_id': postId,
        'user_id': currentUserId,
        'content': content,
      }).select().single();

      print('💬 VOYAGR POST: Added comment to post $postId');

      return PostComment.fromJson(response);
    } catch (e) {
      print('❌ VOYAGR POST: Error adding comment: $e');
      developer.log('Error adding comment: $e');
      rethrow;
    }
  }

  /// Gets comments for a post
  static Future<List<PostComment>> getComments({
    required String postId,
    int limit = 50,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('post_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .limit(limit);

      final comments = (response as List).map((json) => PostComment.fromJson(json)).toList();

      // Get user info for each comment
      for (var comment in comments) {
        final userResponse = await SupabaseConfig.client
            .from('users')
            .select('name, photo_urls')
            .eq('id', comment.userId)
            .maybeSingle();

        if (userResponse != null) {
          comment.userName = userResponse['name'] as String?;
          final photoUrls = userResponse['photo_urls'] as List?;
          if (photoUrls != null && photoUrls.isNotEmpty) {
            comment.userProfileImageUrl = photoUrls[0] as String?;
          }
        }
      }

      return comments;
    } catch (e) {
      developer.log('Error getting comments: $e');
      rethrow;
    }
  }

  /// Deletes a post
  static Future<void> deletePost({
    required String postId,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      // Get post to verify ownership and get photo URLs
      final postResponse = await SupabaseConfig.client
          .from('posts')
          .select()
          .eq('id', postId)
          .single();

      final post = Post.fromJson(postResponse);

      if (post.userId != currentUserId) {
        throw Exception('You can only delete your own posts');
      }

      // Delete photos from storage
      for (var photoUrl in post.photoUrls) {
        try {
          // Extract path from URL
          final uri = Uri.parse(photoUrl);
          final path = uri.pathSegments.sublist(uri.pathSegments.indexOf('post-photos') + 1).join('/');

          await SupabaseConfig.client.storage.from('post-photos').remove([path]);
        } catch (e) {
          developer.log('Error deleting photo from storage: $e');
        }
      }

      // Delete post (this will cascade delete likes and comments due to foreign keys)
      await SupabaseConfig.client
          .from('posts')
          .delete()
          .eq('id', postId);

      print('🗑️ VOYAGR POST: Deleted post $postId');
    } catch (e) {
      print('❌ VOYAGR POST: Error deleting post: $e');
      developer.log('Error deleting post: $e');
      rethrow;
    }
  }

  /// Shares a post with image and caption
  static Future<void> sharePost({
    required Post post,
  }) async {
    try {
      print('📤 VOYAGR SHARE: Sharing post ${post.id}');

      // Download the first image to temporary directory
      if (post.photoUrls.isEmpty) {
        throw Exception('Post has no photos to share');
      }

      final imageUrl = post.photoUrls[0];
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Save image to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'voyagr_post_${post.id}.jpg';
      final filePath = '${tempDir.path}/$fileName';
      final imageFile = File(filePath);
      await imageFile.writeAsBytes(response.bodyBytes);

      // Create caption preview (max 100 characters)
      String captionPreview = post.caption ?? 'Check out this post on Voyagr!';
      if (captionPreview.length > 100) {
        captionPreview = '${captionPreview.substring(0, 97)}...';
      }

      // Create share text with deep link
      final shareText = '''$captionPreview

❤️ ${post.likeCount ?? 0} likes • 💬 ${post.commentCount ?? 0} comments

View on Voyagr: voyagr://post/${post.id}''';

      // Share using native share sheet
      await Share.shareXFiles(
        [XFile(filePath)],
        text: shareText,
        subject: 'Check out this post on Voyagr',
      );

      print('✅ VOYAGR SHARE: Post shared successfully');
    } catch (e) {
      print('❌ VOYAGR SHARE: Error sharing post: $e');
      developer.log('Error sharing post: $e');
      rethrow;
    }
  }

  /// Gets a single post by ID
  static Future<Post> getPostById({
    required String postId,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;

    try {
      print('🔍 VOYAGR POST: Fetching post $postId');

      final response = await SupabaseConfig.client
          .from('posts')
          .select()
          .eq('id', postId)
          .single();

      final post = Post.fromJson(response);

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

      // Check if current user liked the post
      if (currentUserId != null) {
        final userLikeResponse = await SupabaseConfig.client
            .from('post_likes')
            .select()
            .eq('post_id', post.id)
            .eq('user_id', currentUserId)
            .maybeSingle();
        post.isLikedByCurrentUser = userLikeResponse != null;
      }

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

      print('✅ VOYAGR POST: Found post $postId');

      return post;
    } catch (e) {
      print('❌ VOYAGR POST: Error fetching post: $e');
      developer.log('Error fetching post by ID: $e');
      rethrow;
    }
  }
}
