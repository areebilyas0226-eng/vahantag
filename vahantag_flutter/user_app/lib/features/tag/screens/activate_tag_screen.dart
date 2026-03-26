import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../assets/providers/asset_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class ActivateTagScreen extends StatefulWidget {
  final String? assetId;
  final String? assetName;
  const ActivateTagScreen({super.key, this.assetId, this.assetName});
  @override
  State<ActivateTagScreen> createState() => _ActivateTagScreenState();
}

class _ActivateTagScreenState extends State<ActivateTagScreen> {
  final _tagCtrl = TextEditingController();
  String? _selectedAssetId;
  String? _bloodGroup;
  Map<String, dynamic>? _activationData;
  bool _loading = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    if (widget.assetId != null) _selectedAssetId = widget.assetId;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AssetProvider>().loadAssets());
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _findTag() async {
    final code = _tagCtrl.text.trim().toUpperCase();
    if (!RegExp(r'^VT-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid format. Use: VT-XXXX-XXXX'), backgroundColor: AppColors.error));
      return;
    }
    if (_selectedAssetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an asset'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _loading = true);
    final data = await context.read<AssetProvider>().activateTag({'tag_code': code, 'asset_id': _selectedAssetId, if (_bloodGroup != null) 'blood_group': _bloodGroup});
    setState(() { _activationData = data; _loading = false; });
    if (data == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AssetProvider>().error ?? 'Tag not found or already used'), backgroundColor: AppColors.error));
    }
  }

  void _openPayment() {
    final order = _activationData!['order'];
    final user = context.read<AuthProvider>().user;
    final options = {
      'key': order['keyId'] ?? AppConstants.razorpayKey,
      'amount': order['amount'],
      'currency': 'INR',
      'name': 'VahanTag',
      'description': 'Tag Activation - ${_activationData!['asset']?['name'] ?? ''}',
      'order_id': order['orderId'],
      'prefill': {'contact': '+91${user?['phone'] ?? ''}', 'name': user?['name'] ?? ''},
      'theme': {'color': '#FF6B00'},
    };
    _razorpay.open(options);
  }

  Future<void> _onSuccess(PaymentSuccessResponse res) async {
    setState(() => _loading = true);
    final result = await context.read<AssetProvider>().verifyActivation({
      'razorpay_order_id': res.orderId,
      'razorpay_payment_id': res.paymentId,
      'razorpay_signature': res.signature,
    });
    setState(() => _loading = false);
    if (result != null && mounted) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('🎉 Tag Activated!'),
        content: const Text('Your asset is now protected for 1 year! Paste the sticker on your asset.'),
        actions: [TextButton(onPressed: () { Navigator.pop(context); context.go('/assets'); }, child: const Text('View Assets', style: TextStyle(color: AppColors.primary)))],
      ));
    }
  }

  void _onError(PaymentFailureResponse res) {
    if (res.code != 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed. Please try again.'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = context.watch<AssetProvider>().assets.where((a) => a['tag_code'] == null).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary, elevation: 0,
        title: const Text('Activate Tag', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14), border: Border(left: BorderSide(color: AppColors.primary, width: 4))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Activate Your QR Sticker', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 6),
              const Text('Enter the code printed on your physical VahanTag sticker (format: VT-XXXX-XXXX)', style: TextStyle(fontSize: 13, color: AppColors.grey, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 24),

          const Text('Tag Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _tagCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 12,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: 'VT-XXXX-XXXX',
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
              filled: true, fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 24),

          const Text('Link to Asset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          if (assets.isEmpty)
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), child: Column(children: [
              const Text('No unlinked assets found. Add an asset first.', style: TextStyle(color: AppColors.grey)),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.push('/add-asset'), child: const Text('+ Add Asset', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
            ]))
          else
            ...assets.map((a) => GestureDetector(
              onTap: () => setState(() => _selectedAssetId = a['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: Border.all(color: _selectedAssetId == a['id'] ? AppColors.primary : AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(12), color: _selectedAssetId == a['id'] ? AppColors.primaryLight : Colors.white),
                child: Row(children: [
                  Icon(_selectedAssetId == a['id'] ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('${a['category_name'] ?? ''} ${a['registration_number'] != null ? '· ${a['registration_number']}' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                  ]),
                ]),
              ),
            )),
          const SizedBox(height: 20),

          const Text('Blood Group (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Shown on emergency page to help in medical situations', style: TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: AppConstants.bloodGroups.map((bg) =>
            GestureDetector(
              onTap: () => setState(() => _bloodGroup = _bloodGroup == bg ? null : bg),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: _bloodGroup == bg ? AppColors.primaryLight : AppColors.background, border: Border.all(color: _bloodGroup == bg ? AppColors.primary : AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(20)),
                child: Text(bg, style: TextStyle(fontWeight: FontWeight.w600, color: _bloodGroup == bg ? AppColors.primary : AppColors.textSecondary)),
              ),
            )
          ).toList()),
          const SizedBox(height: 28),

          if (_activationData == null)
            SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
              onPressed: _loading ? null : _findTag,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withOpacity(0.6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5) : const Text('Find Tag & Get Price', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ))
          else
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary, width: 1.5)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ready to Activate!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              _row('Asset', _activationData!['asset']?['name'] ?? ''),
              _row('Category', _activationData!['category']?['name'] ?? ''),
              _row('Validity', '1 Year'),
              _row('Amount', '₹${(_activationData!['price'] as num) ~/ 100}', valueStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                label: const Text('Pay & Activate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                onPressed: _loading ? null : _openPayment,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withOpacity(0.6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              )),
              const SizedBox(height: 8),
              const Center(child: Text('🔒 Secured by Razorpay · UPI, Cards, NetBanking', style: TextStyle(fontSize: 11, color: AppColors.grey))),
            ])),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? valueStyle}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 14)),
      Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    ]),
  );
}
