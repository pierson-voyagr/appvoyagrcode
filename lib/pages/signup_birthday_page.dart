import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'signup_interests_page.dart';
import '../widgets/signup_header.dart';

class SignUpBirthdayPage extends StatefulWidget {
  final String name;

  const SignUpBirthdayPage({super.key, required this.name});

  @override
  State<SignUpBirthdayPage> createState() => _SignUpBirthdayPageState();
}

class _SignUpBirthdayPageState extends State<SignUpBirthdayPage> {
  final TextEditingController _birthdayController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime tempDate = _selectedDate ?? DateTime(2000);

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: const Color(0xFF1C1C1E),
          child: Column(
            children: [
              // Header with Cancel and Done buttons
              Container(
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2C2E),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF48484A),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF2E55C6),
                          fontSize: 17,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Color(0xFF2E55C6),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDate = tempDate;
                          _birthdayController.text =
                              '${tempDate.month}/${tempDate.day}/${tempDate.year}';
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              // Date Picker
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: tempDate,
                    minimumDate: DateTime(1900),
                    maximumDate: DateTime.now(),
                    backgroundColor: const Color(0xFF1C1C1E),
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
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
    final bool canContinue = _selectedDate != null;

    return Scaffold(
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
          // Content overlay
          SafeArea(
            child: Column(
              children: [
                // Header with logo and progress bar
                const SignUpHeader(progress: 2 / 7), // Step 2 of 7
                const SizedBox(height: 24),
                const Spacer(),
                // Content in the middle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'What is your birthday?',
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E55C6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _birthdayController.text.isEmpty
                                  ? 'Birthday'
                                  : _birthdayController.text,
                                style: TextStyle(
                                  fontFamily: 'Mona Sans',
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: _birthdayController.text.isEmpty
                                    ? const Color(0xFFE0E0E0)
                                    : const Color(0xFF2E55C6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Continue button at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canContinue
                          ? () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                    SignUpInterestsPage(
                                      name: widget.name,
                                      birthday: _selectedDate!,
                                    ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 200),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E55C6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD3D3D3),
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
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
