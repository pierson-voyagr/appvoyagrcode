import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'signup_verification_page.dart';

class SignUpPicturesPage extends StatefulWidget {
  final String email;
  final String name;
  final String pronouns;
  final DateTime birthday;
  final String hostelCode;

  const SignUpPicturesPage({
    super.key,
    required this.email,
    required this.name,
    required this.pronouns,
    required this.birthday,
    required this.hostelCode,
  });

  @override
  State<SignUpPicturesPage> createState() => _SignUpPicturesPageState();
}

class _SignUpPicturesPageState extends State<SignUpPicturesPage> {
  final List<File?> _photos = List.filled(6, null);
  final ImagePicker _picker = ImagePicker();

  bool get _canContinue => _photos.any((p) => p != null);

  Future<void> _pickPhoto(int index) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _photos[index] = File(picked.path);
      });
    }
  }

  void _onNext() {
    if (!_canContinue) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpVerificationPage(
          email: widget.email,
          name: widget.name,
          pronouns: widget.pronouns,
          birthday: widget.birthday,
          hostelCode: widget.hostelCode,
          photos: _photos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            right: -80,
            top: -60,
            child: Transform.rotate(
              angle: -0.31,
              child: Image.asset(
                'lib/assets/voyagr_star_light_blue.png',
                width: 320,
                height: 420,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, top: 10),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF2E55C6),
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 31, right: 31),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'LETS ADD SOME PICTURES!!!',
                      style: TextStyle(
                        color: Color(0xFF2E55C6),
                        fontSize: 42,
                        fontFamily: 'Mona Sans SemiCondensed',
                        fontWeight: FontWeight.w800,
                        height: 1.17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // 2 rows of 3 photo slots
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPhotoSlot(0),
                          _buildPhotoSlot(1),
                          _buildPhotoSlot(2),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPhotoSlot(3),
                          _buildPhotoSlot(4),
                          _buildPhotoSlot(5),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // NEXT button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 34, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFCEDAF4),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: MaterialButton(
                        onPressed: _canContinue ? _onNext : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'NEXT',
                          style: TextStyle(
                            color: _canContinue
                                ? const Color(0xFF2E55C6)
                                : const Color(0xFFB2B2BA),
                            fontSize: 32,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w700,
                          ),
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

  Widget _buildPhotoSlot(int index) {
    final photo = _photos[index];
    return GestureDetector(
      onTap: () => _pickPhoto(index),
      child: SizedBox(
        width: 116,
        height: 170,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Photo container
            Container(
              width: 116,
              height: 145,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: const Color(0xFFCEDAF4),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 2.5,
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
              child: photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(27.5),
                      child: Image.file(
                        photo,
                        fit: BoxFit.cover,
                        width: 116,
                        height: 145,
                      ),
                    )
                  : null,
            ),
            // Circle button at bottom right
            Positioned(
              right: -6,
              bottom: 12,
              child: GestureDetector(
                onTap: () {
                  if (photo != null) {
                    setState(() => _photos[index] = null);
                  } else {
                    _pickPhoto(index);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: ShapeDecoration(
                    color: photo != null
                        ? const Color(0xFFCEDAF4)
                        : const Color(0xFF2E55C6),
                    shape: const OvalBorder(),
                  ),
                  child: photo != null
                      ? const Icon(
                          Icons.close,
                          color: Color(0xFF2E55C6),
                          size: 22,
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'lib/assets/voyagr_star_light_blue.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
