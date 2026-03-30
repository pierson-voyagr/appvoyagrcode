import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'verification_selfie_page.dart';

class VerificationIdPage extends StatefulWidget {
  final String email;
  final String name;
  final String pronouns;
  final DateTime birthday;
  final String hostelCode;
  final List<File?> photos;

  const VerificationIdPage({
    super.key,
    required this.email,
    required this.name,
    required this.pronouns,
    required this.birthday,
    required this.hostelCode,
    required this.photos,
  });

  @override
  State<VerificationIdPage> createState() => _VerificationIdPageState();
}

class _VerificationIdPageState extends State<VerificationIdPage> {
  final ImagePicker _picker = ImagePicker();
  File? _idPhoto;

  Future<void> _captureId() async {
    final hasCamera = await _picker.supportsImageSource(ImageSource.camera);
    final picked = await _picker.pickImage(
      source: hasCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() {
        _idPhoto = File(picked.path);
      });
    }
  }

  void _onNext() {
    if (_idPhoto == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationSelfiePage(
          email: widget.email,
          name: widget.name,
          pronouns: widget.pronouns,
          birthday: widget.birthday,
          hostelCode: widget.hostelCode,
          photos: widget.photos,
          idPhoto: _idPhoto!,
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
                      'SCAN YOUR ID',
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 31),
                  child: const Text(
                    'Take a clear photo of the front of your passport, driver\'s license, or national ID.',
                    style: TextStyle(
                      color: Color(0xFF2E55C6),
                      fontSize: 18,
                      fontFamily: 'Mona Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const Spacer(),
                // ID photo preview or capture button
                GestureDetector(
                  onTap: _captureId,
                  child: Container(
                    width: 300,
                    height: 200,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFCEDAF4),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 2.5,
                          color: Color(0xFF2E55C6),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 6,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: _idPhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(17.5),
                            child: Image.file(
                              _idPhoto!,
                              fit: BoxFit.cover,
                              width: 300,
                              height: 200,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Color(0xFF2E55C6),
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'TAP TO CAPTURE',
                                style: TextStyle(
                                  color: Color(0xFF2E55C6),
                                  fontSize: 18,
                                  fontFamily: 'Mona Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_idPhoto != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _captureId,
                    child: const Text(
                      'RETAKE',
                      style: TextStyle(
                        color: Color(0xFF2E55C6),
                        fontSize: 16,
                        fontFamily: 'Mona Sans',
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
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
                        onPressed: _idPhoto != null ? _onNext : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'NEXT',
                          style: TextStyle(
                            color: _idPhoto != null
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
}
