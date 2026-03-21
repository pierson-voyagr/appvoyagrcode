import 'package:flutter/material.dart';
import '../models/trip.dart';
import 'create_trip_page.dart';
import 'city_details_page.dart';
import 'city_sticker_detail_page.dart';
import 'city_map_page.dart';

class ExplorePage extends StatefulWidget {
  final List<Trip> trips;
  final Function(Trip) onTripAdded;
  final Function(Trip)? onTripDeleted;

  const ExplorePage({
    super.key,
    required this.trips,
    required this.onTripAdded,
    this.onTripDeleted,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {

  String _getCityStickerPath(String cityName) {
    // Map city names to their sticker paths
    // Note: Berlin has an extra space in the filename
    if (cityName == 'Berlin') {
      return 'lib/assets/cities/$cityName/PNG/Voyagr Sticker $cityName .png';
    }
    return 'lib/assets/cities/$cityName/PNG/Voyagr Sticker $cityName.png';
  }

  Map<String, dynamic> _getStickerDimensions(String cityName) {
    // Return width, height, and rotation for each city
    switch (cityName.toLowerCase()) {
      case 'tokyo':
        return {'width': 295.0, 'height': 74.0, 'rotation': 0.0};
      case 'florence':
        return {'width': 152.0, 'height': 152.0, 'rotation': -7.0};
      case 'london':
        return {'width': 180.0, 'height': 103.0, 'rotation': 3.0};
      case 'berlin':
        return {'width': 200.0, 'height': 93.8, 'rotation': -3.0};
      case 'seoul':
        return {'width': 140.0, 'height': 170.0, 'rotation': 10.0};
      default:
        return {'width': 150.0, 'height': 150.0, 'rotation': 0.0};
    }
  }

  bool _isWideSticker(String cityName) {
    // Tokyo takes up a full row because it's wider
    return cityName.toLowerCase() == 'tokyo';
  }

  void _navigateToCity(BuildContext context, String cityName) {
    // For London, navigate to map view
    if (cityName.toLowerCase() == 'london') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CityMapPage(
            cityName: 'London',
            latitude: 51.5074, // London coordinates
            longitude: -0.1278,
          ),
        ),
      );
    } else {
      // For other cities, navigate to sticker detail page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CityStickerDetailPage(cityName: cityName),
        ),
      );
    }
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
        // Voyagr logo positioned at Y=64
        Positioned(
          top: 64,
          left: (MediaQuery.of(context).size.width - 125) / 2,
          child: Image.asset(
            'lib/assets/Voyagr Logo - Light Blue.png',
            width: 125,
            height: 31,
            fit: BoxFit.contain,
          ),
        ),
        // City stickers grid starting at 34% of screen height
        Positioned(
          top: MediaQuery.of(context).size.height * 0.34,
          left: 20,
          right: 20,
          bottom: 100,
          child: _buildCityStickersGrid(),
        ),
      ],
    );
  }

  Widget _buildCityStickersGrid() {
    if (widget.trips.isEmpty) {
      return const Center(
        child: Text(
          'No trips yet',
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF2E55C6),
          ),
        ),
      );
    }

    // Sort trips to put Tokyo first if it exists
    List<Trip> sortedTrips = List.from(widget.trips);
    sortedTrips.sort((a, b) {
      if (_isWideSticker(a.city)) return -1;  // Tokyo goes first
      if (_isWideSticker(b.city)) return 1;   // Tokyo goes first
      return 0;  // Keep original order for others
    });

    List<Widget> rows = [];
    int i = 0;

    while (i < sortedTrips.length) {
      final trip = sortedTrips[i];
      final dimensions = _getStickerDimensions(trip.city);

      if (_isWideSticker(trip.city)) {
        // Tokyo takes up full row
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: GestureDetector(
                onTap: () => _navigateToCity(context, trip.city),
                child: Transform.rotate(
                  angle: dimensions['rotation'] * 3.14159 / 180, // Convert degrees to radians
                  child: Image.asset(
                    _getCityStickerPath(trip.city),
                    width: dimensions['width'],
                    height: dimensions['height'],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
        i++;
      } else {
        // Two stickers per row
        List<Widget> rowItems = [];

        // First sticker
        rowItems.add(
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => _navigateToCity(context, trip.city),
                child: Transform.rotate(
                  angle: dimensions['rotation'] * 3.14159 / 180,
                  child: Image.asset(
                    _getCityStickerPath(trip.city),
                    width: dimensions['width'],
                    height: dimensions['height'],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );

        // Check if there's a second sticker available
        bool hasSecondSticker = i + 1 < sortedTrips.length && !_isWideSticker(sortedTrips[i + 1].city);

        if (hasSecondSticker) {
          // Two stickers - side by side
          final nextTrip = sortedTrips[i + 1];
          final nextDimensions = _getStickerDimensions(nextTrip.city);
          rowItems.add(const SizedBox(width: 16));
          rowItems.add(
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => _navigateToCity(context, nextTrip.city),
                  child: Transform.rotate(
                    angle: nextDimensions['rotation'] * 3.14159 / 180,
                    child: Image.asset(
                      _getCityStickerPath(nextTrip.city),
                      width: nextDimensions['width'],
                      height: nextDimensions['height'],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );

          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: rowItems,
              ),
            ),
          );
          i += 2;
        } else {
          // Only one sticker - center it
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: GestureDetector(
                  onTap: () => _navigateToCity(context, trip.city),
                  child: Transform.rotate(
                    angle: dimensions['rotation'] * 3.14159 / 180,
                    child: Image.asset(
                      _getCityStickerPath(trip.city),
                      width: dimensions['width'],
                      height: dimensions['height'],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
          i++;
        }
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: rows,
      ),
    );
  }

}
