import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'signup_complycube_page.dart';
import '../widgets/signup_header.dart';

class SignUpProfilePicturePage extends StatefulWidget {
  final String name;
  final String birthday;
  final List<String> interests;
  final List<String> tags;

  const SignUpProfilePicturePage({
    super.key,
    required this.name,
    required this.birthday,
    required this.interests,
    required this.tags,
  });

  @override
  State<SignUpProfilePicturePage> createState() =>
      _SignUpProfilePicturePageState();
}

class _SignUpProfilePicturePageState extends State<SignUpProfilePicturePage> {
  File? _profilePicture;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        // Crop image to vertical 9:16 aspect ratio
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo (Vertical Only)',
              toolbarColor: const Color(0xFF2E55C6),
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
              hideBottomControls: true,
            ),
            IOSUiSettings(
              title: 'Crop Photo (Vertical Only)',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _profilePicture = File(croppedFile.path);
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
      backgroundColor: const Color(0xFF2C2C2E),
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
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
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
                          Colors.white.withValues(
                            alpha: 0.6,
                          ), // 60% opacity at 26%
                          Colors.white.withValues(
                            alpha: 0.92,
                          ), // 92% opacity at 34%
                          Colors.white, // 100% opacity at 100%
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
                const SignUpHeader(progress: 5 / 7), // Step 5 of 7
                const SizedBox(height: 24),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Text(
                        'Add Your Profile Picture',
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E55C6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Profile picture preview - 4:5 aspect ratio
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: CustomPaint(
                        painter: DashedBorderPainter(),
                        child: Container(
                          width: 240,
                          height: 300,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _profilePicture == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_camera,
                                      size: 64,
                                      color: const Color(
                                        0xFF2E55C6,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _profilePicture!,
                                    width: 240,
                                    height: 300,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Continue button at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _profilePicture != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUpComplyCubePage(
                                    name: widget.name,
                                    birthday: DateTime.parse(widget.birthday),
                                    interests: widget.interests,
                                    tags: widget.tags,
                                    profilePicture: _profilePicture,
                                  ),
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
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E55C6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    const borderRadius = 12.0;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(borderRadius),
        ),
      );

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = pathMetric.extractPath(
          distance,
          nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
