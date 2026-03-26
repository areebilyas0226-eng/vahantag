import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AgentLoginScreen extends StatefulWidget {
  const AgentLoginScreen({super.key});
  @override
  State<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends State<AgentLoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 60),
          const Text('🏢', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          const Text('VahanTag Agent', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFFFF6B00))),
          const Text('Sell QR Stickers & Earn', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF334155))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Agent Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF334155), width: 1.5), borderRadius: BorderRadius.circular(12), color: const Color(0xFF0F172A)),
                child: Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), child: const Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
                  const VerticalDivider(color: Color(0xFF334155), width: 1),
                  Expanded(child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: '10-digit mobile', hintStyle: TextStyle(color: Color(0xFF475569)), counterText: '', contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                  )),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                onPressed: _loading ? null : () async {
                  final p = _phoneCtrl.text.trim();
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(p)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid mobile number'))); return; }
                  setState(() => _loading = true);
                  final ok = await context.read<AgentAuthProvider>().sendOTP(p);
                  setState(() => _loading = false);
                  if (ok && mounted) context.push('/otp', extra: {'phone': p});
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5) : const Text('Get OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              )),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('New agent? Contact admin to register', style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
        ]),
      )),
    );
  }
}
