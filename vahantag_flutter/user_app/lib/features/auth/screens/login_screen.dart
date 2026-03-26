import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 10-digit Indian mobile number'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _loading = true);
    final success = await context.read<AuthProvider>().sendOTP(phone);
    setState(() => _loading = false);
    if (success && mounted) {
      context.push('/otp', extra: {'phone': phone});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Failed to send OTP'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Column(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                    child: const Center(child: Text('🏷️', style: TextStyle(fontSize: 48))),
                  ),
                  const SizedBox(height: 16),
                  const Text('VahanTag', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Your asset\'s digital safety shield', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                ],
              ),
              const SizedBox(height: 48),
              // Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sign In / Register', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Enter your mobile number to continue', style: TextStyle(fontSize: 13, color: AppColors.grey)),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(border: Border(right: BorderSide(color: AppColors.border, width: 1.5))),
                            child: const Text('+91', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: const TextStyle(fontSize: 18, color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                border: InputBorder.none, hintText: '9876543210',
                                hintStyle: TextStyle(color: AppColors.textHint),
                                counterText: '', contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onSubmitted: (_) => _sendOTP(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Get OTP', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(child: Text('A 6-digit OTP will be sent to verify your number', style: TextStyle(fontSize: 12, color: AppColors.grey))),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('By continuing, you agree to our Terms & Privacy Policy', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
            ],
          ),
        ),
      ),
    );
  }
}
