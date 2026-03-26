import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  bool _showOTP = false;
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _snack('Enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<AdminAuthProvider>().sendOTP(phone);
    setState(() => _loading = false);
    if (ok) {
      setState(() => _showOTP = true);
    } else {
      _snack('No admin account found for this number');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() => _loading = true);
    final ok = await context.read<AdminAuthProvider>().verifyOTP(
      _phoneCtrl.text.trim(),
      _otpCtrl.text,
    );
    setState(() => _loading = false);
    if (ok && mounted) {
      context.go('/dashboard');
    } else {
      _snack('Invalid OTP. Please try again.');
      _otpCtrl.clear();
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF4444)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinTheme = PinTheme(
      width: 50, height: 58,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1E293B),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              const Text('⚙️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text(
                'VahanTag Admin',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFFF6B00)),
              ),
              const Text(
                'Full System Control Panel',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(children: [
                  Text(
                    _showOTP ? 'Enter OTP' : 'Admin Login',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  if (!_showOTP) ...[
                    // Phone input
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF334155), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF0F172A),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          child: const Text('+91', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Admin mobile number',
                              hintStyle: TextStyle(color: Color(0xFF475569)),
                              counterText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ] else ...[
                    // OTP input
                    Text(
                      'OTP sent to +91 ${_phoneCtrl.text}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Pinput(
                        controller: _otpCtrl,
                        length: 6,
                        defaultPinTheme: pinTheme,
                        focusedPinTheme: pinTheme.copyWith(
                          decoration: pinTheme.decoration!.copyWith(
                            border: Border.all(color: const Color(0xFFFF6B00), width: 1.5),
                          ),
                        ),
                        onCompleted: (_) => _verifyOTP(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() { _showOTP = false; _otpCtrl.clear(); }),
                      child: const Text('Change number', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : (_showOTP ? _verifyOTP : _sendOTP),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          : Text(
                              _showOTP ? 'Login as Admin' : 'Get OTP',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
