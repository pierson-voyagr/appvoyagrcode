import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import '../supabase_config.dart';
import 'home_page.dart';
import '../widgets/signup_header.dart';

class SignUpEmailPasswordPage extends StatefulWidget {
  final String name;
  final DateTime birthday;
  final List<String> interests;
  final List<String> tags;
  final File? profilePicture;
  final String? livePhotoId;
  final String? clientId;

  const SignUpEmailPasswordPage({
    super.key,
    required this.name,
    required this.birthday,
    required this.interests,
    required this.tags,
    this.profilePicture,
    this.livePhotoId,
    this.clientId,
  });

  @override
  State<SignUpEmailPasswordPage> createState() =>
      _SignUpEmailPasswordPageState();
}

class _SignUpEmailPasswordPageState extends State<SignUpEmailPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool _canSignUp() {
    return _emailController.text.isNotEmpty &&
        _isValidEmail(_emailController.text) &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text.length >= 6 &&
        _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _signUp() async {
    if (!_canSignUp()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user with Supabase Auth
      final response = await SupabaseConfig.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw Exception('Sign up failed');
      }

      // Insert user profile data directly
      final Map<String, dynamic> userData = {
        'id': response.user!.id,
        'name': widget.name,
        'email': _emailController.text.trim(),
        'birthday': widget.birthday.toIso8601String(),
        'interests': widget.interests,
        'tags': widget.tags,
      };

      // Add liveness verification data if available
      if (widget.livePhotoId != null) {
        userData['complycube_live_photo_ids'] = [widget.livePhotoId];
        userData['liveness_verified'] = true;
        userData['liveness_verified_at'] = DateTime.now().toIso8601String();
      }

      if (widget.clientId != null) {
        userData['complycube_client_id'] = widget.clientId;
      }

      await SupabaseConfig.client.from('users').insert(userData);

      // Navigate to home page
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(initialIndex: 3),
          ),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.message.contains('Password')) {
          _errorMessage = 'The password provided is too weak.';
        } else if (e.message.contains('already registered')) {
          _errorMessage = 'An account already exists for that email.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }
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
                const SignUpHeader(progress: 7 / 7), // Step 7 of 7 (complete)
                const SizedBox(height: 24),
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E55C6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        // Email field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontFamily: 'Mona Sans',
                            color: Color(0xFF2E55C6),
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              fontFamily: 'Mona Sans',
                              color: const Color(
                                0xFF2E55C6,
                              ).withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E55C6),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E55C6),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E55C6),
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontFamily: 'Mona Sans',
                            color: Color(0xFF2E55C6),
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password (min 6 characters)',
                            hintStyle: TextStyle(
                              fontFamily: 'Mona Sans',
                              color: const Color(
                                0xFF2E55C6,
                              ).withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(
                                  0xFF2E55C6,
                                ).withValues(alpha: 0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E55C6),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E55C6),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E55C6),
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password field
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(
                            fontFamily: 'Mona Sans',
                            color: Color(0xFF2E55C6),
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            hintStyle: TextStyle(
                              fontFamily: 'Mona Sans',
                              color: const Color(
                                0xFF2E55C6,
                              ).withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(
                                  0xFF2E55C6,
                                ).withValues(alpha: 0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E55C6),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E55C6),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E55C6),
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        // Error message display
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontFamily: 'Mona Sans',
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Divider with "or"
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(
                                  0xFF2E55C6,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  fontFamily: 'Mona Sans',
                                  color: const Color(
                                    0xFF2E55C6,
                                  ).withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(
                                  0xFF2E55C6,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Social sign-in buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google sign-in
                            _buildSocialButton(
                              icon: Icons.g_mobiledata,
                              label: 'Google',
                              onTap: () {
                                // TODO: Implement Google sign-in
                              },
                            ),
                            const SizedBox(width: 16),
                            // Apple sign-in
                            _buildSocialButton(
                              icon: Icons.apple,
                              label: 'Apple',
                              onTap: () {
                                // TODO: Implement Apple sign-in
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Sign up button at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSignUp() && !_isLoading ? _signUp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E55C6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD3D3D3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: Lottie.asset(
                                'lib/assets/VOYAGR STAR YELLOW.json',
                                fit: BoxFit.contain,
                              ),
                            )
                          : const Text(
                              'Sign Up',
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

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF2E55C6), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2E55C6), size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Mona Sans',
                color: Color(0xFF2E55C6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
