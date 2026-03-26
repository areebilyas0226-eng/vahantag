import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});
  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  Map<String, dynamic>? _profile;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await ApiService().getProfile(); setState(() => _profile = r.data['data']); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<AgentAuthProvider>().agent;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: RefreshIndicator(color: const Color(0xFFFF6B00), onRefresh: _load, child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          color: const Color(0xFF1E293B),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 24),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hello, ${_profile?['name'] ?? agent?['name'] ?? 'Agent'} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const Text('VahanTag Agent Dashboard', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _profile?['is_approved'] == true ? const Color(0xFF14532D) : const Color(0xFF3D1F00), borderRadius: BorderRadius.circular(20)),
              child: Text(_profile?['is_approved'] == true ? '✅ Approved' : '⏳ Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _profile?['is_approved'] == true ? const Color(0xFF4ADE80) : const Color(0xFFFB923C)))),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          _stat('${_profile?['total_tags'] ?? 0}', 'Total Tags', '🏷️'),
          const SizedBox(width: 10),
          _stat('${_profile?['sold_tags'] ?? 0}', 'Sold', '✅'),
          const SizedBox(width: 10),
          _stat('${_profile?['in_stock'] ?? 0}', 'In Stock', '📦'),
        ]))),
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16,8,16,10), child: Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)))),
        SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 12), sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4),
          delegate: SliverChildListDelegate([
            _action('📦', 'Record Sale', const Color(0xFF14532D), () => context.push('/record-sale')),
            _action('📋', 'My Inventory', const Color(0xFF1E3A5F), () => context.push('/inventory')),
            _action('📊', 'Sales History', const Color(0xFF3B0764), () => context.push('/sales-history')),
            _action('👤', 'My Profile', const Color(0xFF3D1F00), () => context.push('/profile')),
          ]),
        )),
        SliverToBoxAdapter(child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF334155))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📋 How Agent Sales Work', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            ...['Admin assigns QR stickers to your inventory', 'Sell stickers to customers physically', 'Record sale here with customer mobile number', 'Customer activates sticker in VahanTag user app'].map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $s', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4)),
            )),
          ]),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ])),
    );
  }

  Widget _stat(String val, String lbl, String emoji) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF334155))),
    child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 22)), const SizedBox(height: 6), Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFF6B00))), Text(lbl, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]),
  ));

  Widget _action(String emoji, String lbl, Color bg, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF334155))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22)))),
        const SizedBox(height: 10),
        Text(lbl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    ),
  );
}
