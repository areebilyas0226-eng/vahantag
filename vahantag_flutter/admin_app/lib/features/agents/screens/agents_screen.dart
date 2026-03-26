import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/shared_widgets.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});
  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  List _agents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService().getAgents();
      setState(() { _agents = (r.data['data'] ?? []) as List; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _approve(dynamic agent) async {
    try {
      await ApiService().approveAgent(agent['id'].toString());
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${agent['name']} approved ✅'), backgroundColor: const Color(0xFF4CAF50)));
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
        title: Text('Agents${_agents.isNotEmpty ? " (${_agents.length})" : ""}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : _error != null ? ErrorView(error: _error!, onRetry: _load)
          : _agents.isEmpty ? const EmptyView(emoji: '🏢', label: 'No agents yet')
          : RefreshIndicator(
              color: const Color(0xFFFF6B00),
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _agents.length,
                itemBuilder: (_, i) {
                  final a = _agents[i];
                  final approved = a['is_approved'] == true;
                  final name = a['name']?.toString() ?? 'Agent';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF334155))),
                    child: Column(children: [
                      Row(children: [
                        CircleAvatar(radius: 22, backgroundColor: const Color(0xFFFF6B00),
                            child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('+91 ${a['phone'] ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          if (a['city'] != null)
                            Text('${a['city']}, ${a['state'] ?? ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text('Tags: ${a['total_tags'] ?? 0}  ·  Sold: ${a['sold_tags'] ?? 0}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: approved ? const Color(0xFF14532D) : const Color(0xFF3D1F00),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(approved ? 'Approved' : 'Pending',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                  color: approved ? const Color(0xFF4ADE80) : const Color(0xFFFB923C))),
                        ),
                      ]),
                      if (!approved) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _approve(a),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14532D),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: const Text('✅ Approve Agent',
                                style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ]),
                  );
                },
              ),
            ),
    );
  }
}
