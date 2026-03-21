import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'signup_profile_picture_page.dart';
import '../widgets/signup_header.dart';

class SignUpTagsPage extends StatefulWidget {
  final String name;
  final DateTime birthday;
  final List<String> interests;

  const SignUpTagsPage({
    super.key,
    required this.name,
    required this.birthday,
    required this.interests,
  });

  @override
  State<SignUpTagsPage> createState() => _SignUpTagsPageState();
}

class _SignUpTagsPageState extends State<SignUpTagsPage> {
  final Set<String> _selectedTags = {};

  final List<String> _availableTags = [
    'LGBTQ+',
    'Vegan',
    'Sober',
    'Pet Friendly',
    'Disabled',
    'Vegetarian',
    'Gluten Free',
    'Eco-Conscious',
    'Non-Smoker',
    'Spiritual',
    'Halal',
    'Kosher',
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
                const SignUpHeader(progress: 4 / 7), // Step 4 of 7
                const SizedBox(height: 24),
                // Title and subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Text(
                        'Any tags to add?',
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
                        'Optional - Select tags that describe you',
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
                // Floating bubbles
                Expanded(
                  child: _FloatingBubblesArea(
                    tags: _availableTags,
                    selectedTags: _selectedTags,
                    onTagTap: (tag) {
                      setState(() {
                        if (_selectedTags.contains(tag)) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                  ),
                ),
                // Continue button at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                              SignUpProfilePicturePage(
                                name: widget.name,
                                birthday: widget.birthday.toString(),
                                interests: widget.interests,
                                tags: _selectedTags.toList(),
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E55C6),
                        foregroundColor: Colors.white,
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
}

class _FloatingBubblesArea extends StatefulWidget {
  final List<String> tags;
  final Set<String> selectedTags;
  final Function(String) onTagTap;

  const _FloatingBubblesArea({
    required this.tags,
    required this.selectedTags,
    required this.onTagTap,
  });

  @override
  State<_FloatingBubblesArea> createState() => _FloatingBubblesAreaState();
}

class _FloatingBubblesAreaState extends State<_FloatingBubblesArea> {
  final List<_BubbleData> _bubbles = [];
  Timer? _animationTimer;
  final Random _random = Random();
  int? _draggedBubbleIndex;
  Offset? _lastDragPosition;

  @override
  void initState() {
    super.initState();
    // Initialize bubbles with random positions and velocities after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBubbles();
      _startAnimation();
    });
  }

  void _initializeBubbles() {
    final size = MediaQuery.of(context).size;
    final bubbleHeight = size.height * 0.5; // Use half the available height

    setState(() {
      _bubbles.clear();
      for (int i = 0; i < widget.tags.length; i++) {
        final bubbleSize = 80.0 + _random.nextDouble() * 40; // 80-120 size

        // Try to find a non-overlapping position
        Offset position;
        int attempts = 0;
        const maxAttempts = 50;

        do {
          // Spread bubbles across a wider horizontal area to reduce initial overlap
          // Use full screen width plus extra space on left/right
          position = Offset(
            -bubbleSize + _random.nextDouble() * (size.width + bubbleSize * 2),
            _random.nextDouble() * (bubbleHeight - bubbleSize),
          );
          attempts++;
        } while (attempts < maxAttempts && _hasOverlap(position, bubbleSize));

        _bubbles.add(_BubbleData(
          tag: widget.tags[i],
          position: position,
          velocity: Offset(
            0.2 + _random.nextDouble() * 0.3, // Horizontal speed: 0.2-0.5 px per frame (slower)
            0, // No vertical movement
          ),
          size: bubbleSize,
        ));
      }
    });
  }

  bool _hasOverlap(Offset position, double size) {
    const minDistance = 20.0; // Minimum spacing between bubbles

    for (final bubble in _bubbles) {
      final distance = (position - bubble.position).distance;
      final minRequired = (size + bubble.size) / 2 + minDistance;

      if (distance < minRequired) {
        return true;
      }
    }
    return false;
  }

  void _startAnimation() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;

      final size = MediaQuery.of(context).size;
      final bubbleHeight = size.height * 0.5;

      setState(() {
        for (int i = 0; i < _bubbles.length; i++) {
          // Skip the bubble that's being dragged
          if (i == _draggedBubbleIndex) continue;

          final bubble = _bubbles[i];

          // Update position - move left to right
          Offset newPosition = bubble.position + bubble.velocity;

          // When bubble goes off the right edge, wrap it to the left
          if (newPosition.dx > size.width + bubble.size) {
            // Find a non-overlapping Y position when wrapping
            double newY;
            int attempts = 0;
            const maxAttempts = 20;

            do {
              newY = _random.nextDouble() * (bubbleHeight - bubble.size);
              attempts++;
            } while (attempts < maxAttempts && _wouldOverlapAtPosition(
              Offset(-bubble.size, newY),
              bubble.size,
              i,
            ));

            newPosition = Offset(-bubble.size, newY);
          }

          // Ensure bubbles stay within vertical bounds
          newPosition = Offset(
            newPosition.dx,
            newPosition.dy.clamp(0.0, bubbleHeight - bubble.size),
          );

          _bubbles[i] = bubble.copyWith(
            position: newPosition,
          );
        }
      });
    });
  }

  bool _wouldOverlapAtPosition(Offset position, double size, int skipIndex) {
    const minDistance = 20.0; // Minimum spacing between bubbles

    for (int i = 0; i < _bubbles.length; i++) {
      if (i == skipIndex) continue;

      final bubble = _bubbles[i];
      final distance = (position - bubble.position).distance;
      final minRequired = (size + bubble.size) / 2 + minDistance;

      if (distance < minRequired) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bubbleHeight = size.height * 0.5;

    return Stack(
      children: _bubbles.asMap().entries.map((entry) {
        final index = entry.key;
        final bubble = entry.value;
        final isSelected = widget.selectedTags.contains(bubble.tag);

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 50),
          left: bubble.position.dx,
          top: bubble.position.dy,
          child: GestureDetector(
            onTap: () => widget.onTagTap(bubble.tag),
            onPanStart: (details) {
              setState(() {
                _draggedBubbleIndex = index;
                _lastDragPosition = details.globalPosition;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                final delta = details.globalPosition - _lastDragPosition!;
                final newPosition = Offset(
                  bubble.position.dx + delta.dx,
                  (bubble.position.dy + delta.dy).clamp(0.0, bubbleHeight - bubble.size),
                );
                _bubbles[index] = bubble.copyWith(position: newPosition);
                _lastDragPosition = details.globalPosition;
              });
            },
            onPanEnd: (details) {
              setState(() {
                _draggedBubbleIndex = null;
                _lastDragPosition = null;
              });
            },
            child: Container(
              width: bubble.size,
              height: bubble.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2E55C6) : const Color(0xFFC3DAF4),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    bubble.tag,
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: bubble.size * 0.15, // Scale text with bubble
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF2E55C6),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BubbleData {
  final String tag;
  final Offset position;
  final Offset velocity;
  final double size;

  _BubbleData({
    required this.tag,
    required this.position,
    required this.velocity,
    required this.size,
  });

  _BubbleData copyWith({
    String? tag,
    Offset? position,
    Offset? velocity,
    double? size,
  }) {
    return _BubbleData(
      tag: tag ?? this.tag,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      size: size ?? this.size,
    );
  }
}
