import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../assets/providers/asset_provider.dart';
import '../../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().loadAssets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final assetProv = context.watch<AssetProvider>();
    final user = auth.user;
    final assets = assetProv.assets;
    final activeAssets = assets.where((a) => a['sub_status'] == 'active').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<AssetProvider>().loadAssets(),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.primary,
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, ${user?['name'] ?? 'Friend'} 👋',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Keep your assets protected', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 22, backgroundColor: Colors.white.withOpacity(0.25),
                      child: Text((user?['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

            // Stats Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _StatCard(value: '${assets.length}', label: 'Total Assets'),
                    const SizedBox(width: 10),
                    _StatCard(value: '${activeAssets.length}', label: 'Protected'),
                    const SizedBox(width: 10),
                    _StatCard(value: '${assets.fold(0, (s, a) => s + (int.tryParse(a['scan_count']?.toString() ?? '0') ?? 0))}', label: 'Total Scans'),
                  ],
                ),
              ),
            ),

            // Active Assets
            if (activeAssets.isNotEmpty) ...[
              const SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Text('Protected Assets', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              )),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final a = activeAssets[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: GestureDetector(
                        onTap: () => context.push('/assets'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
                          child: Row(
                            children: [
                              Text(a['icon'] ?? '📦', style: const TextStyle(fontSize: 36)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                  Text(a['category_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                                  if (a['registration_number'] != null)
                                    Text(a['registration_number'], style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ],
                              )),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: activeAssets.length > 3 ? 3 : activeAssets.length,
                ),
              ),
            ],

            // Quick Actions
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            )),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5,
                  children: [
                    _ActionCard(emoji: '➕', label: 'Add Asset', color: AppColors.success, bg: AppColors.successLight, onTap: () => context.push('/add-asset')),
                    _ActionCard(emoji: '🏷️', label: 'Activate Tag', color: AppColors.blue, bg: AppColors.blueLight, onTap: () => context.push('/activate-tag')),
                    _ActionCard(emoji: '👥', label: 'Emergency Contacts', color: AppColors.purple, bg: AppColors.purpleLight, onTap: () => context.push('/assets')),
                    _ActionCard(emoji: '👤', label: 'My Profile', color: AppColors.primary, bg: AppColors.primaryLight, onTap: () => context.push('/profile')),
                  ],
                ),
              ),
            ),

            // How it works (if no assets)
            if (assets.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🏷️ How VahanTag Works', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ...['Buy a VahanTag QR sticker from an agent', 'Add your asset (vehicle, pet, bag, etc.)', 'Activate the tag and link to your asset', 'Anyone who scans can safely contact you'].asMap().entries.map((e) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: AppColors.grey))),
                          ]),
                        )
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
        ],
      ),
    ));
  }
}

class _ActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _ActionCard({required this.emoji, required this.label, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)]),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ]),
      ),
    );
  }
}
