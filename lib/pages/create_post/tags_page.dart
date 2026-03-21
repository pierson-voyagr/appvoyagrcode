import 'dart:io';
import 'package:flutter/material.dart';
import 'preview_page.dart';

class TagsPage extends StatefulWidget {
  final List<File> photos;
  final String caption;

  const TagsPage({
    super.key,
    required this.photos,
    required this.caption,
  });

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  final List<String> _availableTags = [
    'Sport',
    'Coffee',
    'Photography',
    'Travel',
    'Music',
    'Food',
    'Art',
    'Reading',
    'Nightlife',
    'Nature',
    'Culture',
    'Shopping',
  ];

  final List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Tags',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _navigateToPreview,
            child: const Text(
              'Next',
              style: TextStyle(
                color: Color(0xFF2E55C6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tag your post',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help others find your post by adding relevant tags',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Selected tags count
            if (_selectedTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${_selectedTags.length} tag${_selectedTags.length == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                    color: Color(0xFF2E55C6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Tags grid
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFC3DAF4)
                              : const Color(0xFF2C2C2E),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2E55C6)
                                : const Color(0xFF48484A),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF2E55C6)
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Helper text
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Tags are optional but help connect your post with others who share similar interests',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewPage(
          photos: widget.photos,
          caption: widget.caption,
          tags: _selectedTags,
        ),
      ),
    );
  }
}
