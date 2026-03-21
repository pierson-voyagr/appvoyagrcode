import 'package:flutter/material.dart';
import 'dart:async';
import 'signup_tags_page.dart';
import '../widgets/signup_header.dart';

class SignUpInterestsPage extends StatefulWidget {
  final String name;
  final DateTime birthday;

  const SignUpInterestsPage({
    super.key,
    required this.name,
    required this.birthday,
  });

  @override
  State<SignUpInterestsPage> createState() => _SignUpInterestsPageState();
}

class _SignUpInterestsPageState extends State<SignUpInterestsPage> {
  final Set<String> _selectedInterests = {};

  // 5 rows of 10 interests each
  final List<List<String>> _interestRows = [
    // Row 1 (scrolls right)
    ['Hiking', 'Photography', 'Clubbing', 'Wine Nights', 'Beach', 'Surfing', 'Yoga', 'Cooking', 'Dancing', 'Gaming'],
    // Row 2 (scrolls left)
    ['Art', 'Music', 'Coffee', 'Travel', 'Reading', 'Fitness', 'Movies', 'Theatre', 'Skiing', 'Running'],
    // Row 3 (scrolls right)
    ['Foodie', 'Cycling', 'Camping', 'Brunch', 'Concerts', 'Museums', 'Nature', 'Swimming', 'Pottery', 'Karaoke'],
    // Row 4 (scrolls left)
    ['Shopping', 'Fashion', 'Festivals', 'Sailing', 'Painting', 'Tennis', 'Golf', 'Climbing', 'Meditation', 'Baking'],
    // Row 5 (scrolls right)
    ['Craft Beer', 'Comedy', 'Gardening', 'Volunteering', 'Board Games', 'Writing', 'Languages', 'Anime', 'Podcasts', 'Vlogging'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
          // Content overlay
          SafeArea(
            child: Column(
              children: [
                // Header with logo and progress bar
                const SignUpHeader(progress: 3 / 7), // Step 3 of 7
                const SizedBox(height: 24),
                // Title and subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Text(
                        'What are your interests?',
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E55C6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select at least three interests',
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E55C6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Scrolling interest rows
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildScrollingRow(_interestRows[0], scrollRight: true),
                      const SizedBox(height: 12),
                      _buildScrollingRow(_interestRows[1], scrollRight: false),
                      const SizedBox(height: 12),
                      _buildScrollingRow(_interestRows[2], scrollRight: true),
                      const SizedBox(height: 12),
                      _buildScrollingRow(_interestRows[3], scrollRight: false),
                      const SizedBox(height: 12),
                      _buildScrollingRow(_interestRows[4], scrollRight: true),
                    ],
                  ),
                ),
                // Continue button at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedInterests.length >= 3
                          ? () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                    SignUpTagsPage(
                                      name: widget.name,
                                      birthday: widget.birthday,
                                      interests: _selectedInterests.toList(),
                                    ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 200),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E55C6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD3D3D3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollingRow(List<String> interests, {required bool scrollRight}) {
    return SizedBox(
      height: 50,
      child: _ScrollingInterestRow(
        interests: interests,
        selectedInterests: _selectedInterests,
        scrollRight: scrollRight,
        onInterestTap: (interest) {
          setState(() {
            if (_selectedInterests.contains(interest)) {
              _selectedInterests.remove(interest);
            } else {
              _selectedInterests.add(interest);
            }
          });
        },
      ),
    );
  }
}

class _ScrollingInterestRow extends StatefulWidget {
  final List<String> interests;
  final Set<String> selectedInterests;
  final bool scrollRight;
  final Function(String) onInterestTap;

  const _ScrollingInterestRow({
    required this.interests,
    required this.selectedInterests,
    required this.scrollRight,
    required this.onInterestTap,
  });

  @override
  State<_ScrollingInterestRow> createState() => _ScrollingInterestRowState();
}

class _ScrollingInterestRowState extends State<_ScrollingInterestRow> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  double _scrollOffset = 0;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Start auto-scrolling after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients && !_isUserInteracting) {
        _scrollOffset += widget.scrollRight ? 1 : -1;

        // Loop the scroll
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (widget.scrollRight && _scrollOffset >= maxScroll) {
          _scrollOffset = 0;
        } else if (!widget.scrollRight && _scrollOffset <= 0) {
          _scrollOffset = maxScroll;
        }

        _scrollController.jumpTo(_scrollOffset.clamp(0.0, maxScroll));
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isUserInteracting = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_scrollController.hasClients) {
      // Move the scroll position based on drag delta
      final newOffset = _scrollController.offset - details.delta.dx;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(newOffset.clamp(0.0, maxScroll));
    }
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isUserInteracting = false;
      // Update scroll offset to current position when user releases
      if (_scrollController.hasClients) {
        _scrollOffset = _scrollController.offset;
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Duplicate the interests list to create seamless loop
    final duplicatedInterests = [...widget.interests, ...widget.interests];

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: duplicatedInterests.length,
        itemBuilder: (context, index) {
          final interest = duplicatedInterests[index];
          final isSelected = widget.selectedInterests.contains(interest);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => widget.onInterestTap(interest),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E55C6) : const Color(0xFFC3DAF4),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    interest,
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF2E55C6),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
