import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PinRecoveryScreen extends StatefulWidget {
  const PinRecoveryScreen({super.key});

  @override
  State<PinRecoveryScreen> createState() => _PinRecoveryScreenState();
}

class _PinRecoveryScreenState extends State<PinRecoveryScreen> {
  final _formKeyQuestions = GlobalKey<FormState>();
  final _formKeyNewPin = GlobalKey<FormState>();

  final _a1Controller = TextEditingController();
  final _a2Controller = TextEditingController();

  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isVerified = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isSaving = false;
  String _errorMsg = '';

  @override
  void dispose() {
    _a1Controller.dispose();
    _a2Controller.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _verifyAnswers() async {
    if (!_formKeyQuestions.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMsg = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isMatched = await authProvider.verifySecurityQuestions(
      _a1Controller.text.trim(),
      _a2Controller.text.trim(),
    );

    setState(() => _isSaving = false);

    if (isMatched) {
      setState(() {
        _isVerified = true;
      });
    } else {
      setState(() {
        _errorMsg = 'Incorrect answers. Please try again.';
      });
    }
  }

  Future<void> _resetPin() async {
    if (!_formKeyNewPin.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPin(_newPinController.text.trim());

    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN successfully reset. Use your new PIN to login.'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      setState(() {
        _errorMsg = 'Failed to reset PIN. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'PIN Recovery',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isVerified ? Icons.lock_open_rounded : Icons.verified_user_rounded,
                          color: const Color(0xFF0D9488),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isVerified ? 'Create New PIN' : 'Security Verification',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isVerified
                        ? 'Enter a new 4 to 6 digit security PIN.'
                        : 'Answer your offline security questions to unlock access.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMsg.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMsg,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isVerified
                        ? _buildNewPinForm(isDark)
                        : _buildQuestionsForm(authProvider, isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsForm(AuthProvider authProvider, bool isDark) {
    return Form(
      key: _formKeyQuestions,
      child: Column(
        key: const ValueKey('questionsForm'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            authProvider.question1,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _a1Controller,
            label: 'Your Answer',
            hint: 'Enter your answer here',
            icon: Icons.question_answer_rounded,
            isDark: isDark,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Answer is required' : null,
          ),
          const SizedBox(height: 24),

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
            authProvider.question2,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _a2Controller,
            label: 'Your Answer',
            hint: 'Enter your answer here',
            icon: Icons.question_answer_rounded,
            isDark: isDark,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Answer is required' : null,
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSaving ? null : _verifyAnswers,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Verify Answers',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPinForm(bool isDark) {
    return Form(
      key: _formKeyNewPin,
      child: Column(
        key: const ValueKey('newPinForm'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _newPinController,
            label: 'New Security PIN *',
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
            hint: 'Re-enter your new PIN',
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
              if (val != _newPinController.text) return 'PINs do not match';
              return null;
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSaving ? null : _resetPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Reset PIN & Login',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
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
