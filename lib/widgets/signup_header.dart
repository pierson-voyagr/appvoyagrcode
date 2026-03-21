import 'package:flutter/material.dart';
import 'signup_progress_bar.dart';

class SignUpHeader extends StatelessWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  const SignUpHeader({
    super.key,
    required this.progress,
    this.onBack,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top navigation bar with logo inline
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2E55C6)),
                onPressed: onBack ?? () => Navigator.pop(context),
              ),
              // Logo in the center
              Image.asset(
                'lib/assets/Voyagr Logo - Light Blue.png',
                width: 100,
                height: 25,
                fit: BoxFit.contain,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF2E55C6)),
                onPressed: onClose ?? () => Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Progress bar with animated star
        SignUpProgressBar(progress: progress),
      ],
    );
  }
}
