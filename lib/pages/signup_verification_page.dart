import 'dart:io';
import 'package:flutter/material.dart';
import 'verification_id_page.dart';

class SignUpVerificationPage extends StatelessWidget {
  final String email;
  final String name;
  final String pronouns;
  final DateTime birthday;
  final String hostelCode;
  final List<File?> photos;

  const SignUpVerificationPage({
    super.key,
    required this.email,
    required this.name,
    required this.pronouns,
    required this.birthday,
    required this.hostelCode,
    required this.photos,
  });

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
                const Spacer(),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: const Text(
                    'TIME TO GET VERIFIED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2E55C6),
                      fontSize: 42,
                      fontFamily: 'Mona Sans SemiCondensed',
                      fontWeight: FontWeight.w800,
                      height: 1.17,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: const Text(
                    'This is a paragraph about why it is required to complete a biometric face check with a selfie, and also to upload an ID to prevent fraud, and catfishing. Learn More',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2E55C6),
                      fontSize: 20,
                      fontFamily: 'Mona Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Warning text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: const Text(
                    'You will not be able to Connect with others until this step is completed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2E55C6),
                      fontSize: 20,
                      fontFamily: 'Mona Sans',
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                    ),
                  ),
                ),
                const Spacer(),
                // GET STARTED button
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerificationIdPage(
                                email: email,
                                name: name,
                                pronouns: pronouns,
                                birthday: birthday,
                                hostelCode: hostelCode,
                                photos: photos,
                              ),
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'GET STARTED',
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
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
