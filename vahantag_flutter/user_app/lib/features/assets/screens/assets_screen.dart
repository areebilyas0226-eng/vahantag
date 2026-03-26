import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../../../core/constants/app_colors.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});
  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AssetProvider>().loadAssets());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AssetProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => prov.loadAssets(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.primary,
              floating: true,
              pinned: true,
              expandedHeight: 90,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('My Assets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              ),
              actions: [
                IconButton(
                  icon: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 22)),
                  onPressed: () => context.push('/add-asset').then((_) => prov.loadAssets()),
                ),
                const SizedBox(width: 8),
              ],
            ),
            if (prov.loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (prov.assets.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏷️', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      const Text('No assets yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Add your first asset to protect it', style: TextStyle(fontSize: 14, color: AppColors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Asset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => context.push('/add-asset').then((_) => prov.loadAssets()),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final a = prov.assets[i];
                      final isActive = a['sub_status'] == 'active';
                      final hasTag = a['tag_code'] != null;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Text(a['icon'] ?? '📦', style: const TextStyle(fontSize: 40)),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                      Text(a['category_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                                      if (a['registration_number'] != null) Text(a['registration_number'], style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                      if (a['tag_code'] != null) Text('🏷️ ${a['tag_code']}', style: const TextStyle(fontSize: 11, color: AppColors.blue)),
                                    ],
                                  )),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.successLight : hasTag ? AppColors.warningLight : AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : hasTag ? 'Expired' : 'No Tag',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? AppColors.success : hasTag ? AppColors.warning : AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(children: [
                                if (!hasTag)
                                  _AssetActionBtn('Activate Tag', Icons.qr_code, AppColors.primary, () => context.push('/activate-tag', extra: {'assetId': a['id'], 'assetName': a['name']}).then((_) => prov.loadAssets())),
                                if (hasTag) ...[
                                  _AssetActionBtn('View QR', Icons.qr_code, AppColors.blue, () => context.push('/view-qr', extra: {'assetId': a['id'], 'tagCode': a['tag_code']})),
                                  const SizedBox(width: 8),
                                ],
                                _AssetActionBtn('Contacts', Icons.people_outline, AppColors.purple, () => context.push('/emergency-contacts', extra: {'assetId': a['id'], 'assetName': a['name']})),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                      title: const Text('Remove Asset'),
                                      content: Text('Remove ${a['name']}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: AppColors.error))),
                                      ],
                                    ));
                                    if (ok == true) prov.deleteAsset(a['id']);
                                  },
                                ),
                              ]),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: prov.assets.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _AssetActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AssetActionBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))]),
      ),
    );
  }
}
