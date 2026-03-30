import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_hostel_code_page.dart';

class SignUpBirthdayPage extends StatefulWidget {
  final String email;
  final String name;
  final String pronouns;

  const SignUpBirthdayPage({
    super.key,
    required this.email,
    required this.name,
    required this.pronouns,
  });

  @override
  State<SignUpBirthdayPage> createState() => _SignUpBirthdayPageState();
}

class _SignUpBirthdayPageState extends State<SignUpBirthdayPage> {
  final TextEditingController _mmController = TextEditingController();
  final TextEditingController _ddController = TextEditingController();
  final TextEditingController _yyyyController = TextEditingController();
  final FocusNode _mmFocus = FocusNode();
  final FocusNode _ddFocus = FocusNode();
  final FocusNode _yyyyFocus = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _mmController.addListener(() => setState(() {}));
    _ddController.addListener(() => setState(() {}));
    _yyyyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mmController.dispose();
    _ddController.dispose();
    _yyyyController.dispose();
    _mmFocus.dispose();
    _ddFocus.dispose();
    _yyyyFocus.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _mmController.text.length == 2 &&
      _ddController.text.length == 2 &&
      _yyyyController.text.length == 4;

  bool _isUnder18() {
    final month = int.tryParse(_mmController.text);
    final day = int.tryParse(_ddController.text);
    final year = int.tryParse(_yyyyController.text);
    if (month == null || day == null || year == null) return true;
    if (month < 1 || month > 12 || day < 1 || day > 31) return true;

    try {
      final birthday = DateTime(year, month, day);
      final now = DateTime.now();
      var age = now.year - birthday.year;
      if (now.month < birthday.month ||
          (now.month == birthday.month && now.day < birthday.day)) {
        age--;
      }
      return age < 18;
    } catch (_) {
      return true;
    }
  }

  void _onNext() {
    if (!_canContinue) return;

    if (_isUnder18()) {
      setState(() {
        _errorText = 'You must be 18 or older to sign up.';
      });
      return;
    }

    setState(() => _errorText = null);

    final month = int.parse(_mmController.text);
    final day = int.parse(_ddController.text);
    final year = int.parse(_yyyyController.text);
    final birthday = DateTime(year, month, day);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpHostelCodePage(
          email: widget.email,
          name: widget.name,
          pronouns: widget.pronouns,
          birthday: birthday,
        ),
      ),
    );
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 31, right: 31),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'WHEN IS YOUR BIRTHDAY?',
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
                // Date input: MM / DD / YYYY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 31),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 45,
                            child: TextField(
                              controller: _mmController,
                              focusNode: _mmFocus,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              style: const TextStyle(
                                color: Color(0xFF2E55C6),
                                fontSize: 24,
                                fontFamily: 'Mona Sans',
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'MM',
                                hintStyle: TextStyle(
                                  color: Color(0xFF2E55C6),
                                  fontSize: 24,
                                  fontFamily: 'Mona Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                if (value.length == 2) _ddFocus.requestFocus();
                              },
                            ),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(
                              color: Color(0xFF2E55C6),
                              fontSize: 24,
                              fontFamily: 'Mona Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: TextField(
                              controller: _ddController,
                              focusNode: _ddFocus,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              style: const TextStyle(
                                color: Color(0xFF2E55C6),
                                fontSize: 24,
                                fontFamily: 'Mona Sans',
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'DD',
                                hintStyle: TextStyle(
                                  color: Color(0xFF2E55C6),
                                  fontSize: 24,
                                  fontFamily: 'Mona Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                if (value.length == 2) _yyyyFocus.requestFocus();
                              },
                            ),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(
                              color: Color(0xFF2E55C6),
                              fontSize: 24,
                              fontFamily: 'Mona Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: _yyyyController,
                              focusNode: _yyyyFocus,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: const TextStyle(
                                color: Color(0xFF2E55C6),
                                fontSize: 24,
                                fontFamily: 'Mona Sans',
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'YYYY',
                                hintStyle: TextStyle(
                                  color: Color(0xFF2E55C6),
                                  fontSize: 24,
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
                      const SizedBox(height: 8),
                      Container(
                        width: 219,
                        height: 3,
                        color: const Color(0xFF2E55C6),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontFamily: 'Mona Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}
