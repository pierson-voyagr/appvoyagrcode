import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/location.dart' as location_model;
import '../services/location_service.dart';

class CityMapPage extends StatefulWidget {
  final String cityName;
  final double latitude;
  final double longitude;

  const CityMapPage({
    super.key,
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CityMapPage> createState() => _CityMapPageState();
}

class _CityMapPageState extends State<CityMapPage> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  CircleAnnotationManager? _circleAnnotationManager;
  bool _isStarSelected = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  List<location_model.Location> _locations = [];
  List<location_model.Location> _allLocations = []; // Keep all locations for search
  List<location_model.Location> _searchResults = []; // Search results
  bool _isSearching = false; // Whether search dropdown is visible
  bool _isLoadingLocations = true;
  bool _isStyleLoaded = false;
  bool _useStarIcon = false;
  final Map<String, int> _annotationIdToIndex = {};
  Cancelable? _tapSubscription;
  Cancelable? _circleTapSubscription;
  final Set<String> _savedLocationIds = {}; // Track saved/starred locations
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadSavedLocationIds();
  }

  Future<void> _loadSavedLocationIds() async {
    final savedIds = await LocationService.getSavedLocationIds(widget.cityName);
    setState(() {
      _savedLocationIds.clear();
      _savedLocationIds.addAll(savedIds);
    });
    // Update markers if already loaded
    if (_locations.isNotEmpty) {
      _updateMarkers();
    }
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      // Load all locations for the city first
      List<location_model.Location> locations = await LocationService.getLocationsByCity(widget.cityName);

      print('Loaded ${locations.length} total locations for ${widget.cityName}');

      // Store all locations for search functionality
      _allLocations = List.from(locations);

      // Apply category filter if selected (case-insensitive)
      if (_selectedCategory.isNotEmpty) {
        final selectedCat = _selectedCategory.toLowerCase();
        // Remove trailing 's' for singular form (e.g., "Sights" -> "sight", "Stays" -> "stay")
        final selectedCatSingular = selectedCat.endsWith('s')
            ? selectedCat.substring(0, selectedCat.length - 1)
            : selectedCat;

        print('Category filter: selected="$selectedCat", singular="$selectedCatSingular"');
        print('Available categories in locations:');
        for (var loc in locations) {
          print('  - ${loc.name}: category="${loc.category}"');
        }

        locations = locations.where((loc) {
          final locCategory = loc.category?.toLowerCase() ?? '';
          // Match exact, singular form, or plural form
          final matches = locCategory == selectedCat ||
                 locCategory == selectedCatSingular ||
                 '${locCategory}s' == selectedCat ||
                 locCategory == '${selectedCat}s';
          print('Checking "${loc.name}" category="$locCategory" against "$selectedCat" or "$selectedCatSingular": $matches');
          return matches;
        }).toList();
        print('After category filter "$_selectedCategory": ${locations.length} locations');
      }

      // Apply star filter if selected - only show saved locations
      if (_isStarSelected) {
        locations = locations.where((loc) => _savedLocationIds.contains(loc.id)).toList();
        print('After star filter: ${locations.length} saved locations');
      }

      for (var loc in locations) {
        print('Location: ${loc.name} (${loc.category}) at ${loc.latitude}, ${loc.longitude}');
      }

      setState(() {
        _locations = locations;
        _isLoadingLocations = false;
      });

      // Update markers on the map
      _updateMarkers();
    } catch (e) {
      print('Error loading locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final results = _allLocations.where((loc) {
      final name = loc.name.toLowerCase();
      final category = loc.category?.toLowerCase() ?? '';
      // Match if query is found anywhere in name or category
      return name.contains(lowerQuery) || category.contains(lowerQuery);
    }).toList();

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  void _selectSearchResult(location_model.Location location) {
    // Clear search
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
    _searchFocusNode.unfocus();

    // Show the location details
    _showLocationDetails(location);

    // Optionally, fly to the location on the map
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(location.longitude, location.latitude)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> _updateMarkers() async {
    print('_updateMarkers called. Map: ${_mapboxMap != null}, PointManager: ${_pointAnnotationManager != null}, CircleManager: ${_circleAnnotationManager != null}, Locations: ${_locations.length}, StyleLoaded: $_isStyleLoaded, UseStarIcon: $_useStarIcon');

    if (_mapboxMap == null) {
      print('Skipping marker update - map not ready');
      return;
    }

    if (_locations.isEmpty) {
      print('No locations to display - clearing markers');
      // Clear existing markers when no locations match
      if (_pointAnnotationManager != null) {
        await _pointAnnotationManager!.deleteAll();
      }
      if (_circleAnnotationManager != null) {
        await _circleAnnotationManager!.deleteAll();
      }
      _annotationIdToIndex.clear();
      return;
    }

    if (_useStarIcon && _pointAnnotationManager != null && _isStyleLoaded) {
      // Clear existing markers and mappings
      await _pointAnnotationManager!.deleteAll();
      if (_circleAnnotationManager != null) {
        await _circleAnnotationManager!.deleteAll();
      }
      _annotationIdToIndex.clear();

      print('Creating star markers with iconImage: star-marker');

      // Verify image exists before creating markers
      try {
        final hasImage = await _mapboxMap!.style.hasStyleImage('star-marker');
        print('Double-check: star-marker exists before creating annotations: $hasImage');

        if (!hasImage) {
          print('ERROR: star-marker image not found in style! Falling back to circles.');
          setState(() {
            _useStarIcon = false;
          });
          _updateMarkers();
          return;
        }
      } catch (e) {
        print('Error checking for star-marker image: $e');
      }

      // Add star markers for each location
      final annotations = <PointAnnotationOptions>[];

      for (var i = 0; i < _locations.length; i++) {
        final location = _locations[i];
        print('Adding star marker for ${location.name} at ${location.latitude}, ${location.longitude}');
        final pointAnnotation = PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(location.longitude, location.latitude),
          ),
          iconImage: 'star-marker',
          iconSize: 0.5,  // Smaller size for the map
          iconAnchor: IconAnchor.CENTER,
        );
        annotations.add(pointAnnotation);
      }

      print('Creating ${annotations.length} star markers');
      try {
        final createdAnnotations = await _pointAnnotationManager!.createMulti(annotations);
        print('Star markers created successfully: ${createdAnnotations.length} annotations');

        // Map annotation IDs to location indices
        for (var i = 0; i < createdAnnotations.length; i++) {
          final annotation = createdAnnotations[i];
          final id = annotation?.id;
          if (id != null) {
            _annotationIdToIndex[id] = i;
          }
        }

        // Set up tap listener for markers using the modern tapEvents
        _tapSubscription?.cancel();
        _tapSubscription = _pointAnnotationManager!.tapEvents(
          onTap: (annotation) {
            final index = _annotationIdToIndex[annotation.id];
            if (index != null && index < _locations.length) {
              print('Marker tapped: ${_locations[index].name}');
              _showLocationDetails(_locations[index]);
            }
          },
        );

        print('Star annotations are now ready. Tap should work on markers.');
      } catch (e) {
        print('ERROR creating star markers: $e');
        print('Falling back to circle markers');
        setState(() {
          _useStarIcon = false;
        });
        _updateMarkers();
      }
    } else if (_circleAnnotationManager != null) {
      // Fallback to circle markers
      print('Using circle markers as fallback');
      if (_pointAnnotationManager != null) {
        await _pointAnnotationManager!.deleteAll();
      }
      await _circleAnnotationManager!.deleteAll();
      _annotationIdToIndex.clear();

      final annotations = <CircleAnnotationOptions>[];

      for (var location in _locations) {
        final isSaved = _savedLocationIds.contains(location.id);
        print('Adding circle marker for ${location.name} at ${location.latitude}, ${location.longitude} (saved: $isSaved)');
        final circleAnnotation = CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(location.longitude, location.latitude),
          ),
          circleRadius: 15.0,
          circleColor: isSaved ? 0xFFFFD700 : 0xFF2E55C6, // Yellow if saved, dark blue otherwise
          circleStrokeColor: 0xFFFFFFFF, // White border
          circleStrokeWidth: 2.0,
        );
        annotations.add(circleAnnotation);
      }

      print('Creating ${annotations.length} circle markers');
      final createdAnnotations = await _circleAnnotationManager!.createMulti(annotations);
      print('Circle markers created successfully');

      // Map annotation IDs to location indices
      for (var i = 0; i < createdAnnotations.length; i++) {
        final annotation = createdAnnotations[i];
        final id = annotation?.id;
        if (id != null) {
          _annotationIdToIndex[id] = i;
        }
      }

      // Set up tap listener for circle markers
      _circleTapSubscription?.cancel();
      _circleTapSubscription = _circleAnnotationManager!.tapEvents(
        onTap: (annotation) {
          final index = _annotationIdToIndex[annotation.id];
          if (index != null && index < _locations.length) {
            print('Circle marker tapped: ${_locations[index].name}');
            _showLocationDetails(_locations[index]);
          }
        },
      );

      print('Circle tap listener set up successfully');
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Configure logo and attribution position
    await mapboxMap.logo.updateSettings(
      LogoSettings(
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginBottom: 8.0,
        marginRight: 8.0,
      ),
    );

    await mapboxMap.attribution.updateSettings(
      AttributionSettings(
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginBottom: 8.0,
        marginRight: 8.0,
      ),
    );

    // Set camera position
    await mapboxMap.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(widget.longitude, widget.latitude),
        ),
        zoom: 13.0,
      ),
    );

    // Create both annotation managers
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    print('Annotation managers created');

    // Load custom star icon with delay to ensure style is ready
    if (!mounted) return;

    // Wait a bit for style to fully load
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      print('Loading star icon asset...');

      // Load the pre-sized 64x64 PNG (from the original high-res PNG with transparency)
      final ByteData bytes = await rootBundle.load(
        'lib/assets/star_marker_64.png',
      );
      final Uint8List pngBytes = bytes.buffer.asUint8List();
      print('PNG loaded: ${pngBytes.length} bytes');

      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      print('Image size: ${image.width}x${image.height}');

      // Convert to RGBA bytes
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      final Uint8List rgbaBytes = byteData.buffer.asUint8List();
      print('RGBA bytes created: ${rgbaBytes.length} bytes (expected: ${image.width * image.height * 4})');

      print('Adding star icon to map style...');

      // Try alternative approach: use the raw PNG bytes instead of decoded RGBA
      try {
        await mapboxMap.style.addStyleImage(
          'star-marker',
          1.0, // Scale
          MbxImage(
            width: image.width,
            height: image.height,
            data: rgbaBytes,
          ),
          false, // sdf
          <ImageStretches>[],
          <ImageStretches>[],
          null,
        );
        print('Star icon added to style successfully');
      } catch (e) {
        print('Failed with RGBA approach, trying PNG bytes: $e');
        // Fallback: try with PNG bytes directly (some Mapbox versions prefer this)
        await mapboxMap.style.addStyleImage(
          'star-marker',
          1.0,
          MbxImage(
            width: image.width,
            height: image.height,
            data: pngBytes,
          ),
          false,
          <ImageStretches>[],
          <ImageStretches>[],
          null,
        );
        print('Star icon added using PNG bytes');
      }

      // Verify the image was added
      final hasImage = await mapboxMap.style.hasStyleImage('star-marker');
      print('Verify star-marker exists in style: $hasImage');

      // Dispose the image
      image.dispose();

      setState(() {
        _isStyleLoaded = true;
        _useStarIcon = false; // Use circle markers for dynamic color support (saved = yellow, unsaved = blue)
      });

      // Update markers now that style and icon are ready
      _updateMarkers();
    } catch (e) {
      print('Error loading star icon: $e');
      print('Error type: ${e.runtimeType}');

      // Fallback to circle markers
      setState(() {
        _isStyleLoaded = true;
        _useStarIcon = false;
      });
      _updateMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Mapbox Map with tap handling
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              // Show location details when tapping on the map
              // For now, show the first location as a demo
              if (_locations.isNotEmpty) {
                print('Map tapped, showing details for ${_locations.first.name}');
                _showLocationDetails(_locations.first);
              }
            },
            child: MapWidget(
              key: const ValueKey("mapWidget"),
              styleUri: MapboxStyles.MAPBOX_STREETS,
              textureView: true,
              onMapCreated: _onMapCreated,
            ),
          ),
          // Header with back button and search bar
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row with back button and search
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E55C6)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search bar
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Search ${widget.cityName}...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[400],
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search results dropdown
                if (_isSearching && _searchResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final location = _searchResults[index];
                            final isSaved = _savedLocationIds.contains(location.id);
                            return InkWell(
                              onTap: () => _selectSearchResult(location),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: index < _searchResults.length - 1
                                      ? Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.withValues(alpha: 0.2),
                                          ),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Location icon with saved indicator
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSaved
                                            ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                            : const Color(0xFF2E55C6).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isSaved ? Icons.star : Icons.location_on,
                                        color: isSaved
                                            ? const Color(0xFFFFD700)
                                            : const Color(0xFF2E55C6),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Location info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            location.name,
                                            style: const TextStyle(
                                              fontFamily: 'Mona Sans',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2E55C6),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (location.category != null)
                                            Text(
                                              location.category!,
                                              style: TextStyle(
                                                fontFamily: 'Mona Sans',
                                                fontSize: 12,
                                                color: const Color(0xFF2E55C6).withValues(alpha: 0.6),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Arrow icon
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: const Color(0xFF2E55C6).withValues(alpha: 0.4),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                // No results message
                if (_isSearching && _searchResults.isEmpty && _searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'No locations found',
                            style: TextStyle(
                              fontFamily: 'Mona Sans',
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Category tags row (only show when not searching)
                if (!_isSearching)
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        children: [
                          const SizedBox(width: 16),
                          _buildCategoryTag('Food'),
                          const SizedBox(width: 8),
                          _buildCategoryTag('Bars'),
                          const SizedBox(width: 8),
                          _buildCategoryTag('Sights'),
                          const SizedBox(width: 8),
                          _buildCategoryTag('Stays'),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Star button in bottom right
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: _isStarSelected ? const Color(0xFF2E55C6) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isStarSelected = !_isStarSelected;
                    });
                    print('Star filter ${_isStarSelected ? "enabled" : "disabled"}');
                    _loadLocations(); // Reload locations with star filter applied
                  },
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'lib/assets/Icon /PNG/Voyagr Star Icon - Yellow.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? '' : category;
        });
        print('Category button tapped: ${isSelected ? "Deselecting" : "Selecting"} $category');
        print('New selected category: $_selectedCategory');
        _loadLocations(); // Reload locations when category changes
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E55C6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2E55C6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSavedLocation(String locationId) async {
    final isCurrentlySaved = _savedLocationIds.contains(locationId);
    print('_toggleSavedLocation called for $locationId, currently saved: $isCurrentlySaved');

    // Optimistically update UI
    setState(() {
      if (isCurrentlySaved) {
        _savedLocationIds.remove(locationId);
        print('Removed $locationId from saved set');
      } else {
        _savedLocationIds.add(locationId);
        print('Added $locationId to saved set');
      }
    });

    print('Saved location IDs now: $_savedLocationIds');

    // Refresh markers to update colors (await to ensure it completes)
    print('Calling _updateMarkers...');
    await _updateMarkers();
    print('_updateMarkers completed');

    // Persist to database
    if (isCurrentlySaved) {
      await LocationService.unsaveLocation(locationId: locationId);
    } else {
      await LocationService.saveLocation(
        locationId: locationId,
        city: widget.cityName,
      );
    }
    print('Database operation completed');
  }

  bool _isLocationSaved(String locationId) {
    return _savedLocationIds.contains(locationId);
  }

  void _showLocationDetails(location_model.Location location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationDetailsSheet(
        location: location,
        isSaved: _isLocationSaved(location.id),
        onToggleSaved: () => _toggleSavedLocation(location.id),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tapSubscription?.cancel();
    _circleTapSubscription?.cancel();
    super.dispose();
  }
}

// Separate StatefulWidget for the location details sheet (needs its own state for star toggle)
class _LocationDetailsSheet extends StatefulWidget {
  final location_model.Location location;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  const _LocationDetailsSheet({
    required this.location,
    required this.isSaved,
    required this.onToggleSaved,
  });

  @override
  State<_LocationDetailsSheet> createState() => _LocationDetailsSheetState();
}

class _LocationDetailsSheetState extends State<_LocationDetailsSheet> {
  late bool _isStarred;
  String _selectedFilter = 'Top'; // 'Top' or 'Recent'

  @override
  void initState() {
    super.initState();
    _isStarred = widget.isSaved;
  }
  final TextEditingController _commentController = TextEditingController();
  String? _selectedImagePath;

  // Mock posts data - in production, this would come from a database
  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'username': 'TravelLover22',
      'text': 'Absolutely stunning! The architecture is breathtaking. Spent hours just taking it all in.',
      'imageUrl': 'https://picsum.photos/400/300?random=1',
      'likes': 42,
      'isLiked': false,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': '2',
      'username': 'WorldExplorer',
      'text': 'A must-visit when in the city! Pro tip: go early in the morning to avoid crowds.',
      'imageUrl': null,
      'likes': 28,
      'isLiked': false,
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '3',
      'username': 'PhotoNomad',
      'text': 'Golden hour here is magical ✨',
      'imageUrl': 'https://picsum.photos/400/300?random=2',
      'likes': 156,
      'isLiked': true,
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
    },
  ];

  // Get image URL from location or fallback to placeholder
  String? _getLocationImageUrl() {
    return widget.location.image;
  }

  void _toggleLike(int index) {
    setState(() {
      _posts[index]['isLiked'] = !_posts[index]['isLiked'];
      _posts[index]['likes'] += _posts[index]['isLiked'] ? 1 : -1;
    });
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty && _selectedImagePath == null) {
      return;
    }

    setState(() {
      _posts.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'username': 'You',
        'text': _commentController.text.trim(),
        'imageUrl': _selectedImagePath,
        'likes': 0,
        'isLiked': false,
        'timestamp': DateTime.now(),
      });
      _commentController.clear();
      _selectedImagePath = null;
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  List<Map<String, dynamic>> get _sortedPosts {
    final sorted = List<Map<String, dynamic>>.from(_posts);
    if (_selectedFilter == 'Top') {
      sorted.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));
    } else {
      sorted.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    }
    return sorted;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openDirections() async {
    final lat = widget.location.latitude;
    final lng = widget.location.longitude;
    final name = Uri.encodeComponent(widget.location.name);

    // Apple Maps URL scheme
    final appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d&t=m&q=$name'
    );

    if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton() {
    final category = widget.location.category?.toLowerCase() ?? '';

    // Determine button text and icon based on category
    String label;
    IconData icon;

    if (category == 'sights' || category == 'attractions') {
      label = 'Tickets';
      icon = Icons.confirmation_number_outlined;
    } else if (category == 'food' || category == 'restaurants' || category == 'dining') {
      label = 'Reserve';
      icon = Icons.restaurant_outlined;
    } else if (category == 'stays' || category == 'hotels' || category == 'lodging') {
      label = 'Book';
      icon = Icons.hotel_outlined;
    } else if (category == 'bars' || category == 'nightlife') {
      label = 'Reserve';
      icon = Icons.local_bar_outlined;
    } else {
      label = 'More';
      icon = Icons.more_horiz;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // TODO: Handle booking/reservation action
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2E55C6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildFilterTab('Top'),
          _buildFilterTab('Recent'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E55C6) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[500],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row with like button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        post['username'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF2E55C6),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Username and timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['username'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _formatTimestamp(post['timestamp']),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Like button
                  GestureDetector(
                    onTap: () => _toggleLike(index),
                    child: Row(
                      children: [
                        Icon(
                          post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                          color: post['isLiked'] ? Colors.red : Colors.grey[350],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post['likes']}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Post text
            if (post['text'] != null && post['text'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(
                  post['text'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            // Post image
            if (post['imageUrl'] != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post['imageUrl'],
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2E55C6),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Add bottom padding if no image
            if (post['imageUrl'] == null && (post['text'] == null || post['text'].isEmpty))
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo with title overlay (title sits half on/half off photo)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Background photo with gradient overlay
                        Container(
                          width: double.infinity,
                          height: 200,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[300],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Image
                                _getLocationImageUrl() != null
                                    ? Image.network(
                                        _getLocationImageUrl()!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              color: const Color(0xFF2E55C6),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 48,
                                                color: Color(0xFF2E55C6),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 48,
                                            color: Color(0xFF2E55C6),
                                          ),
                                        ),
                                      ),
                                // Gradient overlay at the bottom for text readability
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 80,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withValues(alpha: 0.85),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Title and Star row - positioned half on/half off the photo
                        Positioned(
                          bottom: -24, // Half off the photo (negative value)
                          left: 24,
                          right: 24,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Location name - responsive sizing
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.location.name,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2E55C6),
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Star toggle button with blue circle background when starred
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isStarred = !_isStarred;
                                  });
                                  // Notify parent to update map markers
                                  widget.onToggleSaved();
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isStarred
                                        ? const Color(0xFF2E55C6)
                                        : Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      _isStarred
                                          ? 'lib/assets/Icon /PNG/Voyagr Star Icon - Yellow.png'
                                          : 'lib/assets/Icon /PNG/Voyagr Star Icon - Blue.png',
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Add spacing to account for the overlapping title
                    const SizedBox(height: 36),
                    // City and Category
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.location.city,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (widget.location.category != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.location.category!,
                                style: const TextStyle(
                                  color: Color(0xFF2E55C6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action buttons row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Website button
                          _buildActionButton(
                            icon: Icons.language,
                            label: 'Website',
                            onTap: () {
                              // TODO: Open website URL
                            },
                          ),
                          const SizedBox(width: 8),
                          // Social button
                          _buildActionButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Social',
                            onTap: () {
                              // TODO: Open Instagram/Facebook
                            },
                          ),
                          const SizedBox(width: 8),
                          // Directions button
                          _buildActionButton(
                            icon: Icons.directions_outlined,
                            label: 'Directions',
                            onTap: () => _openDirections(),
                          ),
                          const SizedBox(width: 8),
                          // Context-specific button based on category
                          _buildPrimaryActionButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(color: Colors.grey[200], thickness: 1),
                    ),
                    const SizedBox(height: 16),

                    // Top / Recent filter bar (full width toggle)
                    _buildFilterBar(),
                    const SizedBox(height: 16),

                    // Comment input box
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _commentController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Share your experience...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              ),
                            ),
                            // Bottom row with Add Photo and Send buttons
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 12, bottom: 12),
                              child: Row(
                                children: [
                                  // Add Photo button
                                  GestureDetector(
                                    onTap: () {
                                      // TODO: Implement photo picker
                                      setState(() {
                                        _selectedImagePath = 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedImagePath != null
                                            ? const Color(0xFF2E55C6).withValues(alpha: 0.1)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _selectedImagePath != null
                                                ? Icons.check_circle
                                                : Icons.add_photo_alternate_outlined,
                                            color: _selectedImagePath != null
                                                ? const Color(0xFF2E55C6)
                                                : Colors.grey[500],
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _selectedImagePath != null ? 'Photo added' : 'Add photo',
                                            style: TextStyle(
                                              color: _selectedImagePath != null
                                                  ? const Color(0xFF2E55C6)
                                                  : Colors.grey[500],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Send button
                                  GestureDetector(
                                    onTap: _submitComment,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2E55C6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_upward,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Posts list
                    ..._sortedPosts.asMap().entries.map((entry) {
                      final index = _posts.indexWhere((p) => p['id'] == entry.value['id']);
                      final post = entry.value;
                      return _buildPostCard(post, index);
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
