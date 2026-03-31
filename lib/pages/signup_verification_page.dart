import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verification_id_page.dart';
import 'home_page.dart';

class SignUpVerificationPage extends StatefulWidget {
  final String phone;
  final String email;
  final String name;
  final String pronouns;
  final DateTime birthday;
  final String hostelCode;
  final List<File?> photos;

  const SignUpVerificationPage({
    super.key,
    required this.phone,
    required this.email,
    required this.name,
    required this.pronouns,
    required this.birthday,
    required this.hostelCode,
    required this.photos,
  });

  @override
  State<SignUpVerificationPage> createState() => _SignUpVerificationPageState();
}

class _SignUpVerificationPageState extends State<SignUpVerificationPage> {
  bool _isSaving = false;

  Future<void> _saveUserAndNavigateHome() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Upload photos to Supabase Storage
      final photoUrls = <String>[];
      for (int i = 0; i < widget.photos.length; i++) {
        final photo = widget.photos[i];
        if (photo == null) continue;

        final fileName = '${user.id}/profile_$i.jpg';
        await Supabase.instance.client.storage
            .from('profile-photos')
            .upload(fileName, photo, fileOptions: const FileOptions(upsert: true));

        final url = Supabase.instance.client.storage
            .from('profile-photos')
            .getPublicUrl(fileName);
        photoUrls.add(url);
      }

      // Save user profile to Supabase
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'name': widget.name,
        'email': widget.email,
        'birthday': widget.birthday.toIso8601String(),
        'is_verified': false,
        'verification_status': 'pending',
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                                email: widget.email,
                                name: widget.name,
                                pronouns: widget.pronouns,
                                birthday: widget.birthday,
                                hostelCode: widget.hostelCode,
                                photos: widget.photos,
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
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isSaving ? null : _saveUserAndNavigateHome,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF2E55C6),
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Skip for now',
                          style: TextStyle(
                            color: Color(0xFF2E55C6),
                            fontSize: 18,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w600,
                          ),
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
