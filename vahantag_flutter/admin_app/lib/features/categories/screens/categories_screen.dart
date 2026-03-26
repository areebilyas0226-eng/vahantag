import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/shared_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List _cats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService().getCategories();
      setState(() { _cats = (r.data['data'] ?? []) as List; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _editPrice(dynamic cat) {
    final ctrl = TextEditingController(
        text: '${((cat['yearly_price_paisa'] as num?) ?? 0) ~/ 100}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit ${cat['name']} Price',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Yearly price (₹)',
            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixText: '₹ ',
            prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim());
              if (val == null || val < 1) return;
              try {
                await ApiService().updateCategory(cat['id'].toString(), {'yearly_price_paisa': val * 100});
                if (mounted) {
                  Navigator.pop(context);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${cat['name']} updated to ₹$val/year ✅'),
                      backgroundColor: const Color(0xFF4CAF50)));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Color(0xFFFF6B00)),
        elevation: 0,
        title: const Text('Categories & Pricing',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : _error != null ? ErrorView(error: _error!, onRetry: _load)
          : _cats.isEmpty ? const EmptyView(emoji: '📦', label: 'No categories found')
          : RefreshIndicator(
              color: const Color(0xFFFF6B00),
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _cats.length,
                itemBuilder: (_, i) {
                  final c = _cats[i];
                  final price = ((c['yearly_price_paisa'] as num?) ?? 0) ~/ 100;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF334155))),
                    child: Row(children: [
                      Text(c['icon']?.toString() ?? '📦', style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['name']?.toString() ?? '',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('${c['total_assets'] ?? 0} assets registered',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('₹$price/yr',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFF6B00))),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _editPrice(c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Edit Price',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ]),
                    ]),
                  );
                },
              ),
            ),
    );
  }
}
