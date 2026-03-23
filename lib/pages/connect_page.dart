import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:developer' as developer;
import '../models/trip.dart';
import 'create_trip_page.dart';
import '../services/matching_service.dart';
import '../services/messaging_service.dart';
import '../supabase_config.dart';
import 'home_page.dart';
import '../widgets/swipe_card.dart';
import 'match_page.dart';

class ConnectPage extends StatefulWidget {
  final List<Trip> trips;
  final Function(Trip) onTripAdded;
  final Function(int)? onNavigate;

  const ConnectPage({
    super.key,
    required this.trips,
    required this.onTripAdded,
    this.onNavigate,
  });

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> with SingleTickerProviderStateMixin {
  int _currentCardIndex = 0;
  double _dragX = 0;
  double _dragY = 0;
  double _angle = 0;
  bool _isDragging = false;
  int _currentPhotoIndex = 0;
  double _verticalDrag = 0;

  Trip? _selectedTrip;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoadingProfiles = false;

  @override
  void initState() {
    super.initState();
    // Auto-select the first trip if available
    if (widget.trips.isNotEmpty) {
      _selectedTrip = widget.trips.first;
      _loadProfiles();
    }
  }

  @override
  void didUpdateWidget(ConnectPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If trips list changed and we had a selected trip, try to maintain selection
    if (widget.trips != oldWidget.trips && _selectedTrip != null) {
      // Check if the selected trip still exists in the new trips list
      final stillExists = widget.trips.any((trip) =>
        trip.city == _selectedTrip!.city &&
        trip.dateType == _selectedTrip!.dateType &&
        trip.month == _selectedTrip!.month &&
        trip.year == _selectedTrip!.year
      );

      if (!stillExists) {
        // Trip was deleted or doesn't exist anymore, select first available trip
        if (widget.trips.isNotEmpty) {
          _selectedTrip = widget.trips.first;
          _loadProfiles();
        } else {
          // No trips left, clear selection
          setState(() {
            _selectedTrip = null;
            _profiles = [];
          });
        }
      }
    } else if (widget.trips.isNotEmpty && _selectedTrip == null) {
      // No trip was selected but trips are now available, select first one
      _selectedTrip = widget.trips.first;
      _loadProfiles();
    }
  }

  Future<void> _loadProfiles() async {
    try {
      setState(() {
        _isLoadingProfiles = true;
      });

      print('═══════════════════════════════');
      print('🔄 VOYAGR: LOADING PROFILES');
      print('📍 Selected trip: ${_selectedTrip?.city}, ${_selectedTrip?.dateType}, ${_selectedTrip?.month} ${_selectedTrip?.year}');

      // Convert month-based trips to date ranges for matching
      DateTime? startDate = _selectedTrip?.startDate;
      DateTime? endDate = _selectedTrip?.endDate;

      if (_selectedTrip?.dateType == 'month' &&
          _selectedTrip?.month != null &&
          _selectedTrip?.year != null) {
        // Convert month name to number
        final monthMap = {
          'January': 1, 'February': 2, 'March': 3, 'April': 4,
          'May': 5, 'June': 6, 'July': 7, 'August': 8,
          'September': 9, 'October': 10, 'November': 11, 'December': 12,
        };
        final monthNum = monthMap[_selectedTrip!.month];
        if (monthNum != null) {
          startDate = DateTime(_selectedTrip!.year!, monthNum, 1);
          // Last day of the month
          endDate = DateTime(_selectedTrip!.year!, monthNum + 1, 0);
          print('📅 Converted month to date range: $startDate to $endDate');
        }
      } else {
        print('📅 Using specific dates: $startDate to $endDate');
      }

      final profiles = await MatchingService.getPotentialMatches(
        selectedCity: _selectedTrip?.city,
        startDate: startDate,
        endDate: endDate,
      );

      print('✅ Received ${profiles.length} total profiles');
      print('═══════════════════════════════');

      if (mounted) {
        setState(() {
          _profiles = profiles;
          _isLoadingProfiles = false;
        });
      }
    } catch (e) {
      print('❌ VOYAGR: Error loading profiles: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfiles = false;
        });
      }
    }
  }

  /// Handles swipe action - saves to database and checks for mutual match
  Future<void> _handleSwipe(Map<String, dynamic> profile, bool isLike) async {
    final currentUser = SupabaseConfig.auth.currentUser;
    if (currentUser == null) {
      print('❌ VOYAGR SWIPE: No user logged in');
      return;
    }

    // Only track swipes on real users, not fake profiles
    final isRealUser = profile['isRealUser'] == true;
    if (!isRealUser) {
      print('ℹ️ VOYAGR SWIPE: Swiped on fake profile ${profile['name']}, not tracking');
      return;
    }

    final swipedUserId = profile['id'] as String;
    print('═══════════════════════════════');
    print('💫 VOYAGR SWIPE: ${isLike ? "LIKE ❤️" : "PASS 👎"} on ${profile['name']} ($swipedUserId)');
    print('   Current user: ${currentUser.id}');
    print('   Swiped user: $swipedUserId');

    try {
      // Save swipe to database
      await SupabaseConfig.client.from('swipes').insert({
        'user_id': currentUser.id,
        'swiped_user_id': swipedUserId,
        'is_like': isLike,
      });

      print('✅ VOYAGR SWIPE: Saved to database');

      // Only check for match if this was a like
      if (isLike) {
        await _checkForMatch(swipedUserId, profile);
      } else {
        print('ℹ️ VOYAGR SWIPE: Pass - not checking for match');
      }
      print('═══════════════════════════════');
    } catch (e) {
      final errorString = e.toString();

      // Check if this is a duplicate swipe error
      if (errorString.contains('duplicate key') || errorString.contains('23505')) {
        print('ℹ️ VOYAGR SWIPE: Already swiped on this user before');

        // If this was a like, still check for match (maybe they liked back after our swipe)
        if (isLike) {
          print('   Checking if they liked back since our last swipe...');
          await _checkForMatch(swipedUserId, profile);
        }
      } else {
        print('❌ VOYAGR SWIPE: Error saving swipe: $e');
      }
      print('═══════════════════════════════');
    }
  }

  /// Checks if the other user has also liked us (mutual match)
  Future<void> _checkForMatch(String otherUserId, Map<String, dynamic> profile) async {
    final currentUser = SupabaseConfig.auth.currentUser;
    if (currentUser == null) return;

    try {
      print('🔍 VOYAGR MATCH: Checking for mutual like...');
      print('   Looking for swipe where:');
      print('   - user_id = $otherUserId (they swiped)');
      print('   - swiped_user_id = ${currentUser.id} (on me)');
      print('   - is_like = true');

      // Check if the other user has liked us
      final response = await SupabaseConfig.client
          .from('swipes')
          .select()
          .eq('user_id', otherUserId)
          .eq('swiped_user_id', currentUser.id)
          .eq('is_like', true)
          .maybeSingle();

      print('   Query result: ${response != null ? "FOUND ✅" : "NOT FOUND ❌"}');

      if (response != null) {
        print('🎉 VOYAGR MATCH: MUTUAL MATCH DETECTED!');
        print('   Match details: $response');
        await _createMatch(otherUserId, profile);
      } else {
        print('ℹ️ VOYAGR MATCH: No mutual match yet');
        print('   They have not liked you back (or swipe not found in database)');
      }
    } catch (e) {
      print('❌ VOYAGR MATCH: Error checking for match: $e');
    }
  }

  /// Creates a match record and shows celebration popup
  Future<void> _createMatch(String otherUserId, Map<String, dynamic> profile) async {
    final currentUser = SupabaseConfig.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Ensure user IDs are ordered correctly (smaller first)
      final userId1 = currentUser.id.compareTo(otherUserId) < 0 ? currentUser.id : otherUserId;
      final userId2 = currentUser.id.compareTo(otherUserId) < 0 ? otherUserId : currentUser.id;

      bool isNewMatch = true;
      String? matchId;

      // Try to create match record
      try {
        final matchResponse = await SupabaseConfig.client.from('matches').insert({
          'user1_id': userId1,
          'user2_id': userId2,
        }).select().single();

        matchId = matchResponse['id'] as String;
        print('✅ VOYAGR MATCH: New match record created!');
      } catch (e) {
        // Match might already exist - fetch existing match
        print('ℹ️ VOYAGR MATCH: Match already exists, checking for existing match');
        final existingMatch = await SupabaseConfig.client
            .from('matches')
            .select()
            .eq('user1_id', userId1)
            .eq('user2_id', userId2)
            .maybeSingle();

        if (existingMatch != null) {
          matchId = existingMatch['id'] as String;
          isNewMatch = false;
          print('✅ VOYAGR MATCH: Found existing match');
        } else {
          throw e;
        }
      }

      // Get or create conversation
      final conversation = await MessagingService.getOrCreateConversation(
        otherUserId: otherUserId,
      );

      // If we have a selected trip with a city, create city match messages
      if (_selectedTrip != null && _selectedTrip!.city.isNotEmpty) {
        final isNewCityMatch = await MessagingService.createCityMatchMessages(
          conversationId: conversation.id,
          otherUserId: otherUserId,
          city: _selectedTrip!.city,
        );

        print(isNewCityMatch
            ? '✅ VOYAGR MATCH: Created city match messages for ${_selectedTrip!.city}'
            : 'ℹ️ VOYAGR MATCH: Already matched in ${_selectedTrip!.city}');
      }

      // Show celebration popup
      if (mounted) {
        _showMatchPopup(profile);
      }
    } catch (e) {
      print('❌ VOYAGR MATCH: Error creating match: $e');
      // Still show popup even if database insert fails
      if (mounted) {
        _showMatchPopup(profile);
      }
    }
  }

  /// Handles the completion of a swipe gesture
  Future<void> _handleSwipeComplete(bool isRightSwipe) async {
    if (_currentCardIndex >= _profiles.length) return;

    final currentProfile = _profiles[_currentCardIndex];

    // Animate card off screen
    setState(() {
      _dragX = isRightSwipe ? 500 : -500;
      _angle = isRightSwipe ? 0.3 : -0.3;
    });

    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 300));

    // Process the swipe
    await _handleSwipe(currentProfile, isRightSwipe);

    // Move to next card
    setState(() {
      _currentCardIndex++;
      _dragX = 0;
      _dragY = 0;
      _angle = 0;
      _isDragging = false;
      _currentPhotoIndex = 0;
    });
  }

  /// Shows full-screen match page when a match is made
  void _showMatchPopup(Map<String, dynamic> profile) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MatchPage(
          matchedProfile: profile,
          city: _selectedTrip?.city,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showTripPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (context) {
        if (widget.trips.isEmpty) {
          // Show "no trips" message
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You have no trips planned',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E55C6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Let's hop on that!",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Navigate to create trip page
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateTripPage()),
                      );
                      if (result != null && result is Trip) {
                        widget.onTripAdded(result);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E55C6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Create a Trip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Show trip list
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Select a Trip',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E55C6),
                  ),
                ),
              ),
              const Divider(),
              // Trip list
              ...widget.trips.map((trip) {
                final isSelected = _selectedTrip == trip;
                return ListTile(
                  leading: Text(
                    trip.getCountryFlag(),
                    style: TextStyle(
                      fontSize: 24,
                      color: isSelected ? const Color(0xFF2E55C6) : Colors.grey,
                    ),
                  ),
                  title: Text(
                    trip.city,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF2E55C6) : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    trip.getDateDisplay(),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF2E55C6) : Colors.grey,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF2E55C6))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedTrip = trip;
                    });
                    Navigator.pop(context);
                    // Reload profiles for the selected trip
                    _loadProfiles();
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Static placeholder profiles using Austin images
    final List<Map<String, String>> placeholderCards = [
      {'name': 'AUSTIN', 'image': 'lib/assets/AUSTIN/Austin 1.jpg'},
      {'name': 'ANDREI', 'image': 'lib/assets/AUSTIN/Austin 2.jpg'},
      {'name': 'TAYSON', 'image': 'lib/assets/AUSTIN/Austin 3.jpg'},
      {'name': 'NICK', 'image': 'lib/assets/AUSTIN/Austin 4.jpg'},
      {'name': 'ALDRIC', 'image': 'lib/assets/AUSTIN/Austin 5.jpg'},
      {'name': 'BRODY', 'image': 'lib/assets/AUSTIN/Austin 6.jpg'},
    ];

    return Stack(
        clipBehavior: Clip.none,
        children: [
          // White background
          Positioned.fill(
            child: Container(color: Colors.white),
          ),
          // Voyagr star icon - top right, behind content
          Positioned(
            top: 0,
            right: 0,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(50.0, 0.0)
                ..rotateZ(-0.18),
              child: Image.asset(
                'lib/assets/voyagr_star_light_blue.png',
                width: 148.81,
                height: 199.54,
              ),
            ),
          ),
          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // "CONNECT" header
                GestureDetector(
                  onTap: () => _showTripPicker(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text(
                        'CONNECT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF2E55C6),
                          fontSize: 96,
                          fontFamily: 'Mona Sans SemiCondensed',
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
            // Scrollable grid of profile cards
            Expanded(
              child: _isLoadingProfiles
                  ? Center(
                      child: Lottie.asset(
                        'lib/assets/VOYAGR STAR YELLOW.json',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 130),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 175 / 219,
                        ),
                        itemCount: placeholderCards.length,
                        itemBuilder: (context, index) {
                          final card = placeholderCards[index];
                          return _buildProfileCard(
                            name: card['name']!,
                            imagePath: card['image']!,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
        ],
    );
  }

  Widget _buildProfileCard({required String name, required String imagePath}) {
    return GestureDetector(
      onTap: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Profile',
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) {
            return GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            );
          },
        );
      },
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 6,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Blue banner behind name (slightly rotated)
          Positioned(
            left: 10,
            bottom: 8,
            child: Transform(
              transform: Matrix4.identity()..rotateZ(-0.05),
              child: Container(
                width: name.length * 16.0 + 16,
                height: 29,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E55C6),
                ),
              ),
            ),
          ),
          // Decorative star at end of banner
          Positioned(
            left: 10 + name.length * 16.0 + 8,
            bottom: 10,
            child: Image.asset(
              'lib/assets/star_marker_64.png',
              width: 25,
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
          // Name text on the banner
          Positioned(
            left: 16,
            bottom: 10,
            child: Transform(
              transform: Matrix4.identity()..rotateZ(-0.05),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Mona Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildProfileImage(String imagePath) {
    // Check if it's a network URL or local asset
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF2C2C2E),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 100,
                color: Color(0xFF48484A),
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF2C2C2E),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E55C6),
              ),
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF2C2C2E),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 100,
                color: Color(0xFF48484A),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildPillBox(String text) {
    // Map text to emojis
    final Map<String, String> emojiMap = {
      'Sport': '⚽',
      'Coffee': '☕',
      'Photography': '📷',
      'LGBTQ': '🏳️‍🌈',
    };

    final emoji = emojiMap[text] ?? '';

    // Check if this interest/tag matches (for now just checking Sport)
    final bool isMatch = text == 'Sport';
    final Color fillColor = isMatch ? const Color(0xFFFEFFC1) : const Color(0xFFC3DAF4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(
          color: const Color(0xFF2E55C6),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        emoji.isNotEmpty ? '$emoji $text' : text,
        style: const TextStyle(
          color: Color(0xFF2E55C6),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
