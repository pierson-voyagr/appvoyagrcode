import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'signup_page.dart';
import 'login_email_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-bleed background image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/WK_Voyagr_20251230-final-19.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.54, -1.0),
            ),
          ),
          // Content overlay
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Logo
                Center(
                  child: Image.asset(
                    'lib/assets/Voyagr Logo - Light Blue.png',
                    width: 251,
                    height: 62,
                    fit: BoxFit.cover,
                  ),
                ),
                const Spacer(flex: 7),
                // SIGN UP button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpPage()),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'SIGN UP',
                          style: TextStyle(
                            color: Color(0xFF2E55C6),
                            fontSize: 32,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Already have an account? Sign in
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Mona Sans',
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign in',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginEmailPage()),
                            );
                          },
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
