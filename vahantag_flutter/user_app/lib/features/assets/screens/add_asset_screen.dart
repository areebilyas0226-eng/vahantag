import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});
  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  Map<String, dynamic>? _selectedCat;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AssetProvider>().loadCategories());
    for (final k in ['name','description','registration_number','make','model','year','color','pet_breed','brand','serial_number']) {
      _controllers[k] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCat == null) { _showSnack('Select a category'); return; }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final data = <String, dynamic>{'category_id': _selectedCat!['id']};
    for (final k in _controllers.keys) {
      if (_controllers[k]!.text.isNotEmpty) data[k] = _controllers[k]!.text.trim();
    }
    final ok = await context.read<AssetProvider>().addAsset(data);
    setState(() => _loading = false);
    if (ok && mounted) {
      _showSnack('Asset added successfully! 🎉', isSuccess: true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.pop();
    } else if (mounted) {
      _showSnack('Failed to add asset. Try again.');
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isSuccess ? AppColors.success : AppColors.error));
  }

  Widget _field(String key, String label, {String? hint, TextInputType? type, bool required = false, TextCapitalization cap = TextCapitalization.none}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controllers[key],
            keyboardType: type,
            textCapitalization: cap,
            validator: required ? (v) => v == null || v.isEmpty ? '$label is required' : null : null,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textHint),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
              filled: true, fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryFields() {
    if (_selectedCat == null) return const SizedBox();
    final slug = _selectedCat!['slug'];
    if (slug == 'vehicle') return Column(children: [
      _field('name', 'Asset Name *', hint: 'My Car, Family Bike...', required: true),
      _field('registration_number', 'Registration Number', hint: 'MH12AB1234', cap: TextCapitalization.characters),
      _field('make', 'Brand / Make', hint: 'Maruti, Honda, Bajaj...'),
      _field('model', 'Model', hint: 'Swift, Activa...'),
      _field('year', 'Year', type: TextInputType.number),
      _field('color', 'Color', hint: 'White, Black, Silver...'),
    ]);
    if (slug == 'pet') return Column(children: [
      _field('name', 'Pet Name *', hint: 'Tommy, Milo...', required: true),
      _field('pet_breed', 'Breed', hint: 'Labrador, Persian Cat...'),
      _field('color', 'Color / Appearance', hint: 'Golden, Black & White...'),
    ]);
    if (slug == 'electronics') return Column(children: [
      _field('name', 'Device Name *', hint: 'My iPhone, Work Laptop...', required: true),
      _field('brand', 'Brand', hint: 'Apple, Samsung, HP...'),
      _field('model', 'Model', hint: 'iPhone 15, Galaxy S24...'),
      _field('serial_number', 'Serial / IMEI', hint: 'Serial number or IMEI'),
    ]);
    return Column(children: [
      _field('name', 'Asset Name *', hint: 'Describe your asset...', required: true),
      _field('brand', 'Brand', hint: 'Brand name...'),
      _field('serial_number', 'Serial Number', hint: 'If any'),
      _field('description', 'Notes', hint: 'Any additional details...'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AssetProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Add Asset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => context.pop()),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              if (prov.categories.isEmpty) const Center(child: CircularProgressIndicator(color: AppColors.primary))
              else GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9,
                children: prov.categories.map((cat) {
                  final selected = _selectedCat?['id'] == cat['id'];
                  return GestureDetector(
                    onTap: () => setState(() { _selectedCat = cat; for (final c in _controllers.values) c.clear(); }),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryLight : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(cat['icon'] ?? '📦', style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(cat['name'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textSecondary)),
                        Text('₹${(cat['yearly_price_paisa'] ~/ 100)}/yr', style: TextStyle(fontSize: 10, color: selected ? AppColors.primary : AppColors.grey)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedCat != null) ...[
                const SizedBox(height: 24),
                const Text('Asset Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _categoryFields(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Activation Cost', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    Text('₹${_selectedCat!['yearly_price_paisa'] ~/ 100}/year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withOpacity(0.6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        : const Text('Add Asset', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
