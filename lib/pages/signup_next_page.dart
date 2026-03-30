import 'package:flutter/material.dart';

class SignUpNextPage extends StatelessWidget {
  const SignUpNextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
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
            const Text(
              'Phone Verified!',
              style: TextStyle(
                color: Color(0xFF2E55C6),
                fontSize: 32,
                fontFamily: 'Mona Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Next step coming soon...',
              style: TextStyle(
                color: Color(0xFF2E55C6),
                fontSize: 18,
                fontFamily: 'Mona Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
