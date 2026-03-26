import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService().getDashboard();
      setState(() { _stats = r.data['data'] as Map<String, dynamic>?; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: RefreshIndicator(
        color: const Color(0xFFFF6B00),
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF1E293B),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20, right: 20, bottom: 24,
              ),
              child: Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Admin Panel ⚙️', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Full system control', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ])),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFFF4444)),
                  onPressed: () async {
                    await context.read<AdminAuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ]),
            ),
          ),

          // ── Error banner ─────────────────────────────────────────────
          if (_error != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF7F1D1D), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFCA5A5)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Could not load stats: $_error', style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12))),
                  TextButton(onPressed: _load, child: const Text('Retry', style: TextStyle(color: Color(0xFFFF6B00)))),
                ]),
              ),
            ),

          // ── Stats grid ───────────────────────────────────────────────
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
              ),
            )
          else if (_stats != null)
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.9,
                ),
                delegate: SliverChildListDelegate([
                  _stat('${_stats!['totalUsers'] ?? 0}',        'Users',       '👥', const Color(0xFF2196F3)),
                  _stat('${_stats!['approvedAgents'] ?? 0}',    'Agents',      '🏢', const Color(0xFF9C27B0)),
                  _stat('${_stats!['activeTags'] ?? 0}',        'Active Tags', '🏷️', const Color(0xFF4CAF50)),
                  _stat('${_stats!['activeSubscriptions'] ?? 0}','Active Subs','🛡️', const Color(0xFFFF6B00)),
                  _stat('${_stats!['scansLast30Days'] ?? 0}',   'Scans 30d',   '📱', const Color(0xFF00BCD4)),
                  _stat('₹${((_stats!['revenueLast30Days'] as num?) ?? 0) ~/ 100}', 'Revenue 30d', '💰', const Color(0xFFFF6B00)),
                ]),
              ),
            ),

          // ── Management section label ─────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Text('Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),

          // ── Management grid ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate([
                _menu('👥',  'Users',      () => context.push('/users')),
                _menu('🏢',  'Agents',     () => context.push('/agents')),
                _menu('🏷️', 'QR Tags',    () => context.push('/tags')),
                _menu('💰',  'Categories', () => context.push('/categories')),
                _menu('📊',  'Revenue',    () => context.push('/revenue')),
                _menu('⚡',  'Gen Tags',   () => context.push('/generate-tags')),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
      ),
    );
  }

  Widget _stat(String val, String lbl, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(lbl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
      ]),
    );
  }

  Widget _menu(String emoji, String lbl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text(lbl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0))),
        ]),
      ),
    );
  }
}
