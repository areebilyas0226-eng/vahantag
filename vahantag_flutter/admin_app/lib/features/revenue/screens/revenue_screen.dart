import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/shared_widgets.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});
  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService().getRevenue();
      setState(() { _data = (r.data['data'] ?? []) as List; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  int get _total => _data.fold(0, (s, r) => s + ((r['total'] as num?) ?? 0).toInt());

  String _formatMonth(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString());
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.year}';
    } catch (_) { return raw.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Color(0xFFFF6B00)),
        elevation: 0,
        title: const Text('Revenue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : _error != null ? ErrorView(error: _error!, onRetry: _load)
          : RefreshIndicator(
              color: const Color(0xFFFF6B00),
              onRefresh: _load,
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  color: const Color(0xFFFF6B00),
                  child: Column(children: [
                    const Text('Total Revenue (All Time)',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('₹${_total ~/ 100}',
                        style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                  ]),
                ),
                Expanded(
                  child: _data.isEmpty
                      ? const EmptyView(emoji: '📊', label: 'No revenue data yet')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final r = _data[i];
                            final amount = ((r['total'] as num?) ?? 0).toInt() ~/ 100;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF334155))),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(_formatMonth(r['month']),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                  Text('${r['transactions'] ?? 0} transactions',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ])),
                                Text('₹$amount',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFF6B00))),
                              ]),
                            );
                          },
                        ),
                ),
              ]),
            ),
    );
  }
}
