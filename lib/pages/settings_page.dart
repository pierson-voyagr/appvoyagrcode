import 'package:flutter/material.dart';
import '../supabase_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditingPhone = false;
  bool _isEditingEmail = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppVersion();
  }

  Future<void> _loadUserData() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user != null) {
      setState(() {
        _emailController.text = user.email ?? '';
        _phoneController.text = user.phone ?? '';
      });
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'v1.0.0';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header card with Settings title and Done button
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E55C6),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E55C6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium card - full width
                    _buildPremiumCard(),
                    const SizedBox(height: 12),
                    // Get Boost and Buy Trips - side by side
                    Row(
                      children: [
                        Expanded(child: _buildBoostCard()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildBuyTripsCard()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Account Settings section
                    _buildSectionTitle('Account Settings'),
                    const SizedBox(height: 12),
                    _buildAccountSettingsCard(),
                    const SizedBox(height: 24),
                    // Manage Payment
                    _buildSettingsItem(
                      icon: Icons.credit_card,
                      title: 'Manage Payment',
                      onTap: () => _showManagePaymentSheet(),
                    ),
                    const SizedBox(height: 12),
                    // Contact Us
                    _buildSettingsItem(
                      icon: Icons.mail_outline,
                      title: 'Contact Us',
                      onTap: () => _showContactUsSheet(),
                    ),
                    const SizedBox(height: 24),
                    // Privacy section
                    _buildSectionTitle('Privacy'),
                    const SizedBox(height: 12),
                    _buildPrivacyCard(),
                    const SizedBox(height: 24),
                    // Legal section
                    _buildSectionTitle('Legal'),
                    const SizedBox(height: 12),
                    _buildLegalCard(),
                    const SizedBox(height: 32),
                    // Log Out button
                    _buildLogoutButton(),
                    const SizedBox(height: 16),
                    // Version number
                    Center(
                      child: Text(
                        _appVersion,
                        style: const TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Delete Account
                    Center(
                      child: GestureDetector(
                        onTap: () => _showDeleteAccountDialog(),
                        child: const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontFamily: 'Mona Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Mona Sans',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to premium subscription
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E55C6), Color(0xFF5B7FD6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E55C6).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voyagr Premium',
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Unlock unlimited matches & features',
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostCard() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to boost purchase
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bolt,
                color: Color(0xFFFFB300),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Get Boost',
              style: TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Be seen more',
              style: TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyTripsCard() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to trips purchase
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flight_takeoff,
                color: Color(0xFF4CAF50),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Buy Trips',
              style: TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add more trips',
              style: TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Phone Number
          _buildEditableField(
            icon: Icons.phone,
            label: 'Phone Number',
            controller: _phoneController,
            isEditing: _isEditingPhone,
            onEditTap: () {
              setState(() {
                _isEditingPhone = !_isEditingPhone;
                if (!_isEditingPhone) {
                  // Save phone number
                  _savePhoneNumber();
                }
              });
            },
            keyboardType: TextInputType.phone,
          ),
          const Divider(height: 1, indent: 56),
          // Email
          _buildEditableField(
            icon: Icons.email_outlined,
            label: 'Email',
            controller: _emailController,
            isEditing: _isEditingEmail,
            onEditTap: () {
              setState(() {
                _isEditingEmail = !_isEditingEmail;
                if (!_isEditingEmail) {
                  // Save email
                  _saveEmail();
                }
              });
            },
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditTap,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2E55C6), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Mona Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 4),
                isEditing
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        style: const TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        autofocus: true,
                      )
                    : Text(
                        controller.text.isEmpty ? 'Not set' : controller.text,
                        style: TextStyle(
                          fontFamily: 'Mona Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: controller.text.isEmpty
                              ? const Color(0xFF999999)
                              : const Color(0xFF333333),
                        ),
                      ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEditTap,
            child: Text(
              isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E55C6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E55C6), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF999999),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPrivacyItem(
            title: 'Cookie Policy',
            onTap: () {
              // TODO: Navigate to cookie policy
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildPrivacyItem(
            title: 'Privacy Policy',
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildPrivacyItem(
            title: 'Privacy Preferences',
            onTap: () {
              // TODO: Navigate to privacy preferences
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF999999),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPrivacyItem(
            title: 'Licenses',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Voyagr',
                applicationVersion: _appVersion,
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildPrivacyItem(
            title: 'Terms of Service',
            onTap: () {
              // TODO: Navigate to terms of service
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () => _showLogoutDialog(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE53935),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Text(
            'Log Out',
            style: TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE53935),
            ),
          ),
        ),
      ),
    );
  }

  void _showManagePaymentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 48,
                      color: Color(0xFF2E55C6),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Manage Payment',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Payment methods will be managed through the App Store.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showContactUsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.mail_outline,
                      size: 48,
                      color: Color(0xFF2E55C6),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Have questions or feedback? We\'d love to hear from you!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Mona Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E55C6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'support@voyagr.app',
                          style: TextStyle(
                            fontFamily: 'Mona Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                Navigator.pop(context);
                await SupabaseConfig.auth.signOut();
                navigator.pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Account',
            style: TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE53935),
            ),
          ),
          content: const Text(
            'This action cannot be undone. All your data, matches, and conversations will be permanently deleted.',
            style: TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement account deletion
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion request submitted.'),
                    backgroundColor: Color(0xFFE53935),
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'Mona Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePhoneNumber() async {
    // TODO: Implement saving phone number to Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number updated'),
        backgroundColor: Color(0xFF2E55C6),
      ),
    );
  }

  Future<void> _saveEmail() async {
    // TODO: Implement saving email to Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email updated'),
        backgroundColor: Color(0xFF2E55C6),
      ),
    );
  }
}
