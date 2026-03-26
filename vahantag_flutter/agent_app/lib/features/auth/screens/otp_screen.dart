import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AgentOTPScreen extends StatefulWidget {
  final String phone;
  const AgentOTPScreen({super.key, required this.phone});
  @override
  State<AgentOTPScreen> createState() => _AgentOTPScreenState();
}

class _AgentOTPScreenState extends State<AgentOTPScreen> {
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() => _loading = true);
    final result = await context.read<AgentAuthProvider>().verifyOTP(widget.phone, _otpCtrl.text, name: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Agent');
    setState(() => _loading = false);
    if (!mounted) return;
    if (result == 'success') context.go('/dashboard');
    else if (result == 'pending') context.go('/pending');
    else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP'), backgroundColor: Color(0xFFFF4444))); _otpCtrl.clear(); }
  }

  @override
  Widget build(BuildContext context) {
    final pinTheme = PinTheme(width: 50, height: 58, textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF334155), width: 1.5), borderRadius: BorderRadius.circular(12), color: const Color(0xFF1E293B)));
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: const Color(0xFF0F172A), iconTheme: const IconThemeData(color: Color(0xFFFF6B00)), elevation: 0),
      body: Padding(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Verify OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        Text('Sent to +91 ${widget.phone}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        const SizedBox(height: 36),
        Center(child: Pinput(controller: _otpCtrl, length: 6, defaultPinTheme: pinTheme, focusedPinTheme: pinTheme.copyWith(decoration: pinTheme.decoration!.copyWith(border: Border.all(color: const Color(0xFFFF6B00), width: 1.5))), onCompleted: (_) => _verify())),
        const SizedBox(height: 20),
        const Text('Your Name', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(hintText: 'Enter your full name', hintStyle: const TextStyle(color: Color(0xFF475569)), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF334155), width: 1.5)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF334155), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFFF6B00), width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _loading ? null : _verify,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5) : const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        )),
      ])),
    );
  }
}
