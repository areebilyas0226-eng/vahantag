import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';

class EmergencyPageScreen extends StatefulWidget {
  final String tagCode;
  const EmergencyPageScreen({super.key, required this.tagCode});
  @override
  State<EmergencyPageScreen> createState() => _EmergencyPageScreenState();
}

class _EmergencyPageScreenState extends State<EmergencyPageScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  final _callerController = TextEditingController();
  bool _calling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService().getEmergencyPage(widget.tagCode);
      setState(() { _data = res.data; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load emergency page'; _loading = false; });
    }
  }

  Future<void> _call() async {
    final phone = _callerController.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid 10-digit mobile number'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _calling = true);
    try {
      await ApiService().initiateCall(_data!['tagId'], phone);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📞 Calling +91$phone now! Please answer.'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call failed. Try WhatsApp instead.'), backgroundColor: AppColors.error));
    }
    setState(() => _calling = false);
  }

  Future<void> _whatsapp() async {
    try {
      final res = await ApiService().getWhatsAppLink(_data!['tagId']);
      final link = res.data['data']['whatsappLink'];
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _dialHelpline(String number) async {
    await launchUrl(Uri.parse('tel:$number'));
  }

  void _showCallModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📞 Masked Call', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('Enter YOUR mobile number. We call you and connect to the owner. Neither of you sees the other\'s real number.',
                style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.5)),
            const SizedBox(height: 20),
            TextField(
              controller: _callerController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Your 10-digit mobile',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _calling ? null : _call,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _calling ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5) : const Text('Call Me Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              )),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (_error != null || _data == null) return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('❌', style: TextStyle(fontSize: 56)), const SizedBox(height: 16), Text(_error ?? 'Page not found', style: const TextStyle(color: AppColors.grey))])));

    final pageType = _data!['pageType'];
    if (pageType == 'unactivated') return _simpleInfo('🏷️', 'Not Activated', 'This tag has not been activated by the owner yet.');
    if (pageType == 'deactivated') return _simpleInfo('🚫', 'Deactivated', 'This tag has been deactivated by the owner.');
    if (pageType == 'not_found') return _simpleInfo('❌', 'Tag Not Found', 'This QR code is not registered in VahanTag system.');

    final asset = _data!['assetInfo'] ?? {};
    final contacts = List<Map<String, dynamic>>.from(_data!['emergencyContacts'] ?? []);
    final helplines = Map<String, dynamic>.from(_data!['helplines'] ?? {});
    final subActive = _data!['contactAvailable'] == true;
    final medical = _data!['medicalInfo'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primary,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text('🏷️ VahanTag Emergency Page', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Emergency Contact', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('You scanned a VahanTag QR. Contact owner or get help below.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.4)),
                ],
              ),
            ),
          ),

          // Asset Card
          SliverToBoxAdapter(child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 12)]),
            child: Row(children: [
              Text(asset['categoryIcon'] ?? '📦', style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(asset['name'] ?? 'Unknown Asset', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text('${asset['category'] ?? ''} ${asset['registrationNumber'] != null ? '· ${asset['registrationNumber']}' : ''}', style: const TextStyle(fontSize: 13, color: AppColors.grey)),
                if (asset['make'] != null) Text('${asset['make']} ${asset['model'] ?? ''} ${asset['color'] != null ? '· ${asset['color']}' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                if (asset['ownerName'] != null) ...[const SizedBox(height: 4), Text('Owner: ${asset['ownerName']}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600))],
              ])),
            ]),
          )),

          // Medical Info
          if (medical != null && medical['bloodGroup'] != null)
            SliverToBoxAdapter(child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: AppColors.error, width: 4))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🩸 Emergency Medical Info', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC62828))),
                const SizedBox(height: 6),
                Text('Blood Group: ${medical['bloodGroup']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFC62828))),
                if (medical['medicalNotes'] != null) Text(medical['medicalNotes'], style: const TextStyle(fontSize: 13, color: AppColors.grey)),
              ]),
            )),

          // Expired
          if (!subActive)
            SliverToBoxAdapter(child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                const Text('⏰', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                const Text('Contact Unavailable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.warning)),
                const Text('Owner subscription expired. Asset info shown but contact is disabled.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.grey)),
              ]),
            )),

          // Contact Owner
          if (subActive) ...[
            SliverToBoxAdapter(child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.lock, size: 14, color: AppColors.success),
                const SizedBox(width: 8),
                const Expanded(child: Text('Owner privacy protected — real number never shown', style: TextStyle(fontSize: 12, color: AppColors.success))),
              ]),
            )),
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 8), child: Text('Contact Owner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
            SliverList(delegate: SliverChildListDelegate([
              _ContactBtn('📞', 'Masked Call', 'We connect you — numbers stay private', AppColors.successLight, _showCallModal),
              _ContactBtn('💬', 'WhatsApp', 'Send a message to owner via WhatsApp', AppColors.blueLight, _whatsapp),
            ])),

            if (contacts.isNotEmpty) ...[
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Emergency Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
              SliverList(delegate: SliverChildBuilderDelegate((_, i) {
                final c = contacts[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: c['is_primary'] == true ? AppColors.primary : AppColors.grey, radius: 22, child: Text((c['name'] ?? 'C')[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(c['relation'] ?? '', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                      Text(c['masked_phone'] ?? '', style: const TextStyle(fontSize: 13)),
                    ]),
                    if (c['is_primary'] == true) ...[const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)), child: const Text('Primary', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)))],
                  ]),
                );
              }, childCount: contacts.length)),
            ],
          ],

          // Helplines
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Emergency Helplines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1),
              delegate: SliverChildBuilderDelegate((_, i) {
                final h = helplines.values.toList()[i];
                return GestureDetector(
                  onTap: () => _dialHelpline(h['number']),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(h['icon'] ?? '📞', style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(h['name'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.grey)),
                      Text(h['number'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ]),
                  ),
                );
              }, childCount: helplines.length),
            ),
          ),

          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Column(children: [
            Text('Powered by VahanTag', style: TextStyle(fontSize: 12, color: AppColors.grey)),
            Text('vahantag.com', style: TextStyle(fontSize: 12, color: AppColors.primary)),
          ])))),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _simpleInfo(String emoji, String title, String sub) => Scaffold(
    body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey, fontSize: 14, height: 1.5)),
    ]))),
  );
}

class _ContactBtn extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final Color bg;
  final VoidCallback onTap;
  const _ContactBtn(this.emoji, this.title, this.sub, this.bg, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.grey),
        ]),
      ),
    );
  }
}
