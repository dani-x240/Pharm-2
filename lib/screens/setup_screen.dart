import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _currentStep = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Step 1 Controllers
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2 Controllers
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  // Step 3 Controllers
  final _q1Controller = TextEditingController(text: 'What is your favourite colour?');
  final _a1Controller = TextEditingController();
  final _q2Controller = TextEditingController(text: 'What was the name of your first school?');
  final _a2Controller = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isSaving = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _q1Controller.dispose();
    _a1Controller.dispose();
    _q2Controller.dispose();
    _a2Controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey1.currentState!.validate()) {
        if (!_agreedToTerms) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must agree to the Terms and Conditions to proceed.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 1) {
      if (_formKey2.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey3.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.setupApp(
      shopName: _shopNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      shopAddress: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      pin: _pinController.text.trim(),
      q1: _q1Controller.text.trim(),
      a1: _a1Controller.text.trim(),
      q2: _q2Controller.text.trim(),
      a2: _a2Controller.text.trim(),
    );

    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings. Please try again.'),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo_32.png',
                          height: 32,
                          width: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pharm',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress Indicators
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index == _currentStep;
                      final isPassed = index < _currentStep;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isPassed
                                ? const Color(0xFF0D9488)
                                : (isActive
                                    ? const Color(0xFF0D9488).withOpacity(0.5)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Title and Subtitle
                  Text(
                    _getStepTitle(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStepSubtitle(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Step Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStepContent(isDark),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _prevStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Back',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : (_currentStep == 2 ? _completeSetup : _nextStep),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentStep == 2 ? 'Finish Setup' : 'Continue',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      children: [
                        const TextSpan(text: 'Created & Copyrighted by '),
                        TextSpan(
                          text: 'https://www.altrastate.com/',
                          style: const TextStyle(
                            color: Color(0xFF0D9488),
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              try {
                                await launchUrl(
                                  Uri.parse('https://www.altrastate.com/contact'),
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (_) {}
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Drug Shop Registration';
      case 1:
        return 'Create Security PIN';
      case 2:
        return 'Setup Recovery Questions';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter basic details about your shop to get started.';
      case 1:
        return 'Used to secure and access your dashboard offline.';
      case 2:
        return 'Used to reset your PIN if you forget it. Stored 100% offline.';
      default:
        return '';
    }
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _formKey1,
          child: Column(
            key: const ValueKey('step1'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _shopNameController,
                label: 'Drug Shop Name *',
                hint: 'e.g., James Drug Shop',
                icon: Icons.store_rounded,
                isDark: isDark,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Shop name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ownerNameController,
                label: 'Owner Name *',
                hint: 'e.g., James John',
                icon: Icons.person_rounded,
                isDark: isDark,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Owner name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Shop Address (Optional)',
                hint: 'e.g., Jinja Main Street, Plot 4',
                icon: Icons.location_on_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number (Optional)',
                hint: 'e.g., +256 700 000000',
                icon: Icons.phone_rounded,
                isDark: isDark,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: const Color(0xFF0D9488),
                      onChanged: (val) {
                        setState(() => _agreedToTerms = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I agree to the terms and conditions: this app will only be shared to the stated owner name as agreed by the builder.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKey2,
          child: Column(
            key: const ValueKey('step2'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _pinController,
                label: 'Security PIN *',
                hint: '4 to 6 digit security PIN',
                icon: Icons.lock_rounded,
                isDark: isDark,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                suffix: IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'PIN is required';
                  if (val.length < 4 || val.length > 6) return 'PIN must be 4 to 6 digits';
                  if (int.tryParse(val) == null) return 'PIN must contain digits only';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _confirmPinController,
                label: 'Confirm PIN *',
                hint: 'Re-enter your security PIN',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                obscureText: _obscureConfirmPin,
                keyboardType: TextInputType.number,
                suffix: IconButton(
                  icon: Icon(_obscureConfirmPin ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                ),
                validator: (val) {
                  if (val != _pinController.text) return 'PINs do not match';
                  return null;
                },
              ),
            ],
          ),
        );
      case 2:
        return Form(
          key: _formKey3,
          child: Column(
            key: const ValueKey('step3'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Q1 Detail
              Text(
                'Question 1',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _q1Controller.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _a1Controller,
                label: 'Your Answer *',
                hint: 'e.g., Blue',
                icon: Icons.question_answer_rounded,
                isDark: isDark,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Answer is required' : null,
              ),
              const SizedBox(height: 24),

              // Q2 Detail
              Text(
                'Question 2',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _q2Controller.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _a2Controller,
                label: 'Your Answer *',
                hint: 'e.g., Jinja Primary',
                icon: Icons.question_answer_rounded,
                isDark: isDark,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Answer is required' : null,
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF0D9488)),
            suffixIcon: suffix,
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            errorStyle: GoogleFonts.inter(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}
