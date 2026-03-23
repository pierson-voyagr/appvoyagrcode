import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'settings_page.dart';
import '../data/languages.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _selectedTab = 'Profile'; // Track selected tab
  List<String> _uploadedPhotos = []; // Track uploaded photos (max 6)
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _interestsSearchController = TextEditingController();
  final TextEditingController _tagsSearchController = TextEditingController();
  final TextEditingController _languagesSearchController = TextEditingController();
  final TextEditingController _homeBaseController = TextEditingController();
  List<String> _selectedInterests = []; // Track selected interests
  List<String> _selectedTags = []; // Track selected tags
  List<String> _selectedLanguages = []; // Track selected languages
  int _minAge = 18; // Minimum age preference
  int _maxAge = 99; // Maximum age preference
  int _budgetLevel = 2; // Budget preference (0-4 for 1-5 dollar signs)
  int _travelStyle = 2; // Travel style (0=Relaxed, 1=Between Relaxed/Balanced, 2=Balanced, 3=Between Balanced/Adventurous, 4=Adventurous)
  String _genderPreference = "Doesn't matter"; // Gender preference
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: const Color(0xFF2E55C6),
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
              hideBottomControls: true,
            ),
            IOSUiSettings(
              title: 'Crop Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
            ),
          ],
        );

        if (croppedFile != null && mounted) {
          setState(() {
            _uploadedPhotos.add(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF2E55C6)),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF2E55C6)),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _interestsSearchController.dispose();
    _tagsSearchController.dispose();
    _languagesSearchController.dispose();
    _homeBaseController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final List<String> photoCards = [
      'lib/assets/AUSTIN/Austin 1.jpg',
      'lib/assets/AUSTIN/Austin 2.jpg',
      'lib/assets/AUSTIN/Austin 3.jpg',
      'lib/assets/AUSTIN/Austin 4.jpg',
      'lib/assets/AUSTIN/Austin 5.jpg',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // White background
          Positioned.fill(
            child: Container(color: Colors.white),
          ),
          // Voyagr star icon - top left, behind content
          Positioned(
            top: -20,
            left: -20,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateZ(0.28),
              child: Image.asset(
                'lib/assets/voyagr_star_light_blue.png',
                width: 165.24,
                height: 221.58,
              ),
            ),
          ),
          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Settings button top right
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 4),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: 39,
                        height: 39,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCEDAF4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Color(0xFF2E55C6),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                // "HEY YOU" header - stationary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      'HEY YOU',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF2E55C6),
                        fontSize: 96,
                        fontFamily: 'Mona Sans SemiCondensed',
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Scrollable content below
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Horizontal scrolling photo cards
                        SizedBox(
                  height: 233,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
                    itemCount: photoCards.length + 1,
                    itemBuilder: (context, index) {
                      // Last item is the "ADD PHOTO" card
                      if (index == photoCards.length) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => _showImageSourceDialog(),
                            child: Container(
                              width: 175,
                              height: 219,
                              clipBehavior: Clip.antiAlias,
                              decoration: ShapeDecoration(
                                color: const Color(0xFFCEDAF4),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 2.50,
                                    color: Color(0xFF2E55C6),
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x3F000000),
                                    blurRadius: 6,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Star decoration
                                  Positioned(
                                    left: 55,
                                    top: -5,
                                    child: Transform(
                                      transform: Matrix4.identity()..rotateZ(-0.12),
                                      child: Image.asset(
                                        'lib/assets/voyagr_star_blue.png',
                                        width: 132,
                                        height: 177,
                                      ),
                                    ),
                                  ),
                                  // "ADD PHOTO" text
                                  const Positioned(
                                    left: 12,
                                    bottom: 12,
                                    right: 12,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'ADD PHOTO',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF2E55C6),
                                          fontSize: 30,
                                          fontFamily: 'Mona Sans SemiCondensed',
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          width: 175,
                          height: 219,
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            image: DecorationImage(
                              image: AssetImage(photoCards[index]),
                              fit: BoxFit.cover,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x3F000000),
                                blurRadius: 6,
                                offset: Offset(4, 4),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                  const SizedBox(height: 24),
                  // BIO section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BIO',
                          style: TextStyle(
                            color: Color(0xFF2E55C6),
                            fontSize: 48,
                            fontFamily: 'Mona Sans SemiCondensed',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bioController,
                          maxLines: 5,
                          style: const TextStyle(
                            color: Color(0xFF2E55C6),
                            fontSize: 20,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tell us about yourself...',
                            hintStyle: TextStyle(
                              color: const Color(0xFF2E55C6).withValues(alpha: 0.4),
                              fontSize: 20,
                              fontFamily: 'Mona Sans',
                              fontWeight: FontWeight.w600,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // INTERESTS section
                        const Text(
                          'INTERESTS',
                          style: TextStyle(
                            color: Color(0xFF2E55C6),
                            fontSize: 48,
                            fontFamily: 'Mona Sans SemiCondensed',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSearchBox(_interestsSearchController),
                        const SizedBox(height: 32),
                        // TAGS section
                        const Text(
                          'TAGS',
                          style: TextStyle(
                            color: Color(0xFF2E55C6),
                            fontSize: 48,
                            fontFamily: 'Mona Sans SemiCondensed',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSearchBox(_tagsSearchController),
                        const SizedBox(height: 32),
                        // LANGUAGES section
                        const Text(
                          'LANGUAGES',
                          style: TextStyle(
                            color: Color(0xFF2E55C6),
                            fontSize: 48,
                            fontFamily: 'Mona Sans SemiCondensed',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Selected language pills
                        if (_selectedLanguages.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedLanguages.map((lang) {
                              final isFirst = _selectedLanguages.indexOf(lang) == 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: ShapeDecoration(
                                  color: isFirst ? const Color(0xFFFAF5A1) : const Color(0xFF2E55C6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      lang.toUpperCase(),
                                      style: TextStyle(
                                        color: isFirst ? Colors.black : Colors.white,
                                        fontSize: 20,
                                        fontFamily: 'Mona Sans',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedLanguages.remove(lang);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: isFirst ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildSearchBox(_languagesSearchController),
                        // Language suggestions
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _languagesSearchController,
                          builder: (context, value, child) {
                            if (value.text.isEmpty) return const SizedBox.shrink();
                            final query = value.text.toLowerCase();
                            final matches = allLanguages
                                .where((l) =>
                                    l.toLowerCase().contains(query) &&
                                    !_selectedLanguages.contains(l))
                                .take(5)
                                .toList();
                            if (matches.isEmpty) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(top: 4, right: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: matches.map((lang) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedLanguages.add(lang);
                                        _languagesSearchController.clear();
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Text(
                                        lang,
                                        style: const TextStyle(
                                          color: Color(0xFF2E55C6),
                                          fontSize: 18,
                                          fontFamily: 'Mona Sans',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                      ],
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

  Widget _buildSearchBox(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(right: 10, bottom: 10),
      child: Container(
        height: 41,
        decoration: BoxDecoration(
          color: const Color(0x59D9D9D9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 17),
            const Icon(Icons.search, color: Color(0xFF2E55C6), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: Color(0xFF2E55C6),
                  fontSize: 20,
                  fontFamily: 'Mona Sans',
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: Color(0xFF2E55C6),
                    fontSize: 20,
                    fontFamily: 'Mona Sans',
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title) {
    final bool isSelected = _selectedTab == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E55C6) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photos Card
          _buildProfileCard(
            title: 'Photos',
            subtitle: 'Add up to six photos (${_uploadedPhotos.length}/6)',
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _uploadedPhotos.length < 6
                    ? _uploadedPhotos.length + 1
                    : 6,
                itemBuilder: (context, index) {
                  final itemWidth = (MediaQuery.of(context).size.width - 80) / 2.5;

                  if (index < _uploadedPhotos.length) {
                    return Container(
                      width: itemWidth,
                      margin: EdgeInsets.only(right: index < 5 ? 10 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: _uploadedPhotos[index].startsWith('/')
                              ? FileImage(File(_uploadedPhotos[index]))
                              : AssetImage(_uploadedPhotos[index]) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  } else if (_uploadedPhotos.length < 6) {
                    return GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: itemWidth,
                        margin: EdgeInsets.only(right: index < 5 ? 10 : 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2E55C6).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Color(0xFF2E55C6),
                              size: 28,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontFamily: 'Mona Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E55C6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bio Card
          _buildProfileCard(
            title: 'Bio',
            subtitle: '${_bioController.text.length}/500 characters',
            child: TextField(
              controller: _bioController,
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tell us about yourself...',
                hintStyle: TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFBBBBBB),
                ),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.5,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          // Interests Card
          _buildProfileCard(
            title: 'Interests',
            subtitle: '${_selectedInterests.length} selected',
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _interestsSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for interests',
                      hintStyle: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFBBBBBB),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF999999),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (_selectedInterests.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedInterests.map((interest) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedInterests.remove(interest);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E55C6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                interest,
                                style: const TextStyle(
                                  fontFamily: 'Mona Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tags Card
          _buildProfileCard(
            title: 'Tags',
            subtitle: '${_selectedTags.length} selected',
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _tagsSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for tags',
                      hintStyle: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFBBBBBB),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF999999),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (_selectedTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTags.remove(tag);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E55C6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tag,
                                style: const TextStyle(
                                  fontFamily: 'Mona Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Languages Card
          _buildProfileCard(
            title: 'Languages',
            subtitle: '${_selectedLanguages.length} selected',
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _languagesSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for languages',
                      hintStyle: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFBBBBBB),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF999999),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (_selectedLanguages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedLanguages.map((language) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLanguages.remove(language);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E55C6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                language,
                                style: const TextStyle(
                                  fontFamily: 'Mona Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Home Base Card
          _buildProfileCard(
            title: 'Home Base',
            subtitle: 'Where are you based?',
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _homeBaseController,
                decoration: const InputDecoration(
                  hintText: 'Enter your city',
                  hintStyle: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFBBBBBB),
                  ),
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF999999),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Save Changes button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _saveChanges();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E55C6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age Range Card
          _buildPreferenceCard(
            title: 'Age Range',
            subtitle: '$_minAge - $_maxAge years',
            child: Row(
              children: [
                // Minimum age wheel
                Expanded(
                  child: _buildAgeWheel(
                    label: 'Minimum',
                    value: _minAge,
                    onChanged: (value) {
                      setState(() {
                        _minAge = value;
                        if (_minAge > _maxAge) {
                          _maxAge = _minAge;
                        }
                      });
                    },
                  ),
                ),
                // Center divider
                Container(
                  width: 1,
                  height: 120,
                  color: const Color(0xFFE8E8E8),
                ),
                // Maximum age wheel
                Expanded(
                  child: _buildAgeWheel(
                    label: 'Maximum',
                    value: _maxAge,
                    onChanged: (value) {
                      setState(() {
                        _maxAge = value;
                        if (_maxAge < _minAge) {
                          _minAge = _maxAge;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Budget Card
          _buildPreferenceCard(
            title: 'Budget',
            subtitle: _getBudgetLabel(),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF2E55C6),
                    inactiveTrackColor: const Color(0xFFE8E8E8),
                    thumbColor: const Color(0xFF2E55C6),
                    overlayColor: const Color(0xFF2E55C6).withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _budgetLevel.toDouble(),
                    min: 0,
                    max: 4,
                    divisions: 4,
                    onChanged: (value) {
                      setState(() {
                        _budgetLevel = value.round();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 12,
                        fontWeight: _budgetLevel == 0 ? FontWeight.w700 : FontWeight.w500,
                        color: _budgetLevel == 0 ? const Color(0xFF2E55C6) : const Color(0xFF999999),
                      ),
                    ),
                    Text(
                      'Comfort',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 12,
                        fontWeight: _budgetLevel == 2 ? FontWeight.w700 : FontWeight.w500,
                        color: _budgetLevel == 2 ? const Color(0xFF2E55C6) : const Color(0xFF999999),
                      ),
                    ),
                    Text(
                      'Luxury',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 12,
                        fontWeight: _budgetLevel == 4 ? FontWeight.w700 : FontWeight.w500,
                        color: _budgetLevel == 4 ? const Color(0xFF2E55C6) : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Travel Style Card
          _buildPreferenceCard(
            title: 'Travel Style',
            subtitle: _getTravelStyleLabel(),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF2E55C6),
                    inactiveTrackColor: const Color(0xFFE8E8E8),
                    thumbColor: const Color(0xFF2E55C6),
                    overlayColor: const Color(0xFF2E55C6).withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _travelStyle.toDouble(),
                    min: 0,
                    max: 4,
                    divisions: 4,
                    onChanged: (value) {
                      setState(() {
                        _travelStyle = value.round();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Relaxed',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 12,
                        fontWeight: _travelStyle == 0 ? FontWeight.w700 : FontWeight.w500,
                        color: _travelStyle == 0 ? const Color(0xFF2E55C6) : const Color(0xFF999999),
                      ),
                    ),
                    Text(
                      'Balanced',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 12,
                        fontWeight: _travelStyle == 2 ? FontWeight.w700 : FontWeight.w500,
                        color: _travelStyle == 2 ? const Color(0xFF2E55C6) : const Color(0xFF999999),
                      ),
                    ),
                    Text(
                      'Adventurous',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 12,
                        fontWeight: _travelStyle == 4 ? FontWeight.w700 : FontWeight.w500,
                        color: _travelStyle == 4 ? const Color(0xFF2E55C6) : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Gender Preference Card
          _buildPreferenceCard(
            title: 'Gender Preference',
            subtitle: _genderPreference,
            child: GestureDetector(
              onTap: () {
                _showGenderPreferenceDialog();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _genderPreference,
                      style: const TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF999999),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Save Changes button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _savePreferences();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E55C6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _getBudgetLabel() {
    switch (_budgetLevel) {
      case 0:
        return 'Budget';
      case 1:
        return 'Budget-Comfort';
      case 2:
        return 'Comfort';
      case 3:
        return 'Comfort-Luxury';
      case 4:
        return 'Luxury';
      default:
        return 'Comfort';
    }
  }

  String _getTravelStyleLabel() {
    switch (_travelStyle) {
      case 0:
        return 'Relaxed';
      case 1:
        return 'Relaxed-Balanced';
      case 2:
        return 'Balanced';
      case 3:
        return 'Balanced-Adventurous';
      case 4:
        return 'Adventurous';
      default:
        return 'Balanced';
    }
  }

  Widget _buildSafetyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Upgrade to Premium" card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E55C6),
                  Color(0xFF4A6FD8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E55C6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Premium icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Unlock exclusive safety features',
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // "Safety" card - larger card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with icon and title
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E55C6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Color(0xFF2E55C6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Safety',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Safety description
                const Text(
                  'Your safety is our top priority. Here you can manage your safety settings and preferences.',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Safety features list
                _buildSafetyFeatureItem(
                  icon: Icons.verified_user,
                  title: 'Identity Verification',
                  subtitle: 'Verify your identity for added trust',
                ),
                const SizedBox(height: 16),
                _buildSafetyFeatureItem(
                  icon: Icons.emergency,
                  title: 'Emergency Contacts',
                  subtitle: 'Add contacts for emergencies',
                ),
                const SizedBox(height: 16),
                _buildSafetyFeatureItem(
                  icon: Icons.location_on,
                  title: 'Location Sharing',
                  subtitle: 'Share your location with trusted contacts',
                ),
                const SizedBox(height: 16),
                _buildSafetyFeatureItem(
                  icon: Icons.block,
                  title: 'Blocked Users',
                  subtitle: 'Manage your blocked users list',
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Extra padding to scroll above navbar
        ],
      ),
    );
  }

  Widget _buildSafetyFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Handle safety feature tap
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2E55C6),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFCCCCCC),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeWheel({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Scrollable number picker
        SizedBox(
          height: 100,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 36,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              onChanged(18 + index); // Start from age 18
            },
            controller: FixedExtentScrollController(
              initialItem: value - 18, // Offset by 18
            ),
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final age = 18 + index;
                if (age > 99) return null; // Max age 99
                final isSelected = age == value;
                return Center(
                  child: Text(
                    age.toString(),
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: isSelected ? 26 : 18,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF2E55C6) : const Color(0xFF999999),
                    ),
                  ),
                );
              },
              childCount: 82, // Ages 18-99
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showGenderPreferenceDialog() {
    final options = [
      'Woman required',
      'Woman preferred',
      "Doesn't matter",
      'Man preferred',
      'Man required',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  'Gender Preference',
                  style: TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Options
              ...options.map((option) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _genderPreference = option;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: _genderPreference == option
                          ? const Color(0xFF2E55C6).withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 16,
                        fontWeight: _genderPreference == option ? FontWeight.w600 : FontWeight.w500,
                        color: _genderPreference == option
                            ? const Color(0xFF2E55C6)
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    // TODO: Implement saving to Supabase
    // Save bio: _bioController.text
    // Save photos: _uploadedPhotos
    // Save interests: _selectedInterests
    // Save tags: _selectedTags
    // Save languages: _selectedLanguages
    // Save home base: _homeBaseController.text

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved successfully!'),
          backgroundColor: Color(0xFF2E55C6),
        ),
      );
    }
  }

  Future<void> _savePreferences() async {
    // TODO: Implement saving preferences to Supabase
    // Save min age: _minAge
    // Save max age: _maxAge
    // Save budget level: _budgetLevel
    // Save travel style: _travelStyle
    // Save gender preference: _genderPreference

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully!'),
          backgroundColor: Color(0xFF2E55C6),
        ),
      );
    }
  }
}
