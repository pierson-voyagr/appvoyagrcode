import '../models/trip.dart';
import '../models/location.dart';
import '../supabase_config.dart';

class ItineraryAiService {
  // Set to true to use the real AI backend, false for simulated responses
  static const bool _useRealAi = true;

  // Store conversation history for context
  static final List<Map<String, String>> _conversationHistory = [];

  /// Sends a message to the AI itinerary builder and gets a response
  static Future<String> sendMessage({
    required String message,
    required Trip trip,
    List<Location>? savedLocations,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      // Use simulated responses for testing, or real AI when enabled
      if (!_useRealAi) {
        return await _simulateAiResponse(message, trip, savedLocations);
      }

      // Add user message to history
      _conversationHistory.add({'role': 'user', 'content': message});

      // Call Supabase Edge Function using the SDK
      final res = await SupabaseConfig.client.functions.invoke(
        'itinerary-ai',
        body: {
          'message': message,
          'trip': {
            'city': trip.city,
            'country': trip.country,
            'start_date': trip.startDate?.toIso8601String(),
            'end_date': trip.endDate?.toIso8601String(),
            'date_display': trip.getDateDisplay(),
          },
          'saved_locations': savedLocations?.map((loc) => {
            'name': loc.name,
            'category': loc.category,
            'latitude': loc.latitude,
            'longitude': loc.longitude,
          }).toList(),
          'conversation_history': _conversationHistory,
          'user_id': SupabaseConfig.auth.currentUser?.id,
        },
      );

      final data = res.data;

      if (data != null && data['output_text'] != null) {
        final aiResponse = data['output_text'] as String;

        // Add AI response to history
        _conversationHistory.add({'role': 'assistant', 'content': aiResponse});

        return aiResponse;
      } else if (data != null && data['error'] != null) {
        print('Edge Function error: ${data['error']}');
        throw Exception(data['error']);
      } else {
        throw Exception('Invalid response from AI service');
      }
    } catch (e) {
      print('Error in AI service: $e');
      return 'I\'m having trouble connecting right now. Please try again in a moment.';
    }
  }

  /// Clears conversation history (call when starting a new chat)
  static void clearHistory() {
    _conversationHistory.clear();
  }

  /// Simulates AI responses for testing/demo purposes
  static Future<String> _simulateAiResponse(
    String message,
    Trip trip,
    List<Location>? savedLocations,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final lowerMessage = message.toLowerCase();

    // Initial greeting / start
    if (lowerMessage.contains('start') || lowerMessage.contains('begin') || lowerMessage.contains('help')) {
      return '''Great! I'm excited to help you plan your trip to ${trip.city}! 🌟

I can see you're traveling ${trip.getDateDisplay()}. ${savedLocations != null && savedLocations.isNotEmpty ? 'I also notice you\'ve saved ${savedLocations.length} location${savedLocations.length > 1 ? 's' : ''} that you\'re interested in.' : ''}

To create the perfect itinerary, I'd love to know a bit more about your preferences:

**What's most important to you on this trip?**
1. Cultural experiences & sightseeing
2. Food & dining experiences
3. Nightlife & entertainment
4. Relaxation & wellness
5. A mix of everything

Just type the number or describe what you're looking for!''';
    }

    // Preferences response
    if (lowerMessage.contains('1') || lowerMessage.contains('cultural') || lowerMessage.contains('sightseeing')) {
      return '''Perfect! Cultural experiences it is! 🏛️

${trip.city} has so much history and culture to explore. Here's what I'm thinking for your itinerary:

**Day 1 - Iconic Landmarks**
• Morning: Start with the most famous attractions
• Afternoon: Explore historic neighborhoods
• Evening: Sunset at a scenic viewpoint

**Day 2 - Museums & Art**
• Morning: Visit the top-rated museum
• Afternoon: Art galleries and local crafts
• Evening: Traditional dinner experience

Would you like me to:
A) Add specific times and restaurant recommendations
B) Include more off-the-beaten-path spots
C) Adjust the pace (more relaxed or more packed)

What sounds good?''';
    }

    if (lowerMessage.contains('2') || lowerMessage.contains('food') || lowerMessage.contains('dining')) {
      return '''A foodie trip - excellent choice! 🍽️

${trip.city} has an incredible culinary scene. Let me plan a delicious adventure:

**Day 1 - Local Favorites**
• Breakfast: Famous local café
• Lunch: Street food tour
• Dinner: Award-winning restaurant

**Day 2 - Hidden Gems**
• Breakfast: Neighborhood bakery
• Lunch: Chef's table experience
• Dinner: Rooftop dining with views

Should I:
A) Focus on budget-friendly options
B) Include cooking classes or food tours
C) Add Michelin-starred recommendations

Let me know your preference!''';
    }

    // Default helpful response
    return '''Thanks for sharing! Let me work on incorporating that into your ${trip.city} itinerary.

Based on what you've told me, I'm putting together a personalized plan that balances your interests with the best of what ${trip.city} has to offer.

Is there anything specific you want to make sure we include? For example:
• A particular restaurant or attraction
• Time for shopping or leisure
• Any dietary restrictions or accessibility needs

Just let me know and I'll refine the itinerary!''';
  }

  /// Gets an initial greeting message from the AI
  static String getInitialGreeting(Trip trip, List<Location>? savedLocations) {
    final locationCount = savedLocations?.length ?? 0;
    final locationText = locationCount > 0
        ? '\n\nI can see you\'ve already saved $locationCount place${locationCount > 1 ? 's' : ''} you\'re interested in - I\'ll make sure to include ${locationCount > 1 ? 'those' : 'that'} in my suggestions!'
        : '';

    return '''Hey there! 👋 I'm your AI travel assistant, ready to help you build the perfect itinerary for ${trip.city}.

You're traveling **${trip.getDateDisplay()}** - that gives us some great options to work with!$locationText

When you're ready, just tell me what kind of experience you're looking for, or type **"start"** and I'll guide you through the process step by step.''';
  }
}
