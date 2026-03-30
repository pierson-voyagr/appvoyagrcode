import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/id_analyzer_service.dart';

class VerificationSelfiePage extends StatefulWidget {
  final String email;
  final String name;
  final String pronouns;
  final DateTime birthday;
  final String hostelCode;
  final List<File?> photos;
  final File idPhoto;

  const VerificationSelfiePage({
    super.key,
    required this.email,
    required this.name,
    required this.pronouns,
    required this.birthday,
    required this.hostelCode,
    required this.photos,
    required this.idPhoto,
  });

  @override
  State<VerificationSelfiePage> createState() => _VerificationSelfiePageState();
}

class _VerificationSelfiePageState extends State<VerificationSelfiePage> {
  final ImagePicker _picker = ImagePicker();
  File? _selfiePhoto;
  bool _isVerifying = false;

  Future<void> _captureSelfie() async {
    final hasCamera = await _picker.supportsImageSource(ImageSource.camera);
    final picked = await _picker.pickImage(
      source: hasCamera ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() {
        _selfiePhoto = File(picked.path);
      });
    }
  }

  Future<void> _onVerify() async {
    if (_selfiePhoto == null || _isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      final result = await IdAnalyzerService.verify(
        documentImage: widget.idPhoto,
        selfieImage: _selfiePhoto!,
      );

      if (!mounted) return;

      final isMatch = IdAnalyzerService.isFaceMatch(result);
      final confidence = IdAnalyzerService.getFaceConfidence(result);

      if (isMatch) {
        // Verification successful
        _showResultDialog(
          title: 'VERIFIED!',
          message: 'Your identity has been verified successfully.',
          success: true,
        );
      } else {
        // Face didn't match
        _showResultDialog(
          title: 'VERIFICATION FAILED',
          message:
              'Your selfie didn\'t match the photo on your ID. Please try again.',
          success: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'ERROR',
        message: 'Something went wrong. Please try again.\n\n$e',
        success: false,
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool success,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: success ? const Color(0xFF2E55C6) : Colors.red,
            fontSize: 24,
            fontFamily: 'Mona Sans',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF2E55C6),
            fontSize: 16,
            fontFamily: 'Mona Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFCEDAF4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: MaterialButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    if (success) {
                      // TODO: Navigate to completion / home
                      // For now, pop back to the start
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    success ? 'CONTINUE' : 'TRY AGAIN',
                    style: const TextStyle(
                      color: Color(0xFF2E55C6),
                      fontSize: 20,
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
                      'TAKE A SELFIE',
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
                    'We\'ll match your selfie to your ID photo to verify your identity.',
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
                // Selfie preview or capture
                GestureDetector(
                  onTap: _captureSelfie,
                  child: Container(
                    width: 220,
                    height: 220,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFCEDAF4),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 2.5,
                          color: Color(0xFF2E55C6),
                        ),
                        borderRadius: BorderRadius.circular(110),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 6,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: _selfiePhoto != null
                        ? ClipOval(
                            child: Image.file(
                              _selfiePhoto!,
                              fit: BoxFit.cover,
                              width: 220,
                              height: 220,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.face,
                                color: Color(0xFF2E55C6),
                                size: 56,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'TAP TO CAPTURE',
                                style: TextStyle(
                                  color: Color(0xFF2E55C6),
                                  fontSize: 16,
                                  fontFamily: 'Mona Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_selfiePhoto != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _captureSelfie,
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
                // VERIFY button
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
                        onPressed:
                            _selfiePhoto != null ? _onVerify : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2E55C6),
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'VERIFY',
                                style: TextStyle(
                                  color: _selfiePhoto != null
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
