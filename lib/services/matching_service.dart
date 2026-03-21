import 'dart:developer' as developer;
import '../supabase_config.dart';

class MatchingService {
  /// Gets potential matches for the current user
  /// Combines real Supabase users with fake profiles
  static Future<List<Map<String, dynamic>>> getPotentialMatches({
    String? selectedCity,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    try {
      // Only exclude users who have already matched in THIS specific city
      // This allows re-matching with the same user in different cities
      final Set<String> matchedUserIdsForThisCity = {};

      if (selectedCity != null) {
        print('🔍 VOYAGR MATCHING: Fetching existing matches for city: $selectedCity');

        // Get all matches for current user
        final matchesResponse = await SupabaseConfig.client
            .from('matches')
            .select()
            .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

        // For each match, check if they've already matched in this city
        for (var match in matchesResponse as List) {
          final otherUserId = match['user1_id'] == currentUserId
              ? match['user2_id']
              : match['user1_id'];

          // Get the conversation for this match
          // Ensure we're looking for the correct ordered pair
          final userId1 = currentUserId.compareTo(otherUserId) < 0 ? currentUserId : otherUserId;
          final userId2 = currentUserId.compareTo(otherUserId) < 0 ? otherUserId : currentUserId;

          final conversationResponse = await SupabaseConfig.client
              .from('conversations')
              .select('id')
              .eq('user1_id', userId1)
              .eq('user2_id', userId2)
              .maybeSingle();

          if (conversationResponse != null) {
            final conversationId = conversationResponse['id'] as String;

            // Check if there's a city divider for this city in the conversation
            final cityDividerResponse = await SupabaseConfig.client
                .from('messages')
                .select()
                .eq('conversation_id', conversationId)
                .eq('message_type', 'city_divider')
                .eq('city', selectedCity)
                .maybeSingle();

            if (cityDividerResponse != null) {
              // They've already matched in this city
              matchedUserIdsForThisCity.add(otherUserId as String);
              print('   Already matched with $otherUserId in $selectedCity');
            }
          }
        }
        print('🚫 VOYAGR MATCHING: Excluding ${matchedUserIdsForThisCity.length} users already matched in $selectedCity');
      } else {
        print('ℹ️ VOYAGR MATCHING: No city selected, not excluding any users');
      }

      // Fetch real users from Supabase
      final List<Map<String, dynamic>> realUsers = [];

      // Base query: exclude current user
      // Only query columns that actually exist in the schema
      var query = SupabaseConfig.client
          .from('users')
          .select('id, name, birthday, bio, interests, tags')
          .neq('id', currentUserId);

      // If a city and dates are selected, filter by matching trips
      if (selectedCity != null && startDate != null && endDate != null) {
        print('🔍 VOYAGR MATCHING: Searching for city: $selectedCity, dates: $startDate to $endDate');

        // Get all trips to the same city (not just the current user's)
        // Use ilike for case-insensitive matching
        final allTripsResponse = await SupabaseConfig.client
            .from('trips')
            .select('user_id, city, start_date, end_date, date_type, month, year')
            .ilike('city', selectedCity)
            .neq('user_id', currentUserId);

        print('🔍 VOYAGR MATCHING: Found ${(allTripsResponse as List).length} trips to $selectedCity from other users');
        print('🔍 VOYAGR MATCHING: Current user ID: $currentUserId');
        print('🔍 VOYAGR MATCHING: Searching city: $selectedCity');

        // Debug: Also check how many trips exist total for this city (including current user)
        final allCityTrips = await SupabaseConfig.client
            .from('trips')
            .select('user_id, city')
            .ilike('city', selectedCity);
        print('🔍 VOYAGR MATCHING: Total trips to $selectedCity (all users): ${(allCityTrips as List).length}');

        // Print all trips found
        for (var trip in allTripsResponse) {
          print('   Trip data: user=${trip['user_id']}, city=${trip['city']}, type=${trip['date_type']}, month=${trip['month']}, year=${trip['year']}');
        }

        // Filter for overlapping dates manually for better debugging
        final matchingUserIds = <String>{};
        for (var trip in allTripsResponse) {
          try {
            DateTime? tripStart;
            DateTime? tripEnd;

            // Handle different date types
            if (trip['date_type'] == 'specific' &&
                trip['start_date'] != null &&
                trip['end_date'] != null) {
              tripStart = DateTime.parse(trip['start_date']);
              tripEnd = DateTime.parse(trip['end_date']);
            } else if (trip['date_type'] == 'month' &&
                       trip['month'] != null &&
                       trip['year'] != null) {
              // Convert month to date range
              final monthMap = {
                'January': 1, 'February': 2, 'March': 3, 'April': 4,
                'May': 5, 'June': 6, 'July': 7, 'August': 8,
                'September': 9, 'October': 10, 'November': 11, 'December': 12,
              };
              final monthNum = monthMap[trip['month']];
              if (monthNum != null) {
                tripStart = DateTime(trip['year'], monthNum, 1);
                tripEnd = DateTime(trip['year'], monthNum + 1, 0);
              }
            } else if (trip['date_type'] == 'unknown') {
              // Unknown dates match everything
              matchingUserIds.add(trip['user_id'] as String);
              print('✅ VOYAGR MATCHING: Match found (unknown dates): ${trip['user_id']}');
              continue;
            }

            if (tripStart != null && tripEnd != null) {
              // Check if dates overlap
              // Trips overlap if: trip starts before your trip ends AND trip ends after your trip starts
              final overlaps = tripStart.isBefore(endDate.add(const Duration(days: 1))) &&
                              tripEnd.isAfter(startDate.subtract(const Duration(days: 1)));

              if (overlaps) {
                matchingUserIds.add(trip['user_id'] as String);
                print('✅ VOYAGR MATCHING: Match found: ${trip['user_id']} ($tripStart to $tripEnd)');
              } else {
                print('❌ VOYAGR MATCHING: No overlap for ${trip['user_id']} ($tripStart to $tripEnd)');
              }
            }
          } catch (e) {
            print('❌ VOYAGR MATCHING: Error parsing dates for trip: $e');
          }
        }

        print('🎯 VOYAGR MATCHING: Total ${matchingUserIds.length} matching users');

        if (matchingUserIds.isEmpty) {
          // No matching users for this trip, show all users instead
          print('⚠️ VOYAGR MATCHING: No matches found, showing all users');
          final response = await query.limit(10);
          realUsers.addAll((response as List).cast<Map<String, dynamic>>());
        } else {
          // Filter to users with matching trips
          print('✅ VOYAGR MATCHING: Fetching ${matchingUserIds.length} matching user profiles');
          final response = await query.inFilter('id', matchingUserIds.toList()).limit(10);
          realUsers.addAll((response as List).cast<Map<String, dynamic>>());
        }
      } else {
        // No trip selected, just get any users
        print('ℹ️ VOYAGR MATCHING: No trip selected, showing all users');
        final response = await query.limit(10);
        realUsers.addAll((response as List).cast<Map<String, dynamic>>());
      }

      // Convert Supabase users to the same format as fake profiles
      final formattedRealUsers = realUsers.map((user) {
        // Calculate age from birthday
        int? age;
        if (user['birthday'] != null) {
          try {
            final birthday = DateTime.parse(user['birthday']);
            age = DateTime.now().year - birthday.year;
          } catch (e) {
            developer.log('Error parsing birthday: $e');
          }
        }

        // Gender column doesn't exist, use default pronouns
        String pronouns = 'They/Them';

        // Need at least one photo for the UI to work
        // profile_image_url column doesn't exist, use placeholder
        List<String> photos = ['https://placeholder.com/profile'];

        return {
          'id': user['id'],
          'name': user['name'] ?? 'Unknown',
          'age': age ?? 25,
          'pronouns': pronouns,
          'photos': photos,
          'bio': user['bio'] ?? 'No bio yet',
          'interests': user['interests'] != null
              ? (user['interests'] as List).cast<String>()
              : <String>[],
          'tags': user['tags'] != null
              ? (user['tags'] as List).cast<String>()
              : <String>[],
          'homebase': 'Unknown', // homebase column doesn't exist in users table
          'isRealUser': true,
        };
      }).toList();

      // Demo profile
      final fakeProfiles = [
        {
          'name': 'Austin',
          'age': 27,
          'pronouns': 'He/Him',
          'photos': <String>[
            'lib/assets/AUSTIN/Austin 1.jpg',
            'lib/assets/AUSTIN/Austin 2.jpg',
            'lib/assets/AUSTIN/Austin 3.jpg',
            'lib/assets/AUSTIN/Austin 4.jpg',
            'lib/assets/AUSTIN/Austin 5.jpg',
            'lib/assets/AUSTIN/Austin 6.jpg',
          ],
          'bio': 'Backpacking the globe and super stoked to be heading to Tokyo next. Always up for karaoke, street food, and good vibes. Let\'s connect and explore together!',
          'interests': <String>['Clubbing', 'Fashion', 'Foodie', 'Formula 1', 'Karaoke'],
          'tags': <String>['Adventurous', 'Night Owl'],
          'travel_style': 'Adventurous',
          'city': 'Tokyo',
          'country': 'Japan',
          'homebase': 'Los Angeles',
          'isRealUser': false,
        },
      ];

      // Filter out users already-matched in THIS city from the results
      final filteredRealUsers = formattedRealUsers.where((user) {
        return !matchedUserIdsForThisCity.contains(user['id']);
      }).toList();

      // Combine real users and fake profiles
      // Real users first, then fake profiles
      final allProfiles = [...filteredRealUsers, ...fakeProfiles];

      print('📋 VOYAGR MATCHING: Returning ${filteredRealUsers.length} real users (${formattedRealUsers.length - filteredRealUsers.length} excluded) + ${fakeProfiles.length} fake profiles');

      return allProfiles;
    } catch (e) {
      print('❌ VOYAGR MATCHING: Error fetching potential matches: $e');
      rethrow;
    }
  }
}
