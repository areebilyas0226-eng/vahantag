import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final r = await ApiService().getInventory(); setState(() { _items = r.data['data'] ?? []; _loading = false; }); }
    catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: const Color(0xFF1E293B), title: const Text('My Inventory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), iconTheme: const IconThemeData(color: Color(0xFFFF6B00)), elevation: 0),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))) :
        _items.isEmpty ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('📦', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('No tags assigned yet. Contact admin.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15))]))
        : RefreshIndicator(color: const Color(0xFFFF6B00), onRefresh: _load, child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final item = _items[i];
            final sold = item['status'] == 'sold';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
              child: Row(children: [
                Text(item['tag_code'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: sold ? const Color(0xFF1E3A5F) : const Color(0xFF14532D), borderRadius: BorderRadius.circular(20)),
                  child: Text(sold ? 'Sold' : 'In Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sold ? const Color(0xFF93C5FD) : const Color(0xFF4ADE80)))),
              ]),
            );
          },
        )),
    );
  }
}
