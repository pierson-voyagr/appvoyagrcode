import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class IdAnalyzerService {
  static const String _apiUrl = 'https://api.idanalyzer.com';
  static const String _apiKey = String.fromEnvironment(
    'ID_ANALYZER_API_KEY',
    defaultValue: '',
  );

  /// Get the API key
  static String get _key {
    if (_apiKey.isEmpty) {
      throw Exception('ID_ANALYZER_API_KEY not set. Pass via --dart-define.');
    }
    return _apiKey;
  }

  /// Verify an ID document and biometric selfie
  /// Returns a map with verification results
  static Future<Map<String, dynamic>> verify({
    required File documentImage,
    required File selfieImage,
  }) async {
    try {
      // Convert images to base64
      final docBytes = await documentImage.readAsBytes();
      final selfieBytes = await selfieImage.readAsBytes();
      final docBase64 = base64Encode(docBytes);
      final selfieBase64 = base64Encode(selfieBytes);

      developer.log('ID Analyzer: Sending verification request...');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'apikey': _key,
          'file_base64': docBase64,
          'biometric_file_base64': selfieBase64,
        }),
      );

      developer.log('ID Analyzer Response Status: ${response.statusCode}');
      developer.log('ID Analyzer Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data.containsKey('error')) {
          throw Exception(data['error']['message'] ?? 'Verification failed');
        }

        return data;
      } else {
        throw Exception(
            'API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      developer.log('ID Analyzer error: $e');
      rethrow;
    }
  }

  /// Check if the face matched from the verification result
  static bool isFaceMatch(Map<String, dynamic> result) {
    final biometric = result['biometric'];
    if (biometric == null) return false;
    return biometric['isIdentical'] == true;
  }

  /// Get face match confidence from the verification result
  static double getFaceConfidence(Map<String, dynamic> result) {
    final biometric = result['biometric'];
    if (biometric == null) return 0.0;
    return (biometric['confidence'] ?? 0).toDouble();
  }
}
