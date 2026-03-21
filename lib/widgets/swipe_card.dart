import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SwipeCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final int currentPhotoIndex;
  final Function(bool isRight) onPhotoTap;
  final double dragX;
  final double dragY;
  final double angle;

  const SwipeCard({
    super.key,
    required this.profile,
    required this.currentPhotoIndex,
    required this.onPhotoTap,
    this.dragX = 0,
    this.dragY = 0,
    this.angle = 0,
  });

  /// Builds the ordered page sequence:
  /// Page 0: first photo with name/age/city overlay
  /// Page 1: bio (if exists)
  /// Page 2: second photo plain (if exists)
  /// Page 3: interests (if exists)
  /// Page 4+: remaining photos
  List<Map<String, dynamic>> _buildPageSequence() {
    final photos = profile['photos'];
    final photoCount = (photos != null && photos is List) ? photos.length : 0;
    final hasBio = profile['bio'] != null && profile['bio'].toString().isNotEmpty;
    final interests = profile['interests'];
    final hasInterests = interests != null && interests is List && interests.isNotEmpty;
    final hasTravelStyle = profile['travel_style'] != null && profile['travel_style'].toString().isNotEmpty;

    final pages = <Map<String, dynamic>>[];
    int nextPhoto = 0;

    // Page 0: first photo with overlay
    if (photoCount > 0) {
      pages.add({'type': 'photo', 'photoIdx': 0, 'overlay': true});
      nextPhoto = 1;
    }

    // Page 1: bio
    if (hasBio) {
      pages.add({'type': 'bio'});
    }

    // Page 2: second photo (plain)
    if (nextPhoto < photoCount) {
      pages.add({'type': 'photo', 'photoIdx': nextPhoto, 'overlay': false});
      nextPhoto++;
    }

    // Page 3: interests
    if (hasInterests) {
      pages.add({'type': 'interests'});
    }

    // Page 4: third photo (plain)
    if (nextPhoto < photoCount) {
      pages.add({'type': 'photo', 'photoIdx': nextPhoto, 'overlay': false});
      nextPhoto++;
    }

    // Page 5: travel style (with next photo as background)
    if (hasTravelStyle) {
      final bgIdx = nextPhoto < photoCount ? nextPhoto : 0;
      if (nextPhoto < photoCount) nextPhoto++;
      pages.add({'type': 'travel_style', 'photoIdx': bgIdx});
    }

    // Remaining photos
    while (nextPhoto < photoCount) {
      pages.add({'type': 'photo', 'photoIdx': nextPhoto, 'overlay': false});
      nextPhoto++;
    }

    // Fallback
    if (pages.isEmpty) {
      pages.add({'type': 'photo', 'photoIdx': 0, 'overlay': true});
    }

    return pages;
  }

  /// Static helper so ConnectPage can calculate total pages
  static int getTotalPages(Map<String, dynamic> profile) {
    final photos = profile['photos'];
    final photoCount = (photos != null && photos is List) ? photos.length : 0;
    final hasBio = profile['bio'] != null && profile['bio'].toString().isNotEmpty;
    final interests = profile['interests'];
    final hasInterests = interests != null && interests is List && interests.isNotEmpty;
    final hasTravelStyle = profile['travel_style'] != null && profile['travel_style'].toString().isNotEmpty;

    int total = 0;
    int nextPhoto = 0;
    if (photoCount > 0) { total++; nextPhoto = 1; }
    if (hasBio) total++;
    if (nextPhoto < photoCount) { total++; nextPhoto++; }
    if (hasInterests) total++;
    if (nextPhoto < photoCount) { total++; nextPhoto++; }
    if (hasTravelStyle) {
      total++;
      if (nextPhoto < photoCount) nextPhoto++;
    }
    total += (photoCount > nextPhoto) ? photoCount - nextPhoto : 0;
    return total > 0 ? total : 1;
  }

  Widget _buildProfileImage({required int photoIndex}) {
    final photos = profile['photos'];

    if (photos != null && photos is List && photos.isNotEmpty) {
      final idx = photoIndex.clamp(0, photos.length - 1);
      final photoUrl = photos[idx] as String;

      if (photoUrl.startsWith('lib/assets/') || photoUrl.startsWith('assets/')) {
        return Image.asset(
          photoUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.person, size: 100, color: Color(0xFF2E55C6)),
            );
          },
        );
      } else {
        return Image.network(
          photoUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.person, size: 100, color: Color(0xFF2E55C6)),
            );
          },
        );
      }
    }

    return const Center(
      child: Icon(Icons.person, size: 100, color: Color(0xFF2E55C6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (profile['name'] ?? 'Unknown').toString().split(' ').first;
    final age = profile['age']?.toString() ?? '';
    final city = profile['city'] ?? 'Unknown';
    final country = profile['country'] ?? '';

    String locationText = city;
    if (country.isNotEmpty) {
      final countryCode = _getCountryCode(country);
      locationText = '$city, $countryCode';
    }

    return Transform.translate(
      offset: Offset(dragX, dragY),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardW = constraints.maxWidth;
                final cardH = constraints.maxHeight;
                final s = cardW / 473.0;

                // Determine which page to show
                final pages = _buildPageSequence();
                final safeIndex = currentPhotoIndex.clamp(0, pages.length - 1);
                final page = pages[safeIndex];
                final pageType = page['type'] as String;

                if (pageType == 'bio') {
                  return _buildBioPage(s, cardW);
                }
                if (pageType == 'interests') {
                  return _buildInterestsPage(s, cardW);
                }
                if (pageType == 'travel_style') {
                  final bgPhotoIdx = page['photoIdx'] as int;
                  return _buildTravelStylePage(s, cardW, cardH, bgPhotoIdx);
                }

                // Photo page
                final photoIdx = page['photoIdx'] as int;
                final showOverlay = page['overlay'] as bool;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Full-bleed profile image
                    Positioned.fill(
                      child: GestureDetector(
                        onTapUp: (details) {
                          final isRightSide = details.localPosition.dx > cardW / 2;
                          onPhotoTap(isRightSide);
                        },
                        child: _buildProfileImage(photoIndex: photoIdx),
                      ),
                    ),

                    if (showOverlay) ...[
                      // Blue name rectangle — rotation -0.03 rad
                      Positioned(
                        left: 26.45 * s,
                        bottom: 80.6 * s,
                        child: Transform(
                          transform: Matrix4.identity()..rotateZ(-0.03),
                          child: Container(
                            width: 314 * s,
                            height: 70 * s,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E55C6),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(left: 14 * s),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$name ',
                                  style: TextStyle(
                                    fontFamily: 'Mona Sans',
                                    fontSize: 48 * s,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Age circle — white, 49x49, rotation -0.02 rad
                      Positioned(
                        left: 270.58 * s,
                        bottom: 96.49 * s,
                        child: Transform(
                          transform: Matrix4.identity()..rotateZ(-0.02),
                          child: Container(
                            width: 49 * s,
                            height: 49 * s,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                age,
                                style: TextStyle(
                                  fontFamily: 'Mona Sans',
                                  fontSize: 32 * s,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2E55C6),
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Yellow pill box — 90 radius corners
                      Positioned(
                        left: 40 * s,
                        bottom: 22 * s,
                        child: Container(
                          width: 214 * s,
                          height: 70 * s,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEFFC1),
                            borderRadius: BorderRadius.circular(90),
                          ),
                          child: Center(
                            child: Text(
                              locationText,
                              style: TextStyle(
                                fontFamily: 'Mona Sans',
                                fontSize: 36 * s,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                      // Voyagr star — rotation -0.12 rad
                      Positioned(
                        left: 299 * s,
                        bottom: 20 * s,
                        child: Transform(
                          transform: Matrix4.identity()..rotateZ(-0.12),
                          child: Lottie.asset(
                            'lib/assets/VOYAGR STAR YELLOW.json',
                            width: 66.48 * s,
                            height: 89.14 * s,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Bio page ──────────────────────────────────────────────────────────

  Widget _buildBioPage(double s, double cardW) {
    final name = (profile['name'] ?? 'Unknown').toString().split(' ').first;
    final bio = profile['bio']?.toString() ?? '';

    // Strip emojis — Mona Sans can't render them
    final cleanBio = bio.replaceAll(RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}'
      r'\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}'
      r'\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}'
      r'\u{1FA70}-\u{1FAFF}\u{200D}\u{20E3}\u{E0020}-\u{E007F}]',
      unicode: true,
    ), '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    final fullText = '"$name here! $cleanBio"';
    final lines = _splitBioIntoLines(fullText);

    final leftOffsets = [83.95, 17.32, 57.64, 104.0, 21.49, 48.79, 35.19, 127.48, 46.93, 121.31];
    const lineSpacing = 36.5;
    final totalTextHeight = lines.length * lineSpacing;
    final startTop = (751.0 - totalTextHeight) / 2.0;
    final fontSize = 36.0 * s;

    return GestureDetector(
      onTapUp: (details) {
        final isRightSide = details.localPosition.dx > cardW / 2;
        onPhotoTap(isRightSide);
      },
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            for (int i = 0; i < lines.length; i++) ...[
              Positioned(
                left: (leftOffsets[i % leftOffsets.length] - 0.7) * s,
                top: (startTop + i * lineSpacing + 8) * s,
                child: Container(
                  width: _measureTextWidth(lines[i], fontSize) + 2 * s,
                  height: 36 * s,
                  decoration: const BoxDecoration(color: Color(0xFFE7F1FD)),
                ),
              ),
              Positioned(
                left: leftOffsets[i % leftOffsets.length] * s,
                top: (startTop + i * lineSpacing) * s,
                child: Text(
                  lines[i],
                  style: TextStyle(
                    color: const Color(0xFF2E55C6),
                    fontSize: fontSize,
                    fontFamily: 'Mona Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Interests page ────────────────────────────────────────────────────

  Widget _buildInterestsPage(double s, double cardW) {
    final interests = profile['interests'] as List? ?? [];
    final cleanInterests = interests.map((e) => _stripEmojis(e.toString())).toList();

    final fontSize = 36.0 * s;
    final pillHeight = 58.0 * s;
    final hPadding = 20.0 * s;
    final gap = -4.0 * s; // negative gap allows horizontal overlap

    // Gravity container: 3/4 width, centered
    final containerWidth = cardW * 0.75;
    final containerLeft = (cardW - containerWidth) / 2;

    // Tight row spacing — pills overlap and sit on/behind each other
    final rowSpacing = pillHeight * 0.55;

    // Deterministic random from profile name
    final rng = math.Random(profile['name'].hashCode);

    // Pill colors: (background, textColor)
    final pillColors = [
      (const Color(0xFFFAF5A1), Colors.black),
      (const Color(0xFF2E55C6), Colors.white),
      (const Color(0xFFC3DAF4), Colors.black),
      (const Color(0xFF2E55C6), Colors.white),
      (const Color(0xFFFEFFC1), Colors.black),
    ];

    // Measure each pill width
    final pillWidths = cleanInterests.map((text) {
      return _measureTextWidth(text, fontSize, FontWeight.w900) + hPadding * 2;
    }).toList();

    // Pack pills into rows (bottom-up) within the container width
    final rows = <List<Map<String, dynamic>>>[];
    var currentRow = <Map<String, dynamic>>[];
    var rowWidth = 0.0;

    for (int i = 0; i < cleanInterests.length; i++) {
      final w = pillWidths[i];
      final needed = currentRow.isEmpty ? w : w + gap;
      if (rowWidth + needed > containerWidth && currentRow.isNotEmpty) {
        rows.add(currentRow);
        currentRow = [];
        rowWidth = 0;
      }
      currentRow.add({
        'text': cleanInterests[i],
        'width': w,
        'colorIndex': i,
      });
      rowWidth += currentRow.length == 1 ? w : w + gap;
    }
    if (currentRow.isNotEmpty) rows.add(currentRow);

    // Center the pile vertically in the card
    final totalPileHeight = rows.length * rowSpacing;
    // Use top-based positioning: center the pile vertically
    // cardH isn't available here, so we use the 751 reference scaled by s
    final cardRefH = 751.0 * s;
    final pileTopStart = (cardRefH - totalPileHeight) / 2;

    final pillWidgets = <Widget>[];

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];

      // Total width of this row
      var totalRowWidth = 0.0;
      for (final p in row) {
        totalRowWidth += p['width'] as double;
      }
      totalRowWidth += (row.length - 1) * gap;

      // Center row with slight horizontal jitter
      final rowJitterX = (rng.nextDouble() - 0.5) * 16 * s;
      var x = containerLeft + (containerWidth - totalRowWidth) / 2 + rowJitterX;

      for (int p = 0; p < row.length; p++) {
        final pill = row[p];
        final ci = pill['colorIndex'] as int;
        final w = pill['width'] as double;

        // Alternating tilts — pills lean into each other
        // Odd/even index determines lean direction, with some randomness
        final direction = (ci % 2 == 0) ? 1.0 : -1.0;
        final tiltAmount = 0.08 + rng.nextDouble() * 0.10; // 0.08–0.18 rad (~5–10°)
        final rotation = direction * tiltAmount;

        // Slight vertical jitter
        final yJitter = (rng.nextDouble() - 0.5) * 6 * s;

        pillWidgets.add(
          Positioned(
            left: x,
            top: pileTopStart + r * rowSpacing + yJitter,
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: w,
                height: pillHeight,
                decoration: ShapeDecoration(
                  color: pillColors[ci % pillColors.length].$1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Center(
                  child: Text(
                    pill['text'] as String,
                    style: TextStyle(
                      color: pillColors[ci % pillColors.length].$2,
                      fontSize: fontSize,
                      fontFamily: 'Mona Sans',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        x += w + gap;
      }
    }

    return GestureDetector(
      onTapUp: (details) {
        final isRightSide = details.localPosition.dx > cardW / 2;
        onPhotoTap(isRightSide);
      },
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Pills (rendered first, behind star and title)
            ...pillWidgets,

            // Voyagr star — bottom right, rotation -0.18 rad (behind title)
            Positioned(
              left: 325 * s,
              bottom: 23 * s,
              child: Transform(
                transform: Matrix4.identity()..rotateZ(-0.18),
                child: Image.asset(
                  'lib/assets/Branding/LOGO FILES/Icon/PNG/Voyagr Star Icon - Light Blue.png',
                  width: 141.72 * s,
                  height: 190.04 * s,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // "INTERESTS" title — bottom left, 23px from bottom (on top of star)
            Positioned(
              left: 34 * s,
              bottom: 23 * s,
              child: Text(
                'INTERESTS',
                style: TextStyle(
                  color: const Color(0xFF2E55C6),
                  fontSize: 70 * s,
                  fontFamily: 'Mona Sans',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Travel Style page ──────────────────────────────────────────────

  Widget _buildTravelStylePage(double s, double cardW, double cardH, int photoIdx) {
    final rawStyle = (profile['travel_style'] ?? 'Explorer').toString().toUpperCase();
    // Add stylized trailing letters (e.g. ADVENTUROUS → ADVENTUROUSSS)
    final travelStyle = '${rawStyle}SS';
    final fontSize = 36.0 * s;

    return GestureDetector(
      onTapUp: (details) {
        final isRightSide = details.localPosition.dx > cardW / 2;
        onPhotoTap(isRightSide);
      },
      child: Stack(
        children: [
          // Background photo
          Positioned.fill(
            child: _buildProfileImage(photoIndex: photoIdx),
          ),

          // Single blue bar running full card height, rotated -1.57 rad
          // Positioned at bottom-left, rotates upward
          Positioned(
            left: 13 * s,
            bottom: 0,
            child: Transform(
              transform: Matrix4.identity()..rotateZ(-1.57),
              alignment: Alignment.bottomLeft,
              child: Container(
                width: cardH,
                height: 45 * s,
                decoration: const BoxDecoration(color: Color(0xFF2E55C6)),
              ),
            ),
          ),

          // "TRAVEL STYLE:" text — bottom end of the bar
          Positioned(
            left: 10 * s,
            bottom: 10 * s,
            child: Transform(
              transform: Matrix4.identity()..rotateZ(-1.57),
              child: Text(
                'TRAVEL STYLE:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontFamily: 'Mona Sans',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          // Travel style value text — top end of the bar
          Positioned(
            left: 10 * s,
            top: cardH * 0.46,
            child: Transform(
              transform: Matrix4.identity()..rotateZ(-1.57),
              child: Text(
                travelStyle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontFamily: 'Mona Sans',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _stripEmojis(String text) {
    return text.replaceAll(RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}'
      r'\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}'
      r'\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}'
      r'\u{1FA70}-\u{1FAFF}\u{200D}\u{20E3}\u{E0020}-\u{E007F}]',
      unicode: true,
    ), '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  double _measureTextWidth(String text, double fontSize, [FontWeight weight = FontWeight.w600]) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Mona Sans',
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  List<String> _splitBioIntoLines(String text) {
    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) return [text];

    final lines = <String>[];
    var currentLine = words[0];
    var lineIdx = 0;
    final targets = [16, 22, 10, 13, 23, 23, 14, 16, 19, 19];

    for (var i = 1; i < words.length; i++) {
      final target = targets[lineIdx % targets.length];
      if (currentLine.length + 1 + words[i].length > target) {
        lines.add(currentLine);
        currentLine = words[i];
        lineIdx++;
      } else {
        currentLine += ' ${words[i]}';
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }

  String _getCountryCode(String country) {
    final codes = {
      'United Kingdom': 'UK',
      'UK': 'UK',
      'United States': 'US',
      'USA': 'US',
      'Japan': 'JP',
      'South Korea': 'KR',
      'Italy': 'IT',
      'France': 'FR',
      'Germany': 'DE',
      'Spain': 'ES',
      'Australia': 'AU',
      'Canada': 'CA',
      'Monaco': 'MC',
    };
    return codes[country] ?? country;
  }
}
