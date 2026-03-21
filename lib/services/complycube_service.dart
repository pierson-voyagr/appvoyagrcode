import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../supabase_config.dart';

class ComplyCubeService {
  static const String _baseUrl = 'https://api.complycube.com/v1';
  static const String _apiKey = String.fromEnvironment('COMPLYCUBE_API_KEY',
      defaultValue: 'test_eXJTa2g1ZWhLRUhyN0hudW86NmM3MWY3NjQzNGRhMzU0M2VhOGZkNGRlN2Y3OGUwNzUxZTE4NDEwOTczMmE5MjFjMjlmN2I4ZDNiNDFiZWEwMA==');

  // Set to true to bypass ComplyCube verification for development
  static const bool _useMockMode = false;

  /// Creates a ComplyCube client for the current user
  /// This should ideally be called from your backend server for security
  static Future<String> createClient({
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final requestBody = jsonEncode({
        'type': 'person',
        'email': email,
        'personDetails': {
          'firstName': firstName,
          'lastName': lastName,
        }
      });

      developer.log('ComplyCube API Request: POST $_baseUrl/clients');
      developer.log('Request Body: $requestBody');
      developer.log('API Key: ${_apiKey.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse('$_baseUrl/clients'),
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
        },
        body: requestBody,
        encoding: utf8,
      );

      developer.log('ComplyCube Response Status: ${response.statusCode}');
      developer.log('ComplyCube Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as String;
      } else {
        throw Exception(
            'Failed to create ComplyCube client: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('ComplyCube createClient error: $e');
      throw Exception('Error creating ComplyCube client: $e');
    }
  }

  /// Generates an SDK token for the client
  /// This should ideally be called from your backend server for security
  static Future<String> generateSDKToken({
    required String clientId,
    required String appId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tokens'),
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clientId': clientId,
          'appId': appId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'] as String;
      } else {
        throw Exception(
            'Failed to generate SDK token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating SDK token: $e');
    }
  }

  /// Gets or creates a ComplyCube client ID for the current user
  /// and generates an SDK token
  static Future<Map<String, String>> getSDKToken(
      {required String firstName,
      required String lastName,
      required String appId}) async {
    // Mock mode - return fake credentials for development
    if (_useMockMode) {
      developer.log('ComplyCube: Using mock mode - skipping verification');
      return {
        'clientId': 'mock_client_${DateTime.now().millisecondsSinceEpoch}',
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    final user = SupabaseConfig.auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    // In production, you should store the clientId in Supabase
    // to avoid creating duplicate clients
    final clientId = await createClient(
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
    );

    final token = await generateSDKToken(
      clientId: clientId,
      appId: appId,
    );

    return {
      'clientId': clientId,
      'token': token,
    };
  }

  /// Gets SDK token for signup (before user account is created)
  /// Uses a temporary email until the user completes signup
  static Future<Map<String, String>> getSDKTokenForSignup({
    required String firstName,
    required String lastName,
    required String appId,
  }) async {
    // Mock mode - return fake credentials for development
    if (_useMockMode) {
      developer.log('ComplyCube: Using mock mode for signup - skipping verification');
      return {
        'clientId': 'mock_signup_client_${DateTime.now().millisecondsSinceEpoch}',
        'token': 'mock_signup_token_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    // Use a temporary email for signup
    final tempEmail = 'signup_${DateTime.now().millisecondsSinceEpoch}@voyagr.temp';

    final clientId = await createClient(
      email: tempEmail,
      firstName: firstName,
      lastName: lastName,
    );

    final token = await generateSDKToken(
      clientId: clientId,
      appId: appId,
    );

    return {
      'clientId': clientId,
      'token': token,
    };
  }
}
