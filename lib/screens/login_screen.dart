import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  String _errorMessage = '';
  bool _isChecking = false;
  Timer? _lockoutTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _checkLockoutStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLockedOut) {
      _secondsRemaining = authProvider.lockoutSecondsRemaining;
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLockedOut) {
        setState(() {
          _secondsRemaining = authProvider.lockoutSecondsRemaining;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _errorMessage = '';
        });
      }
    });
  }

  Future<void> _handleNumPress(String val) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLockedOut) {
      _checkLockoutStatus();
      return;
    }

    if (_pin.length >= 6) return;

    setState(() {
      _pin += val;
      _errorMessage = '';
    });

    // Auto check if it reaches 6 (max pin size)
    if (_pin.length == 6) {
      await _submitPin();
    }
  }

  void _handleBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = '';
    });
  }

  void _handleClear() {
    setState(() {
      _pin = '';
      _errorMessage = '';
    });
  }

  Future<void> _submitPin() async {
    if (_pin.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    setState(() => _isChecking = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyPin(_pin);
    setState(() => _isChecking = false);

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      _handleClear();
      if (authProvider.isLockedOut) {
        _secondsRemaining = authProvider.lockoutSecondsRemaining;
        _startLockoutTimer();
        setState(() {
          _errorMessage = 'Too many failed attempts. Temporary lockout.';
        });
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. ${5 - authProvider.failedAttempts} attempts remaining.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLocked = authProvider.isLockedOut;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 96,
                      width: 96,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Title & Shop Name
                  Text(
                    authProvider.shopName.isNotEmpty ? authProvider.shopName : 'Pharm',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pharmacy Management System',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // PIN Display dots
                  _buildPinIndicators(isDark),
                  const SizedBox(height: 24),

                  // Error / Lockout Message
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        isLocked
                            ? 'App locked. Try again in $_secondsRemaining seconds.'
                            : _errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isLocked || _errorMessage.contains('Incorrect') || _errorMessage.contains('at least')
                              ? Colors.redAccent
                              : const Color(0xFF0D9488),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Custom Numeric Keyboard
                  _buildKeyboard(isDark, isLocked),
                  const SizedBox(height: 36),

                  // Forgot PIN link
                  TextButton(
                    onPressed: () {
                      _handleClear();
                      Navigator.of(context).pushNamed('/pin-recovery');
                    },
                    child: Text(
                      'Forgot PIN?',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0D9488),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
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

  Widget _buildPinIndicators(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final hasVal = index < _pin.length;
        return Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasVal
                  ? const Color(0xFF0D9488)
                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              width: 2,
            ),
            color: hasVal
                ? const Color(0xFF0D9488)
                : Colors.transparent,
          ),
        );
      }),
    );
  }

  Widget _buildKeyboard(bool isDark, bool isLocked) {
    return Column(
      children: [
        _buildKeyboardRow(['1', '2', '3'], isDark, isLocked),
        const SizedBox(height: 16),
        _buildKeyboardRow(['4', '5', '6'], isDark, isLocked),
        const SizedBox(height: 16),
        _buildKeyboardRow(['7', '8', '9'], isDark, isLocked),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeyboardButton('C', isDark, isLocked, onTap: _handleClear),
            const SizedBox(width: 24),
            _buildKeyboardButton('0', isDark, isLocked, onTap: () => _handleNumPress('0')),
            const SizedBox(width: 24),
            _buildKeyboardButton('⌫', isDark, isLocked, onTap: _handleBackspace),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyboardRow(List<String> values, bool isDark, bool isLocked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: values.map((val) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildKeyboardButton(val, isDark, isLocked, onTap: () => _handleNumPress(val)),
        );
      }).toList(),
    );
  }

  Widget _buildKeyboardButton(String val, bool isDark, bool isLocked, {required VoidCallback onTap}) {
    final isAction = val == 'C' || val == '⌫';
    final buttonColor = isDark
        ? (isAction ? const Color(0xFF1E293B) : const Color(0xFF334155))
        : (isAction ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9));

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return InkWell(
      onTap: (isLocked || _isChecking) ? null : onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: buttonColor,
        ),
        child: Center(
          child: Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: val == '⌫' ? 20 : 26,
              fontWeight: FontWeight.bold,
              color: (isLocked || _isChecking)
                  ? textColor.withOpacity(0.3)
                  : (val == 'C' ? Colors.redAccent : textColor),
            ),
          ),
        ),
      ),
    );
  }
}
