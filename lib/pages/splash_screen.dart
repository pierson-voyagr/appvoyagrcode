import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Show logo for 1 second
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Transition to animation
    setState(() {
      _showAnimation = true;
    });

    // Show animation for 2.5 seconds (enough time for it to play)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Navigate to login page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/homepage_logo1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showAnimation
                ? Lottie.asset(
                    'lib/assets/VOYAGR STAR YELLOW.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    key: const ValueKey('animation'),
                  )
                : Image.asset(
                    'lib/assets/Voyagr Logo - Light Blue.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                    key: const ValueKey('logo'),
                  ),
          ),
        ),
      ),
    );
  }
}
