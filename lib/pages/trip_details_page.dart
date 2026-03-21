import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import '../services/itinerary_ai_service.dart';

// Chat message model for AI Itinerary Builder
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class TripDetailsPage extends StatefulWidget {
  final Trip trip;

  const TripDetailsPage({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Trip Details', 'Build'];
  List<Location> _savedLocations = [];
  bool _isLoadingSavedLocations = true;

  // Chat state for AI Itinerary Builder
  bool _isChatActive = false;
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isAiTyping = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    setState(() {
      _isLoadingSavedLocations = true;
    });

    final locations = await LocationService.getSavedLocations(widget.trip.city);

    setState(() {
      _savedLocations = locations;
      _isLoadingSavedLocations = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and trip info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2E55C6),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Trip title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trip.city,
                          style: const TextStyle(
                            fontFamily: 'Mona Sans',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E55C6),
                          ),
                        ),
                        Text(
                          widget.trip.getDateDisplay(),
                          style: TextStyle(
                            fontFamily: 'Mona Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E55C6).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tab selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E55C6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = _selectedTabIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFC3DAF4)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Text(
                            _tabs[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Mona Sans',
                              fontSize: 16,
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
            const SizedBox(height: 24),
            // Tab content
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildTripDetailsTab()
                  : _buildBuildTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Card 1: Trip Details
          _buildDetailsCard(),
          const SizedBox(height: 16),
          // Card 2: Saved Locations
          _buildSavedLocationsCard(),
          const SizedBox(height: 16),
          // Card 3: Itinerary
          _buildItineraryCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E55C6).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E55C6).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF2E55C6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Trip Details',
                style: TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E55C6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Location
          _buildDetailRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: '${widget.trip.city}, ${widget.trip.country}',
          ),
          const SizedBox(height: 12),
          // Dates
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Dates',
            value: widget.trip.getDateDisplay(),
          ),
          // Reason for travel (if available)
          if (widget.trip.reasonForTrip != null && widget.trip.reasonForTrip!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.flight_takeoff_outlined,
              label: 'Reason',
              value: widget.trip.reasonForTrip!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF2E55C6).withValues(alpha: 0.5),
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Mona Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E55C6).withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E55C6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedLocationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E55C6).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E55C6).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bookmark_outline,
                  color: Color(0xFF2E55C6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Saved Locations',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E55C6),
                  ),
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_savedLocations.length}',
                  style: const TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E55C6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Loading state
          if (_isLoadingSavedLocations)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF2E55C6).withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          // Empty state
          else if (_savedLocations.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.bookmark_add_outlined,
                    size: 40,
                    color: const Color(0xFF2E55C6).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No saved locations yet',
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E55C6).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Save places from the map to see them here',
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 12,
                      color: const Color(0xFF2E55C6).withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          // Locations list
          else
            Column(
              children: _savedLocations.map((location) => _buildSavedLocationItem(location)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedLocationItem(Location location) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Yellow star icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.star,
              color: Color(0xFFFFD700),
              size: 18,
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
                    fontSize: 14,
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
            Icons.chevron_right,
            color: const Color(0xFF2E55C6).withValues(alpha: 0.4),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard() {
    // TODO: Load itinerary from database
    final bool hasItinerary = false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E55C6).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E55C6).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Color(0xFF2E55C6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Itinerary',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E55C6),
                  ),
                ),
              ),
              if (hasItinerary)
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to full itinerary view
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E55C6).withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Empty state or itinerary preview
          if (!hasItinerary)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.route_outlined,
                    size: 40,
                    color: const Color(0xFF2E55C6).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No itinerary yet',
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E55C6).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build your itinerary using AI',
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 12,
                      color: const Color(0xFF2E55C6).withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1; // Switch to Build tab
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E55C6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Start Building',
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // TODO: Show itinerary preview
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildBuildTab() {
    // Show chat interface if active, otherwise show start screen
    if (_isChatActive) {
      return _buildChatInterface();
    }

    return Stack(
      children: [
        // Main content area - placeholder for future AI itinerary builder
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: const Color(0xFF2E55C6).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'AI Itinerary Builder',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E55C6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Let AI help you plan the perfect trip to ${widget.trip.city}. We\'ll create a personalized itinerary based on your preferences.',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 16,
                    color: const Color(0xFF2E55C6).withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 120), // Space for the bottom button
              ],
            ),
          ),
        ),
        // Bottom button
        Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: ElevatedButton(
            onPressed: _startChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E55C6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF2E55C6).withValues(alpha: 0.4),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 22),
                SizedBox(width: 10),
                Text(
                  'Start Building Itinerary',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 18,
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

  void _startChat() {
    // Clear any previous conversation history
    ItineraryAiService.clearHistory();

    setState(() {
      _isChatActive = true;
      _chatMessages.clear();
      // Add initial AI greeting
      _chatMessages.add(ChatMessage(
        text: ItineraryAiService.getInitialGreeting(widget.trip, _savedLocations),
        isUser: false,
      ));
    });
  }

  Future<void> _sendMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    setState(() {
      _chatMessages.add(ChatMessage(text: message, isUser: true));
      _chatController.clear();
      _isAiTyping = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    // Get AI response
    final response = await ItineraryAiService.sendMessage(
      message: message,
      trip: widget.trip,
      savedLocations: _savedLocations,
    );

    // Add AI response
    setState(() {
      _isAiTyping = false;
      _chatMessages.add(ChatMessage(text: response, isUser: false));
    });

    // Scroll to bottom again
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // Chat messages area
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _chatMessages.length + (_isAiTyping ? 1 : 0),
            itemBuilder: (context, index) {
              // Show typing indicator
              if (_isAiTyping && index == _chatMessages.length) {
                return _buildTypingIndicator();
              }
              return _buildMessageBubble(_chatMessages[index]);
            },
          ),
        ),
        // Input area
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E55C6).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF2E55C6).withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          fontFamily: 'Mona Sans',
                          color: const Color(0xFF2E55C6).withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 16,
                        color: Color(0xFF2E55C6),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E55C6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2E55C6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2E55C6)
                    : const Color(0xFF2E55C6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 15,
                  color: isUser ? Colors.white : const Color(0xFF2E55C6),
                  height: 1.4,
                ),
              ),
            ),
          ),
          // User avatar spacing
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E55C6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E55C6).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF2E55C6).withValues(alpha: 0.4 + (0.3 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }
}
