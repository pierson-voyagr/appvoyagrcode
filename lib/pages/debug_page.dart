import 'package:flutter/material.dart';
import '../supabase_config.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  List<Map<String, dynamic>> _allTrips = [];
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  Future<void> _loadDebugData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final user = SupabaseConfig.auth.currentUser;
      print('🐛 DEBUG: Current user ID: ${user?.id}');

      // Load ALL trips from database
      final tripsResponse = await SupabaseConfig.client
          .from('trips')
          .select()
          .order('created_at', ascending: false);

      print('🐛 DEBUG: Found ${(tripsResponse as List).length} total trips in database');

      // Load ALL users
      final usersResponse = await SupabaseConfig.client
          .from('users')
          .select('id, name, email');

      print('🐛 DEBUG: Found ${(usersResponse as List).length} total users in database');

      setState(() {
        _allTrips = (tripsResponse).cast<Map<String, dynamic>>();
        _allUsers = (usersResponse).cast<Map<String, dynamic>>();
        _isLoading = false;
      });

      // Print detailed info
      for (var trip in _allTrips) {
        print('🐛 TRIP: ${trip['city']} by user ${trip['user_id']}, type: ${trip['date_type']}, month: ${trip['month']} ${trip['year']}');
      }
    } catch (e) {
      print('🐛 DEBUG ERROR: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseConfig.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        title: const Text('Debug Info'),
        backgroundColor: const Color(0xFF2E55C6),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDebugData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current User Info
                      _buildSection(
                        'Current User on THIS device',
                        [
                          'ID: ${currentUser?.id ?? "Not logged in"}',
                          'Email: ${currentUser?.email ?? "N/A"}',
                          '',
                          '⚠️ IMPORTANT: If you have 2 devices/simulators,',
                          'make sure EACH is logged in to a DIFFERENT account!',
                          '',
                          'To test matching, you need:',
                          '• Device 1: User A logged in',
                          '• Device 2: User B logged in',
                          '• Both create trips to same city/month',
                        ],
                      ),
                      const SizedBox(height: 20),

                      // All Users
                      _buildSection(
                        'All Users (${_allUsers.length})',
                        _allUsers.map((user) {
                          final isCurrent = user['id'] == currentUser?.id;
                          return '${isCurrent ? "👉 " : ""}${user['name'] ?? 'Unnamed'} (${user['id']})';
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // All Trips
                      _buildSection(
                        'All Trips in Database (${_allTrips.length})',
                        _allTrips.isEmpty
                            ? ['⚠️ NO TRIPS FOUND - This is the problem!']
                            : _allTrips.map((trip) {
                                final isMine = trip['user_id'] == currentUser?.id;
                                return '${isMine ? "👉 MY TRIP: " : "OTHER: "}'
                                    '${trip['city']}, '
                                    'Type: ${trip['date_type']}, '
                                    '${trip['month'] ?? ""} ${trip['year'] ?? ""}'
                                    '${trip['start_date'] != null ? "\nDates: ${trip['start_date']} to ${trip['end_date']}" : ""}';
                              }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Matching Test
                      if (_allTrips.length >= 2) ...[
                        _buildSection(
                          'Matching Analysis',
                          _analyzeMatches(),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Refresh button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _loadDebugData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E55C6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E55C6), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2E55C6),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  List<String> _analyzeMatches() {
    final currentUser = SupabaseConfig.auth.currentUser;
    final myTrips = _allTrips.where((t) => t['user_id'] == currentUser?.id).toList();
    final otherTrips = _allTrips.where((t) => t['user_id'] != currentUser?.id).toList();

    List<String> analysis = [];

    if (myTrips.isEmpty) {
      analysis.add('⚠️ You have no trips');
    } else {
      analysis.add('✅ You have ${myTrips.length} trip(s)');
    }

    if (otherTrips.isEmpty) {
      analysis.add('⚠️ No other users have trips');
    } else {
      analysis.add('✅ Other users have ${otherTrips.length} trip(s)');
    }

    // Check for same city matches
    for (var myTrip in myTrips) {
      final sameCityTrips = otherTrips.where((t) => t['city'] == myTrip['city']).toList();
      if (sameCityTrips.isNotEmpty) {
        analysis.add('✅ Found ${sameCityTrips.length} trip(s) to ${myTrip['city']} from other users');

        for (var otherTrip in sameCityTrips) {
          final sameMonth = myTrip['month'] == otherTrip['month'];
          final sameYear = myTrip['year'] == otherTrip['year'];

          if (sameMonth && sameYear) {
            analysis.add('  ✅ MATCH! Same city, month, and year');
          } else {
            analysis.add('  ❌ No match - Different dates');
          }
        }
      } else {
        analysis.add('❌ No trips to ${myTrip['city']} from other users');
      }
    }

    return analysis;
  }
}
