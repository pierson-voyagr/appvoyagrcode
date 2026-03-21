import 'package:flutter/material.dart';
import 'home_page.dart';
import 'signup_page.dart';
import 'login_email_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
                const Spacer(flex: 2),
                // Logo
                Image.asset(
                  'lib/assets/Voyagr Logo - Light Blue.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const Spacer(flex: 3),
                // Buttons at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // Get Started button (dark blue)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
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
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Already have an account text with clickable Sign in
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontFamily: 'Mona Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E55C6),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginEmailPage()),
                              );
                            },
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                fontFamily: 'Mona Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E55C6),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
