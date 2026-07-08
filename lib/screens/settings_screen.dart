import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKeyDetails = GlobalKey<FormState>();
  final _formKeyPin = GlobalKey<FormState>();

  // Shop Details controllers
  late TextEditingController _shopNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  // PIN change controllers
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSavingDetails = false;
  bool _isSavingPin = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _shopNameController = TextEditingController(text: auth.shopName);
    _ownerNameController = TextEditingController(text: auth.ownerName);
    _addressController = TextEditingController(text: auth.shopAddress);
    _phoneController = TextEditingController(text: auth.phoneNumber);
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _saveShopDetails() async {
    if (!_formKeyDetails.currentState!.validate()) return;

    setState(() => _isSavingDetails = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateShopDetails(
      shopName: _shopNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      shopAddress: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );
    setState(() => _isSavingDetails = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Shop details updated!' : 'Failed to update details.'),
          backgroundColor: success ? const Color(0xFF0D9488) : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _changePin() async {
    if (!_formKeyPin.currentState!.validate()) return;

    setState(() => _isSavingPin = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // 1. Verify current PIN
    final verified = await auth.verifyPin(_currentPinController.text.trim());
    if (!verified) {
      setState(() => _isSavingPin = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect current PIN.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // 2. Save new PIN
    final success = await auth.resetPin(_newPinController.text.trim());
    setState(() => _isSavingPin = false);

    if (success) {
      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security PIN changed successfully!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update PIN.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Shop details Card
            Text(
              'Shop Information',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Form(
                key: _formKeyDetails,
                child: Column(
                  children: [
                    _buildTextField(_shopNameController, 'Drug Shop Name *', 'e.g., James Drug Shop', isDark, validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    _buildTextField(_ownerNameController, 'Owner Name *', 'e.g., James John', isDark, validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    _buildTextField(_addressController, 'Shop Address', 'e.g., Plot 10 Jinja', isDark),
                    const SizedBox(height: 12),
                    _buildTextField(_phoneController, 'Phone Number', 'e.g., +256...', isDark, keyboard: TextInputType.phone),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingDetails ? null : _saveShopDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSavingDetails
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Update Shop Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Section 2: Security Change PIN
            Text(
              'Security PIN Configuration',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Form(
                key: _formKeyPin,
                child: Column(
                  children: [
                    _buildTextField(
                      _currentPinController,
                      'Current security PIN *',
                      'Enter current PIN',
                      isDark,
                      obscure: _obscureCurrent,
                      keyboard: TextInputType.number,
                      suffix: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _newPinController,
                      'New security PIN *',
                      '4-6 digit PIN',
                      isDark,
                      obscure: _obscureNew,
                      keyboard: TextInputType.number,
                      suffix: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (val.length < 4 || val.length > 6) return 'PIN must be 4 to 6 digits';
                        if (int.tryParse(val) == null) return 'Must be digits only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _confirmPinController,
                      'Confirm new PIN *',
                      'Re-enter PIN',
                      isDark,
                      obscure: _obscureConfirm,
                      keyboard: TextInputType.number,
                      suffix: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (val) => val != _newPinController.text ? 'PINs do not match' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingPin ? null : _changePin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSavingPin
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Change Security PIN'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    bool isDark, {
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          validator: validator,
          style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
            suffixIcon: suffix,
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
