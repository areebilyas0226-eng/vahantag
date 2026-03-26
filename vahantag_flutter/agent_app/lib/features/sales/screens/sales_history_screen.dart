import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});
  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<dynamic> _sales = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await ApiService().getSalesHistory(); setState(() { _sales = r.data['data'] ?? []; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: const Color(0xFF1E293B), title: const Text('Sales History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : _sales.isEmpty ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('📊', style: TextStyle(fontSize: 56)), SizedBox(height: 12), Text('No sales yet', style: TextStyle(color: Color(0xFF64748B), fontSize: 15))]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sales.length,
              itemBuilder: (_, i) {
                final s = _sales[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
                  child: Row(children: [
                    const CircleAvatar(radius: 20, backgroundColor: Color(0xFF14532D), child: Text('✅', style: TextStyle(fontSize: 16))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['tag_code'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                      Text('${s['customer_name'] ?? 'Customer'} · +91${s['customer_phone'] ?? ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ])),
                    Text(s['sold_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ]),
                );
              }),
    );
  }
}
