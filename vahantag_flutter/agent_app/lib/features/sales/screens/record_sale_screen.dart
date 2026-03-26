import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';

class RecordSaleScreen extends StatefulWidget {
  const RecordSaleScreen({super.key});
  @override
  State<RecordSaleScreen> createState() => _RecordSaleScreenState();
}

class _RecordSaleScreenState extends State<RecordSaleScreen> {
  final _tagCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _record() async {
    final tag = _tagCtrl.text.trim().toUpperCase();
    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^VT-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(tag)) { _snack('Invalid tag format: VT-XXXX-XXXX'); return; }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) { _snack('Enter valid 10-digit customer mobile'); return; }
    setState(() => _loading = true);
    try {
      await ApiService().recordSale({'tag_code': tag, 'customer_phone': phone, 'customer_name': _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null});
      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Sale Recorded! ✅', style: TextStyle(color: Colors.white)),
          content: Text('Customer +91$phone can now activate tag $tag in VahanTag app.', style: const TextStyle(color: Color(0xFF94A3B8))),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); _tagCtrl.clear(); _phoneCtrl.clear(); _nameCtrl.clear(); }, child: const Text('Record Another', style: TextStyle(color: Color(0xFFFF6B00)))),
            TextButton(onPressed: () { Navigator.pop(context); context.pop(); }, child: const Text('Done', style: TextStyle(color: Color(0xFFFF6B00)))),
          ],
        ));
      }
    } catch (e) { _snack('Error: Tag not in your inventory or already sold'); }
    setState(() => _loading = false);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF4444)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: const Color(0xFF1E293B), title: const Text('Record Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), iconTheme: const IconThemeData(color: Color(0xFFFF6B00)), elevation: 0),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF3D1F00), borderRadius: BorderRadius.circular(14), border: Border(left: BorderSide(color: const Color(0xFFFF6B00), width: 4))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Record a Tag Sale', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFF6B00))),
            SizedBox(height: 6),
            Text('Enter the tag code from the sticker and customer mobile number', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5)),
          ]),
        ),
        const SizedBox(height: 24),
        _label('Tag Code (from sticker)'),
        const SizedBox(height: 8),
        _input(_tagCtrl, 'VT-XXXX-XXXX', maxLength: 12, cap: TextCapitalization.characters, monospace: true),
        const SizedBox(height: 20),
        _label('Customer Mobile Number'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFF334155), width: 1.5), borderRadius: BorderRadius.circular(12), color: const Color(0xFF1E293B)),
          child: Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), child: const Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
            const VerticalDivider(color: Color(0xFF334155), width: 1),
            Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Customer mobile', hintStyle: TextStyle(color: Color(0xFF475569)), counterText: '', contentPadding: EdgeInsets.symmetric(horizontal: 16)))),
          ]),
        ),
        const SizedBox(height: 20),
        _label('Customer Name (Optional)'),
        const SizedBox(height: 8),
        _input(_nameCtrl, 'Customer full name'),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
          onPressed: _loading ? null : _record,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), disabledBackgroundColor: const Color(0xFFFF6B00).withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5) : const Text('Record Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        )),
      ])),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600));

  Widget _input(TextEditingController ctrl, String hint, {int? maxLength, TextCapitalization cap = TextCapitalization.none, bool monospace = false}) =>
    TextField(controller: ctrl, maxLength: maxLength, textCapitalization: cap, style: TextStyle(color: Colors.white, fontSize: monospace ? 20 : 15, fontWeight: monospace ? FontWeight.w700 : FontWeight.normal, letterSpacing: monospace ? 2 : 0),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF475569)), counterText: '', filled: true, fillColor: const Color(0xFF1E293B), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF334155), width: 1.5)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF334155), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFFF6B00), width: 1.5))));
}
