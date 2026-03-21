class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String messageType; // 'text', 'shared_post', 'match_notification', 'city_divider'
  final String? city; // City for divider messages
  final String? sharedPostImage;  // Path to shared post image
  final String? sharedPostCaption; // Caption for shared post
  final int? sharedPostLikes;     // Like count for shared post
  final int? sharedPostComments;  // Comment count for shared post

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.messageType = 'text',
    this.city,
    this.sharedPostImage,
    this.sharedPostCaption,
    this.sharedPostLikes,
    this.sharedPostComments,
  });

  bool get isSharedPost => messageType == 'shared_post';
  bool get isMatchNotification => messageType == 'match_notification';
  bool get isCityDivider => messageType == 'city_divider';
  bool get isSystemMessage => isMatchNotification || isCityDivider;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      messageType: json['message_type'] as String? ?? 'text',
      city: json['city'] as String?,
      sharedPostImage: json['shared_post_image'] as String?,
      sharedPostCaption: json['shared_post_caption'] as String?,
      sharedPostLikes: json['shared_post_likes'] as int?,
      sharedPostComments: json['shared_post_comments'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'message_type': messageType,
      'city': city,
      'shared_post_image': sharedPostImage,
      'shared_post_caption': sharedPostCaption,
      'shared_post_likes': sharedPostLikes,
      'shared_post_comments': sharedPostComments,
    };
  }
}
