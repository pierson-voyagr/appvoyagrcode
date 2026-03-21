class Post {
  final String id;
  final String userId;
  final String? caption;
  final List<String> photoUrls;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Metadata fields (calculated from joins)
  int? likeCount;
  int? commentCount;
  bool? isLikedByCurrentUser;
  bool? isPinnedByCurrentUser;
  String? userName;
  String? userProfileImageUrl;

  Post({
    required this.id,
    required this.userId,
    this.caption,
    required this.photoUrls,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.likeCount,
    this.commentCount,
    this.isLikedByCurrentUser,
    this.isPinnedByCurrentUser,
    this.userName,
    this.userProfileImageUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      caption: json['caption'] as String?,
      photoUrls: (json['photo_urls'] as List?)?.cast<String>() ?? [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      likeCount: json['like_count'] as int?,
      commentCount: json['comment_count'] as int?,
      isLikedByCurrentUser: json['is_liked_by_current_user'] as bool?,
      isPinnedByCurrentUser: json['is_pinned_by_current_user'] as bool?,
      userName: json['user_name'] as String?,
      userProfileImageUrl: json['user_profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'caption': caption,
      'photo_urls': photoUrls,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_liked_by_current_user': isLikedByCurrentUser,
      'is_pinned_by_current_user': isPinnedByCurrentUser,
      'user_name': userName,
      'user_profile_image_url': userProfileImageUrl,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? caption,
    List<String>? photoUrls,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    int? commentCount,
    bool? isLikedByCurrentUser,
    bool? isPinnedByCurrentUser,
    String? userName,
    String? userProfileImageUrl,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      caption: caption ?? this.caption,
      photoUrls: photoUrls ?? this.photoUrls,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isPinnedByCurrentUser: isPinnedByCurrentUser ?? this.isPinnedByCurrentUser,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
    );
  }
}

class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  // User metadata
  String? userName;
  String? userProfileImageUrl;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userProfileImageUrl,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userProfileImageUrl: json['user_profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_name': userName,
      'user_profile_image_url': userProfileImageUrl,
    };
  }
}
