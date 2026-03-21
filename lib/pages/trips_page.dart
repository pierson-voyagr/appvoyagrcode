import 'package:flutter/material.dart';
import 'create_trip_page.dart';
import 'trip_details_page.dart';
import '../models/trip.dart';

class TripsPage extends StatefulWidget {
  final List<Trip> trips;
  final Function(Trip) onTripAdded;
  final Function(Trip)? onTripDeleted;

  const TripsPage({
    super.key,
    required this.trips,
    required this.onTripAdded,
    this.onTripDeleted,
  });

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  int _selectedIndex = 0;
  final List<String> _sections = ['Current', 'Past'];

  bool _isTripPast(Trip trip) {
    final now = DateTime.now();

    // If date type is unknown, it's always current
    if (trip.dateType == 'unknown') {
      return false;
    }

    // For specific dates, check if end date has passed
    if (trip.dateType == 'specific' && trip.endDate != null) {
      return trip.endDate!.isBefore(now);
    }

    // For month-based trips, check if the month/year has passed
    if (trip.dateType == 'month' && trip.month != null && trip.year != null) {
      final monthMap = {
        'January': 1, 'February': 2, 'March': 3, 'April': 4,
        'May': 5, 'June': 6, 'July': 7, 'August': 8,
        'September': 9, 'October': 10, 'November': 11, 'December': 12,
      };
      final monthNum = monthMap[trip.month];
      if (monthNum != null) {
        // Last day of the month
        final lastDayOfMonth = DateTime(trip.year!, monthNum + 1, 0);
        return lastDayOfMonth.isBefore(now);
      }
    }

    return false;
  }

  List<Trip> _getCurrentTrips() {
    return widget.trips.where((trip) => !_isTripPast(trip)).toList();
  }

  List<Trip> _getPastTrips() {
    return widget.trips.where((trip) => _isTripPast(trip)).toList();
  }

  void _showDeleteBottomSheet(Trip trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete Trip',
              style: TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E55C6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Would you like to delete your trip to ${trip.city}? This is irreversible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 16,
                color: const Color(0xFF2E55C6).withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF48484A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (widget.onTripDeleted != null) {
                        widget.onTripDeleted!(trip);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsList(List<Trip> trips) {
    if (trips.isEmpty) {
      return Center(
        child: Text(
          _selectedIndex == 0 ? 'No current trips' : 'No past trips',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailsPage(trip: trip),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E55C6).withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Full background image
                    Positioned.fill(
                      child: Image.asset(
                        trip.getCityImage(),
                        fit: BoxFit.cover,
                      ),
                    ),
                    // City pill on the bottom left
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          trip.city,
                          style: const TextStyle(
                            fontFamily: 'Mona Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E55C6),
                          ),
                        ),
                      ),
                    ),
                    // Date pill on the bottom right
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          trip.getDateDisplay(),
                          style: TextStyle(
                            fontFamily: 'Mona Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E55C6).withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    // Three vertical dots in top right
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _showDeleteBottomSheet(trip),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image with gradient overlay
        Positioned.fill(
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'lib/assets/homepage_logo1.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              // White gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.6),  // 60% opacity at 26%
                        Colors.white.withValues(alpha: 0.92), // 92% opacity at 34%
                        Colors.white,                          // 100% opacity at 100%
                      ],
                      stops: const [0.26, 0.34, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tab selector positioned at top with safe area padding
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E55C6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: List.generate(_sections.length, (index) {
                final isSelected = _selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFC3DAF4)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _sections[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF2E55C6)
                              : const Color(0xFFC3DAF4),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        // Trips list - positioned below tab selector with equal spacing
        Positioned(
          top: MediaQuery.of(context).padding.top + 16 + 52 + 16, // safe area + padding + tab height + spacing
          left: 0,
          right: 0,
          bottom: 0,
          child: _selectedIndex == 0
              ? _buildTripsList(_getCurrentTrips())
              : _buildTripsList(_getPastTrips()),
        ),
        Positioned(
          bottom: 120,
          right: 20,
          child: ElevatedButton(
            onPressed: () async {
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 20),
                SizedBox(width: 8),
                Text(
                  'Create Trip',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
