import 'package:flutter/material.dart';

class CityStickerDetailPage extends StatelessWidget {
  final String cityName;

  const CityStickerDetailPage({
    super.key,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          // Back button
          Positioned(
            top: 64,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2E55C6)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // City name centered
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: 20,
            right: 20,
            child: Text(
              cityName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E55C6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
