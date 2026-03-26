import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/shared_widgets.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List _tags = [];
  bool _loading = true;
  bool _generating = false;
  String? _error;

  final _countCtrl = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD TAGS =================
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final r = await ApiService().getTags();

      final data = r.data;

      setState(() {
        _tags = (data['data'] ?? []) as List;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ================= GENERATE TAGS (FIXED) =================
  Future<void> _generate() async {
    final count = int.tryParse(_countCtrl.text.trim());

    if (count == null || count < 1 || count > 1000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a count between 1 and 1000'),
          ),
        );
      }
      return;
    }

    setState(() => _generating = true);

    try {
      // 🔥 FIX: ApiService already returns List<String>
      final codes = await ApiService().generateTags(count);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Generated ${codes.length} Tags ✅',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SizedBox(
              height: 240,
              child: ListView(
                children: codes.take(20).map((c) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      c,
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontFamily: 'monospace',
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Color(0xFFFF6B00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );

        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  // ================= UI COLORS =================
  static const _statusColors = {
    'active': [Color(0xFF14532D), Color(0xFF4ADE80)],
    'unactivated': [Color(0xFF1E3A5F), Color(0xFF93C5FD)],
    'expired': [Color(0xFF7F1D1D), Color(0xFFFCA5A5)],
    'assigned': [Color(0xFF3D1F00), Color(0xFFFB923C)],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Color(0xFFFF6B00)),
        elevation: 0,
        title: Text(
          'QR Tags${_tags.isNotEmpty ? " (${_tags.length})" : ""}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 55,
                  child: TextField(
                    controller: _countCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '10',
                      hintStyle: TextStyle(color: Color(0xFF475569)),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _generating ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '⚡ Gen',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ================= BODY =================
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B00),
              ),
            )
          : _error != null
              ? ErrorView(error: _error!, onRetry: _load)
              : _tags.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏷️', style: TextStyle(fontSize: 52)),
                          const SizedBox(height: 12),
                          const Text(
                            'No tags yet. Generate some!',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _generating ? null : _generate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B00),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 12),
                            ),
                            child: const Text(
                              '⚡ Generate Tags',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFFF6B00),
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _tags.length,
                        itemBuilder: (_, i) {
                          final t = _tags[i];

                          final sc = _statusColors[t['status']] ??
                              [const Color(0xFF334155), const Color(0xFF94A3B8)];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF334155),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t['tag_code']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      if (t['owner_name'] != null)
                                        Text(
                                          t['owner_name'].toString(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      if (t['agent_name'] != null)
                                        Text(
                                          'Agent: ${t['agent_name']}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: sc[0],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    t['status']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: sc[1],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}