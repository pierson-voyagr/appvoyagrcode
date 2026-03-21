import 'dart:developer' as developer;
import '../supabase_config.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class MessagingService {
  /// Gets or creates a conversation between two users
  static Future<Conversation> getOrCreateConversation({
    required String otherUserId,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    // Ensure user1_id < user2_id for the constraint
    final user1Id = currentUserId.compareTo(otherUserId) < 0
        ? currentUserId
        : otherUserId;
    final user2Id = currentUserId.compareTo(otherUserId) < 0
        ? otherUserId
        : currentUserId;

    try {
      // Try to find existing conversation
      final existingConversation = await SupabaseConfig.client
          .from('conversations')
          .select()
          .eq('user1_id', user1Id)
          .eq('user2_id', user2Id)
          .maybeSingle();

      if (existingConversation != null) {
        return Conversation.fromJson(existingConversation);
      }

      // Create new conversation if it doesn't exist
      final newConversation = await SupabaseConfig.client
          .from('conversations')
          .insert({
            'user1_id': user1Id,
            'user2_id': user2Id,
          })
          .select()
          .single();

      return Conversation.fromJson(newConversation);
    } catch (e) {
      developer.log('Error getting/creating conversation: $e');
      rethrow;
    }
  }

  /// Gets all conversations for the current user
  static Future<List<Conversation>> getConversations() async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      final response = await SupabaseConfig.client
          .from('conversations')
          .select()
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .order('last_message_at', ascending: false);

      final conversations = (response as List)
          .map((json) => Conversation.fromJson(json))
          .toList();

      // Fetch other user details for each conversation
      for (var conversation in conversations) {
        final otherUserId = conversation.getOtherUserId(currentUserId);
        final userData = await SupabaseConfig.client
            .from('users')
            .select('name, photo_urls')
            .eq('id', otherUserId)
            .maybeSingle();

        if (userData != null) {
          conversation.otherUserName = userData['name'] as String?;
          // Get first photo URL if available
          final photoUrls = userData['photo_urls'] as List?;
          if (photoUrls != null && photoUrls.isNotEmpty) {
            conversation.otherUserProfileImage = photoUrls[0] as String?;
          } else {
            conversation.otherUserProfileImage = null;
          }
        }

        // Get the user's current trip for city display
        final tripData = await SupabaseConfig.client
            .from('trips')
            .select('city')
            .eq('user_id', otherUserId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (tripData != null) {
          conversation.otherUserCity = tripData['city'] as String?;
        }
      }

      return conversations;
    } catch (e) {
      developer.log('Error getting conversations: $e');
      rethrow;
    }
  }

  /// Sends a message in a conversation
  static Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      final response = await SupabaseConfig.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': content,
      }).select().single();

      return Message.fromJson(response);
    } catch (e) {
      developer.log('Error sending message: $e');
      rethrow;
    }
  }

  /// Gets messages for a conversation
  static Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 50,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .limit(limit);

      return (response as List).map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      developer.log('Error getting messages: $e');
      rethrow;
    }
  }

  /// Marks messages as read
  static Future<void> markMessagesAsRead({
    required String conversationId,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      await SupabaseConfig.client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      developer.log('Error marking messages as read: $e');
      rethrow;
    }
  }

  /// Stream of messages for real-time updates
  static Stream<List<Message>> streamMessages({
    required String conversationId,
  }) {
    return SupabaseConfig.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }

  /// Stream of conversations for real-time updates
  static Stream<List<Map<String, dynamic>>> streamConversations() {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    return SupabaseConfig.client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false);
  }

  /// Gets unread message count for a conversation
  static Future<int> getUnreadCount({
    required String conversationId,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      final response = await SupabaseConfig.client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      developer.log('Error getting unread count: $e');
      return 0;
    }
  }

  /// Gets user profile data for displaying in bottom sheet
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final userData = await SupabaseConfig.client
          .from('users')
          .select('id, name, birthday, photo_urls, bio, interests, tags')
          .eq('id', userId)
          .single();

      // Calculate age from birthday
      int? age;
      if (userData['birthday'] != null) {
        try {
          final birthday = DateTime.parse(userData['birthday']);
          age = DateTime.now().year - birthday.year;
        } catch (e) {
          developer.log('Error parsing birthday: $e');
        }
      }

      return {
        'id': userData['id'],
        'name': userData['name'],
        'age': age,
        'photo_urls': userData['photo_urls'] ?? [],
        'bio': userData['bio'],
        'interests': userData['interests'] ?? [],
        'tags': userData['tags'] ?? [],
      };
    } catch (e) {
      developer.log('Error getting user profile: $e');
      rethrow;
    }
  }

  /// Gets matched users who haven't started a conversation yet
  static Future<List<Map<String, dynamic>>> getMatchedUsersWithoutConversation() async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      print('🔍 VOYAGR MATCHES: Fetching matches for user $currentUserId');

      // Get all matches for current user
      final matchesResponse = await SupabaseConfig.client
          .from('matches')
          .select()
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .order('matched_at', ascending: false);

      print('✅ VOYAGR MATCHES: Found ${(matchesResponse as List).length} total matches');

      // Get all conversations for current user
      final conversationsResponse = await SupabaseConfig.client
          .from('conversations')
          .select()
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

      final List<String> conversationUserIds = [];
      for (var conv in conversationsResponse as List) {
        final otherUserId = conv['user1_id'] == currentUserId
            ? conv['user2_id']
            : conv['user1_id'];
        conversationUserIds.add(otherUserId as String);
      }

      print('ℹ️ VOYAGR MATCHES: Found ${conversationUserIds.length} existing conversations');

      // Filter matches to only those without conversations
      final List<Map<String, dynamic>> matchedUsers = [];
      for (var match in matchesResponse) {
        final otherUserId = match['user1_id'] == currentUserId
            ? match['user2_id']
            : match['user1_id'];

        // Only include if no conversation exists
        if (!conversationUserIds.contains(otherUserId)) {
          // Fetch user details
          final userData = await SupabaseConfig.client
              .from('users')
              .select('id, name')
              .eq('id', otherUserId)
              .maybeSingle();

          if (userData != null) {
            // Get the matched city from the match record
            String? matchedCity = match['matched_city'] as String?;

            // If matched_city is not stored in the match record, try to find common trip city
            if (matchedCity == null) {
              print('ℹ️ VOYAGR MATCHES: No matched_city in match record, checking trips');

              // Get current user's trips
              final currentUserTrips = await SupabaseConfig.client
                  .from('trips')
                  .select('city')
                  .eq('user_id', currentUserId);

              // Get other user's trips
              final otherUserTrips = await SupabaseConfig.client
                  .from('trips')
                  .select('city')
                  .eq('user_id', otherUserId);

              // Find common city
              final currentUserCities = (currentUserTrips as List)
                  .map((t) => t['city'] as String?)
                  .where((city) => city != null)
                  .toSet();

              for (var trip in otherUserTrips as List) {
                final city = trip['city'] as String?;
                if (city != null && currentUserCities.contains(city)) {
                  matchedCity = city;
                  print('✅ VOYAGR MATCHES: Found common city: $city');
                  break;
                }
              }
            }

            matchedUsers.add({
              'id': userData['id'],
              'name': userData['name'] ?? 'Unknown',
              'matchedAt': match['matched_at'],
              'city': matchedCity,
            });
          }
        }
      }

      print('✅ VOYAGR MATCHES: Returning ${matchedUsers.length} matches without conversations');
      return matchedUsers;
    } catch (e) {
      print('❌ VOYAGR MATCHES: Error fetching matches: $e');
      developer.log('Error getting matched users: $e');
      return [];
    }
  }

  /// Creates city divider and match notification messages for a new city match
  /// Returns true if this is a new city match (re-match)
  static Future<bool> createCityMatchMessages({
    required String conversationId,
    required String otherUserId,
    required String city,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      print('🔍 VOYAGR CITY MATCH: Checking if $city is a new match');

      // Check if there's already a city divider for this city in this conversation
      final existingDivider = await SupabaseConfig.client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('message_type', 'city_divider')
          .eq('city', city)
          .maybeSingle();

      if (existingDivider != null) {
        print('ℹ️ VOYAGR CITY MATCH: City divider already exists for $city');
        return false; // Not a new match
      }

      print('✅ VOYAGR CITY MATCH: Creating new city match messages for $city');

      // Get other user's name
      final userData = await SupabaseConfig.client
          .from('users')
          .select('name')
          .eq('id', otherUserId)
          .single();

      final otherUserName = userData['name'] as String? ?? 'Unknown';

      // Create city divider message
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'receiver_id': otherUserId,
        'content': city,
        'message_type': 'city_divider',
        'city': city,
        'is_read': false,
      });

      // Create match notification message
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'receiver_id': otherUserId,
        'content': 'You and $otherUserName matched again!',
        'message_type': 'match_notification',
        'city': city,
        'is_read': false,
      });

      print('✅ VOYAGR CITY MATCH: Created city match messages successfully');
      return true; // New match created
    } catch (e) {
      print('❌ VOYAGR CITY MATCH: Error creating city match messages: $e');
      developer.log('Error creating city match messages: $e');
      rethrow;
    }
  }
}
