import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/location.dart';

class LocationService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// Save a location for a user and city
  static Future<bool> saveLocation({
    required String locationId,
    required String city,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Error: No user logged in');
        return false;
      }

      await _supabase.from('saved_locations').insert({
        'user_id': userId,
        'location_id': locationId,
        'city': city,
      });

      print('Location saved: $locationId for city $city');
      return true;
    } catch (e) {
      print('Error saving location: $e');
      return false;
    }
  }

  /// Remove a saved location for a user
  static Future<bool> unsaveLocation({
    required String locationId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Error: No user logged in');
        return false;
      }

      await _supabase
          .from('saved_locations')
          .delete()
          .eq('user_id', userId)
          .eq('location_id', locationId);

      print('Location unsaved: $locationId');
      return true;
    } catch (e) {
      print('Error unsaving location: $e');
      return false;
    }
  }

  /// Get all saved location IDs for a user and city
  static Future<Set<String>> getSavedLocationIds(String city) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Error: No user logged in');
        return {};
      }

      final response = await _supabase
          .from('saved_locations')
          .select('location_id')
          .eq('user_id', userId)
          .eq('city', city);

      final ids = (response as List)
          .map((json) => json['location_id'] as String)
          .toSet();

      print('Loaded ${ids.length} saved locations for $city');
      return ids;
    } catch (e) {
      print('Error fetching saved location IDs: $e');
      return {};
    }
  }

  /// Get all saved locations (full details) for a user and city
  static Future<List<Location>> getSavedLocations(String city) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Error: No user logged in');
        return [];
      }

      // Join saved_locations with locations to get full details
      final response = await _supabase
          .from('saved_locations')
          .select('location_id, locations(*)')
          .eq('user_id', userId)
          .eq('city', city);

      final locations = (response as List)
          .where((json) => json['locations'] != null)
          .map((json) => Location.fromJson(json['locations']))
          .toList();

      print('Loaded ${locations.length} saved locations with details for $city');
      return locations;
    } catch (e) {
      print('Error fetching saved locations: $e');
      return [];
    }
  }

  /// Fetch all locations for a specific city
  static Future<List<Location>> getLocationsByCity(String city) async {
    try {
      final response = await _supabase
          .from('locations')
          .select()
          .eq('city', city)
          .order('created_at');

      final locations = (response as List)
          .map((json) => Location.fromJson(json))
          .toList();

      return locations;
    } catch (e) {
      print('Error fetching locations: $e');
      return [];
    }
  }

  /// Fetch locations by city and category
  static Future<List<Location>> getLocationsByCityAndCategory(
    String city,
    String category,
  ) async {
    try {
      final response = await _supabase
          .from('locations')
          .select()
          .eq('city', city)
          .eq('category', category)
          .order('created_at');

      final locations = (response as List)
          .map((json) => Location.fromJson(json))
          .toList();

      return locations;
    } catch (e) {
      print('Error fetching locations by category: $e');
      return [];
    }
  }

  // ========== ADMIN CRUD OPERATIONS ==========

  /// Fetch all locations (admin view)
  static Future<List<Location>> getAllLocations() async {
    try {
      final response = await _supabase
          .from('locations')
          .select()
          .order('city')
          .order('category')
          .order('name');

      final locations = (response as List)
          .map((json) => Location.fromJson(json))
          .toList();

      return locations;
    } catch (e) {
      print('Error fetching all locations: $e');
      return [];
    }
  }

  /// Create a new location
  static Future<Location?> createLocation({
    required String name,
    required String city,
    required String address,
    required double latitude,
    required double longitude,
    String? category,
    String? description,
    String? image,
  }) async {
    try {
      final response = await _supabase.from('locations').insert({
        'name': name,
        'city': city,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'description': description,
        'image': image,
      }).select().single();

      print('Location created: $name');
      return Location.fromJson(response);
    } catch (e) {
      print('Error creating location: $e');
      return null;
    }
  }

  /// Update an existing location
  static Future<bool> updateLocation({
    required String id,
    required String name,
    required String city,
    required String address,
    required double latitude,
    required double longitude,
    String? category,
    String? description,
    String? image,
  }) async {
    try {
      await _supabase.from('locations').update({
        'name': name,
        'city': city,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'description': description,
        'image': image,
      }).eq('id', id);

      print('Location updated: $name');
      return true;
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  /// Delete a location
  static Future<bool> deleteLocation(String id) async {
    try {
      // First delete any saved_locations references
      await _supabase.from('saved_locations').delete().eq('location_id', id);
      // Then delete the location
      await _supabase.from('locations').delete().eq('id', id);

      print('Location deleted: $id');
      return true;
    } catch (e) {
      print('Error deleting location: $e');
      return false;
    }
  }

  /// Bulk insert locations
  static Future<int> bulkInsertLocations(List<Map<String, dynamic>> locations) async {
    try {
      await _supabase.from('locations').insert(locations);
      print('Bulk inserted ${locations.length} locations');
      return locations.length;
    } catch (e) {
      print('Error bulk inserting locations: $e');
      return 0;
    }
  }

  /// Delete all locations for a city
  static Future<bool> deleteAllLocationsForCity(String city) async {
    try {
      // First get all location IDs for the city
      final response = await _supabase
          .from('locations')
          .select('id')
          .eq('city', city);

      final ids = (response as List).map((json) => json['id'] as String).toList();

      // Delete saved_locations references
      for (final id in ids) {
        await _supabase.from('saved_locations').delete().eq('location_id', id);
      }

      // Delete all locations for the city
      await _supabase.from('locations').delete().eq('city', city);

      print('Deleted all locations for city: $city');
      return true;
    } catch (e) {
      print('Error deleting locations for city: $e');
      return false;
    }
  }
}
