import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'connect_page.dart';
import 'trips_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import '../models/trip.dart';
import '../supabase_config.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  final Widget? navigateToThread;

  const HomePage({super.key, this.initialIndex = 0, this.navigateToThread});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadTrips();

    // Navigate to thread if provided (e.g., after sending message from match page)
    if (widget.navigateToThread != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => widget.navigateToThread!),
        );
      });
    }
  }
  final List<Trip> _trips = [];

  Future<void> _loadTrips() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) {
      print('❌ VOYAGR: Cannot load trips - No user logged in');
      return;
    }

    try {
      print('🔄 VOYAGR: Loading trips for user: ${user.id}');

      final response = await SupabaseConfig.client
          .from('trips')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      print('✅ VOYAGR: Loaded ${(response as List).length} trips from database');

      setState(() {
        _trips.clear();
        for (var tripData in response) {
          final trip = Trip(
            country: tripData['country'] ?? '',
            city: tripData['city'] ?? '',
            dateType: tripData['date_type'] ?? 'unknown',
            month: tripData['month'],
            year: tripData['year'],
            startDate: tripData['start_date'] != null
                ? DateTime.parse(tripData['start_date'])
                : null,
            endDate: tripData['end_date'] != null
                ? DateTime.parse(tripData['end_date'])
                : null,
            reasonForTrip: tripData['reason_for_trip'],
            requestedLocation: tripData['requested_location'],
          );
          _trips.add(trip);
          print('  📍 VOYAGR: Trip - ${trip.city}, ${trip.dateType}, ${trip.month} ${trip.year}');
        }
      });
    } catch (e) {
      print('❌ VOYAGR: Error loading trips: $e');
    }
  }

  Future<void> _addTrip(Trip trip) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) {
      print('❌ VOYAGR: Cannot add trip - No user logged in');
      return;
    }

    try {
      print('💾 VOYAGR: Saving trip to database: ${trip.city}, ${trip.dateType}, ${trip.month} ${trip.year}');

      // Insert trip into database
      await SupabaseConfig.client.from('trips').insert({
        'user_id': user.id,
        'country': trip.country,
        'city': trip.city,
        'date_type': trip.dateType,
        'month': trip.month,
        'year': trip.year,
        'start_date': trip.startDate?.toIso8601String(),
        'end_date': trip.endDate?.toIso8601String(),
        'reason_for_trip': trip.reasonForTrip,
        'requested_location': trip.requestedLocation,
      });

      print('✅ VOYAGR: Trip saved successfully to database');

      // Reload trips from database to ensure consistency
      await _loadTrips();
    } catch (e) {
      print('❌ VOYAGR: Error saving trip: $e');
      // Still add to local list if database save fails
      setState(() {
        _trips.add(trip);
      });
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    try {
      final currentUserId = SupabaseConfig.auth.currentUser?.id;
      if (currentUserId == null) {
        print('❌ VOYAGR: No user logged in');
        return;
      }

      print('🗑️ VOYAGR: Deleting trip to ${trip.city}...');

      // Delete from database
      await SupabaseConfig.client
          .from('trips')
          .delete()
          .eq('user_id', currentUserId)
          .eq('city', trip.city)
          .eq('country', trip.country);

      print('✅ VOYAGR: Trip deleted successfully from database');

      // Reload trips from database to ensure consistency
      await _loadTrips();
    } catch (e) {
      print('❌ VOYAGR: Error deleting trip: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TripsPage(
        trips: _trips,
        onTripAdded: _addTrip,
        onTripDeleted: _deleteTrip,
      ),
      ConnectPage(
        trips: _trips,
        onTripAdded: _addTrip,
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const MessagesPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: Stack(
        children: [
          pages[_currentIndex],
          // Floating pill-shaped navigation bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0x592E55C6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.luggage, 'STAY'),
                    _buildNavItem(1, Icons.people, 'CONNECT'),
                    _buildNavItem(2, Icons.message, 'MESSAGE'),
                    _buildNavItem(3, Icons.person, 'PROFILE'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFAF5A1) : const Color(0xFFE0E0E0),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFAF5A1) : const Color(0xFFE0E0E0),
              fontSize: 11,
              fontFamily: 'Mona Sans',
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
