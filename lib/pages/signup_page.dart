import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'signup_code_page.dart';

class _CountryCode {
  final String name;
  final String code;
  const _CountryCode(this.name, this.code);
}

const _countryCodes = [
  _CountryCode('United States', '1'),
  _CountryCode('United Kingdom', '44'),
  _CountryCode('Canada', '1'),
  _CountryCode('Australia', '61'),
  _CountryCode('Germany', '49'),
  _CountryCode('France', '33'),
  _CountryCode('Spain', '34'),
  _CountryCode('Italy', '39'),
  _CountryCode('Brazil', '55'),
  _CountryCode('Mexico', '52'),
  _CountryCode('Japan', '81'),
  _CountryCode('South Korea', '82'),
  _CountryCode('China', '86'),
  _CountryCode('India', '91'),
  _CountryCode('Russia', '7'),
  _CountryCode('South Africa', '27'),
  _CountryCode('Nigeria', '234'),
  _CountryCode('Egypt', '20'),
  _CountryCode('Kenya', '254'),
  _CountryCode('Ghana', '233'),
  _CountryCode('UAE', '971'),
  _CountryCode('Saudi Arabia', '966'),
  _CountryCode('Turkey', '90'),
  _CountryCode('Netherlands', '31'),
  _CountryCode('Belgium', '32'),
  _CountryCode('Switzerland', '41'),
  _CountryCode('Austria', '43'),
  _CountryCode('Sweden', '46'),
  _CountryCode('Norway', '47'),
  _CountryCode('Denmark', '45'),
  _CountryCode('Finland', '358'),
  _CountryCode('Poland', '48'),
  _CountryCode('Portugal', '351'),
  _CountryCode('Greece', '30'),
  _CountryCode('Ireland', '353'),
  _CountryCode('New Zealand', '64'),
  _CountryCode('Singapore', '65'),
  _CountryCode('Malaysia', '60'),
  _CountryCode('Thailand', '66'),
  _CountryCode('Philippines', '63'),
  _CountryCode('Indonesia', '62'),
  _CountryCode('Vietnam', '84'),
  _CountryCode('Argentina', '54'),
  _CountryCode('Colombia', '57'),
  _CountryCode('Chile', '56'),
  _CountryCode('Peru', '51'),
  _CountryCode('Israel', '972'),
  _CountryCode('Pakistan', '92'),
  _CountryCode('Bangladesh', '880'),
  _CountryCode('Hong Kong', '852'),
  _CountryCode('Taiwan', '886'),
];

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  _CountryCode? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _selectedCountry != null &&
      _phoneController.text.trim().length >= 7;

  bool _isLoading = false;

  Future<void> _onNext() async {
    if (!_canContinue || _isLoading) return;
    final phone = '+${_selectedCountry!.code}${_phoneController.text.trim()}';

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpCodePage(
            countryCode: _selectedCountry!.code,
            phoneNumber: _phoneController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send code: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Country',
                style: TextStyle(
                  color: Color(0xFF2E55C6),
                  fontSize: 20,
                  fontFamily: 'Mona Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _countryCodes.length,
                  itemBuilder: (context, index) {
                    final country = _countryCodes[index];
                    return ListTile(
                      title: Text(
                        country.name,
                        style: const TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E55C6),
                        ),
                      ),
                      trailing: Text(
                        '+${country.code}',
                        style: const TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E55C6),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountry = country;
                        });
                        Navigator.pop(context);
                        _phoneFocusNode.requestFocus();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Rotated star image hanging off top-right
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
          // Main content
          SafeArea(
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
                const SizedBox(height: 16),
                // Title - 2 lines
                Padding(
                  padding: const EdgeInsets.only(left: 31, right: 31),
                  child: const Text(
                    'CAN WE GET YOUR NUMBER?',
                    style: TextStyle(
                      color: Color(0xFF2E55C6),
                      fontSize: 42,
                      fontFamily: 'Mona Sans SemiCondensed',
                      fontWeight: FontWeight.w800,
                      height: 1.17,
                    ),
                  ),
                ),
                const Spacer(),
                // Phone input row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 31),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Country code picker
                          GestureDetector(
                            onTap: _showCountryPicker,
                            child: Row(
                              children: [
                                Text(
                                  _selectedCountry != null
                                      ? '+${_selectedCountry!.code}'
                                      : '+ ##',
                                  style: const TextStyle(
                                    color: Color(0xFF2E55C6),
                                    fontSize: 24,
                                    fontFamily: 'Mona Sans',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF2E55C6),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Phone number section
                          IntrinsicWidth(
                            child: TextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(15),
                              ],
                              style: const TextStyle(
                                color: Color(0xFF2E55C6),
                                fontSize: 24,
                                fontFamily: 'Mona Sans',
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'TYPE DIGITS HERE',
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
                      // Single underline
                      Container(
                        width: 310,
                        height: 3,
                        color: const Color(0xFF2E55C6),
                      ),
                      const SizedBox(height: 12),
                      // Warning text
                      const Text(
                        'You will not be able to Connect with others until this step is completed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF2E55C6),
                          fontSize: 16,
                          fontFamily: 'Mona Sans',
                          fontWeight: FontWeight.w600,
                          height: 1.75,
                        ),
                      ),
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
                        child: _isLoading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2E55C6),
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
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
