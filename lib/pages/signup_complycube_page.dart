import 'package:flutter/material.dart';
import 'dart:io';
import 'signup_email_password_page.dart';
import '../widgets/signup_header.dart';

class SignUpComplyCubePage extends StatefulWidget {
  final String name;
  final DateTime birthday;
  final List<String> interests;
  final List<String> tags;
  final File? profilePicture;

  const SignUpComplyCubePage({
    super.key,
    required this.name,
    required this.birthday,
    required this.interests,
    required this.tags,
    this.profilePicture,
  });

  @override
  State<SignUpComplyCubePage> createState() => _SignUpComplyCubePageState();
}

class _SignUpComplyCubePageState extends State<SignUpComplyCubePage> {
  void _continueToEmailPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpEmailPasswordPage(
          name: widget.name,
          birthday: widget.birthday,
          interests: widget.interests,
          tags: widget.tags,
          profilePicture: widget.profilePicture,
          clientId: null,
          livePhotoId: null,
        ),
      ),
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
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.92),
                          Colors.white,
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
                const SignUpHeader(progress: 6 / 7), // Step 6 of 7
                const SizedBox(height: 24),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          const Text(
                            'Verify Your Identity',
                            style: TextStyle(
                              fontFamily: 'Mona Sans',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E55C6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'To keep our community safe, we need to verify your identity.',
                            style: TextStyle(
                              fontFamily: 'Mona Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(
                                0xFF2E55C6,
                              ).withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          // Verification steps
                          _buildVerificationStep(
                            icon: Icons.credit_card,
                            title: 'Scan Your ID',
                            description:
                                'Passport, driver\'s license, or national ID',
                          ),
                          const SizedBox(height: 24),
                          _buildVerificationStep(
                            icon: Icons.face,
                            title: 'Take a Selfie',
                            description:
                                'We\'ll verify it matches your ID photo',
                          ),
                          const SizedBox(height: 24),
                          _buildVerificationStep(
                            icon: Icons.security,
                            title: 'Your Data is Secure',
                            description: 'All verification data is encrypted',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Skip for now button at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continueToEmailPassword,
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
                        'Skip for Now',
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

  Widget _buildVerificationStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC3DAF4).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E55C6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E55C6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
    );
  }
}
