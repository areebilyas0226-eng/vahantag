import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/shared_widgets.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService().getUsers();
      setState(() { _users = (r.data['data'] ?? []) as List; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _toggle(dynamic user) async {
    try {
      await ApiService().toggleUser(user['id'].toString());
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Color(0xFFFF6B00)),
        elevation: 0,
        title: Text('Users${_users.isNotEmpty ? " (${_users.length})" : ""}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : _error != null ? ErrorView(error: _error!, onRetry: _load)
          : _users.isEmpty ? const EmptyView(emoji: '👥', label: 'No users yet')
          : RefreshIndicator(
              color: const Color(0xFFFF6B00),
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final name = u['name']?.toString() ?? 'No name';
                  final isActive = u['is_active'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
                    child: Row(children: [
                      CircleAvatar(radius: 22, backgroundColor: const Color(0xFFFF6B00),
                          child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('+91 ${u['phone'] ?? ''}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        Text('${u['asset_count'] ?? 0} assets  ·  ${u['active_subs'] ?? 0} subs',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      ])),
                      Column(children: [
                        Switch(value: isActive, activeColor: const Color(0xFF4ADE80), onChanged: (_) => _toggle(u)),
                        Text(isActive ? 'Active' : 'Blocked',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: isActive ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5))),
                      ]),
                    ]),
                  );
                },
              ),
            ),
    );
  }
}
