import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _bloodGroup;
  final _medCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService().getProfile();
      setState(() {
        _profile = res.data['data'];
        _nameCtrl.text = _profile?['name'] ?? '';
        _emailCtrl.text = _profile?['email'] ?? '';
        _bloodGroup = _profile?['blood_group'];
        _medCtrl.text = _profile?['medical_notes'] ?? '';
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _save() async {
    try {
      await ApiService().updateProfile({'name': _nameCtrl.text.trim(), 'email': _emailCtrl.text.trim(), 'blood_group': _bloodGroup, 'medical_notes': _medCtrl.text.trim()});
      await context.read<AuthProvider>().updateUser({'name': _nameCtrl.text.trim()});
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated ✅'), backgroundColor: AppColors.success));
    } catch (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update'), backgroundColor: AppColors.error)); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primary,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 28),
              child: Column(children: [
                CircleAvatar(radius: 40, backgroundColor: Colors.white.withOpacity(0.3), child: Text((_profile?['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white))),
                const SizedBox(height: 12),
                Text(_profile?['name'] ?? 'Set your name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('+91 ${_profile?['phone'] ?? ''}', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                if (_bloodGroup != null) ...[
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('🩸 $_bloodGroup', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                ],
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() => _editing = !_editing),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text(_editing ? 'Cancel' : 'Edit Profile', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                ),
              ]),
            ),
          ),

          // Stats
          SliverToBoxAdapter(child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
            child: Row(children: [
              Expanded(child: Column(children: [Text('${_profile?['asset_count'] ?? 0}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary)), const Text('Assets', style: TextStyle(fontSize: 12, color: AppColors.grey))])),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(child: Column(children: [Text('${_profile?['active_subs'] ?? 0}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary)), const Text('Active Tags', style: TextStyle(fontSize: 12, color: AppColors.grey))])),
            ]),
          )),

          // Edit Form
          if (_editing)
            SliverToBoxAdapter(child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _buildField('Name', _nameCtrl),
                const SizedBox(height: 14),
                _buildField('Email', _emailCtrl, type: TextInputType.emailAddress),
                const SizedBox(height: 14),
                const Text('Blood Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: AppConstants.bloodGroups.map((bg) =>
                  GestureDetector(
                    onTap: () => setState(() => _bloodGroup = bg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: _bloodGroup == bg ? AppColors.primaryLight : AppColors.background, border: Border.all(color: _bloodGroup == bg ? AppColors.primary : AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(20)),
                      child: Text(bg, style: TextStyle(fontWeight: FontWeight.w600, color: _bloodGroup == bg ? AppColors.primary : AppColors.textSecondary)),
                    ),
                  )
                ).toList()),
                const SizedBox(height: 14),
                _buildField('Medical Notes', _medCtrl, maxLines: 3, hint: 'Allergies, conditions, medications...'),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)))),
              ]),
            )),

          // Menu
          SliverToBoxAdapter(child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
            child: Column(children: [
              _menuItem(Icons.inventory_2_outlined, 'My Assets', () => context.push('/assets')),
              _divider(),
              _menuItem(Icons.qr_code, 'Activate Tag', () => context.push('/activate-tag')),
              _divider(),
              _menuItem(Icons.help_outline, 'Support', () => {}),
              _divider(),
              _menuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () => {}),
            ]),
          )),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GestureDetector(
              onTap: () async {
                final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: AppColors.error)))],
                ));
                if (ok == true && mounted) {
                  await context.read<AuthProvider>().logout();
                  if (mounted) context.go('/login');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.error, width: 1.5), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout, color: AppColors.error, size: 20),
                  SizedBox(width: 10),
                  Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
              ),
            ),
          )),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {TextInputType? type, int maxLines = 1, String? hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, keyboardType: type, maxLines: maxLines, style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textHint), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1.5)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 1.5)), filled: true, fillColor: AppColors.background),
      ),
    ]);
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) => ListTile(leading: Icon(icon, color: AppColors.primary, size: 22), title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_right, color: AppColors.grey, size: 20), onTap: onTap);
  Widget _divider() => const Divider(height: 1, indent: 56, color: AppColors.border);
}
