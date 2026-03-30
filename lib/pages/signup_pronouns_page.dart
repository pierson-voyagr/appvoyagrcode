import 'package:flutter/material.dart';
import 'signup_birthday_page.dart';

class SignUpPronounsPage extends StatefulWidget {
  final String email;
  final String name;

  const SignUpPronounsPage({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<SignUpPronounsPage> createState() => _SignUpPronounsPageState();
}

class _SignUpPronounsPageState extends State<SignUpPronounsPage> {
  String? _selectedPronoun;
  final TextEditingController _otherController = TextEditingController();
  bool _isOtherSelected = false;

  @override
  void initState() {
    super.initState();
    _otherController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _selectedPronoun != null ||
      (_isOtherSelected && _otherController.text.trim().isNotEmpty);

  String get _pronounValue {
    if (_isOtherSelected) return _otherController.text.trim();
    return _selectedPronoun ?? '';
  }

  void _selectPronoun(String pronoun) {
    setState(() {
      _selectedPronoun = pronoun;
      _isOtherSelected = false;
    });
  }

  void _selectOther() {
    setState(() {
      _selectedPronoun = null;
      _isOtherSelected = true;
    });
  }

  void _onNext() {
    if (!_canContinue) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpBirthdayPage(
          email: widget.email,
          name: widget.name,
          pronouns: _pronounValue,
        ),
      ),
    );
  }

  // Chip colors from Figma: yellow (#FAF5A1), blue (#2E55C6), light blue (#CEDAF4)
  static const _chipStyles = [
    {'label': 'He/Him', 'bg': Color(0xFFFAF5A1), 'textColor': Colors.black},
    {'label': 'She/Her', 'bg': Color(0xFF2E55C6), 'textColor': Colors.white},
    {'label': 'They/Them', 'bg': Color(0xFFCEDAF4), 'textColor': Color(0xFF2E55C6)},
    {'label': 'Prefer not to say', 'bg': Color(0xFFFAF5A1), 'textColor': Colors.black},
  ];

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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 31, right: 31),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'WHAT ARE YOUR PRONOUNS?',
                      style: TextStyle(
                        color: Color(0xFF2E55C6),
                        fontSize: 42,
                        fontFamily: 'Mona Sans SemiCondensed',
                        fontWeight: FontWeight.w800,
                        height: 1.17,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Pronoun chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 9,
                    children: [
                      ..._chipStyles.map((style) {
                        final label = style['label'] as String;
                        final isSelected = _selectedPronoun == label;
                        return _buildChip(
                          label: label,
                          bgColor: style['bg'] as Color,
                          textColor: style['textColor'] as Color,
                          isSelected: isSelected,
                          onTap: () => _selectPronoun(label),
                        );
                      }),
                      // Other chip
                      _buildOtherChip(),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                // NEXT button
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
                        onPressed: _canContinue ? _onNext : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'NEXT',
                          style: TextStyle(
                            color: _canContinue
                                ? const Color(0xFF2E55C6)
                                : const Color(0xFFB2B2BA),
                            fontSize: 32,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color bgColor,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontFamily: 'Mona Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOtherChip() {
    return GestureDetector(
      onTap: _selectOther,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2E55C6),
          borderRadius: BorderRadius.circular(30),
          boxShadow: _isOtherSelected
              ? const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: _isOtherSelected
            ? IntrinsicWidth(
                child: Row(
                  children: [
                    const Text(
                      'Other: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Mona Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _otherController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Mona Sans',
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type Here',
                          hintStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const Text(
                'Other: Type Here',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Mona Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
