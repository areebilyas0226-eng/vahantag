import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';

class AssetProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get assets => _assets;
  List<Map<String, dynamic>> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAssets() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService().getMyAssets();
      _assets = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      final res = await ApiService().getCategories();
      _categories = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addAsset(Map<String, dynamic> data) async {
    try {
      await ApiService().addAsset(data);
      await loadAssets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAsset(String id) async {
    try {
      await ApiService().deleteAsset(id);
      await loadAssets();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> activateTag(Map<String, dynamic> data) async {
    try {
      final res = await ApiService().activateTag(data);
      return res.data['data'];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyActivation(Map<String, dynamic> data) async {
    try {
      final res = await ApiService().verifyActivation(data);
      await loadAssets();
      return res.data['data'];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
