import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SignUpProgressBar extends StatelessWidget {
  final double progress;

  const SignUpProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Progress bar background
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFD3D3D3), // Grey background
              borderRadius: BorderRadius.circular(9),
            ),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2E55C6),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
          // Animated star at the end of the progress bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            left: (progress * (MediaQuery.of(context).size.width - 64) - 35).clamp(0.0, MediaQuery.of(context).size.width - 134),
            top: -31,
            child: SizedBox(
              width: 80,
              height: 80,
              child: Lottie.asset(
                'lib/assets/VOYAGR STAR YELLOW.json',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
