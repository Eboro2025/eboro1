import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:eboro/Helper/ProductData.dart';
import 'package:eboro/API/Provider.dart';

/// Provider لإدارة cache المنتجات مع تحميل سلس بدون توقف
class ProductCacheProvider extends ChangeNotifier {
  // Cache للمنتجات حسب provider_id
  final Map<int, List<ProductData>> _cache = {};

  // حالة التحميل لكل provider
  final Map<int, bool> _isLoading = {};

  // آخر وقت تحديث
  final Map<int, DateTime> _lastUpdate = {};

  // مدة صلاحية الـ cache (10 دقائق)
  static const Duration cacheValidity = Duration(minutes: 10);

  /// الحصول على المنتجات من الـ cache
  List<ProductData> getProducts(int providerId) {
    return _cache[providerId] ?? [];
  }

  /// هل يتم التحميل حاليا؟
  bool isLoading(int providerId) {
    return _isLoading[providerId] ?? false;
  }

  /// هل الـ cache صالح؟
  bool isCacheValid(int providerId) {
    final lastUpdate = _lastUpdate[providerId];
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < cacheValidity;
  }

  /// هل فيه منتجات محملة؟
  bool hasProducts(int providerId) {
    return _cache[providerId]?.isNotEmpty ?? false;
  }

  /// تحميل المنتجات في الـ background بدون blocking
  Future<void> loadProductsInBackground(int providerId) async {
    // لو بيحمل حاليا، ما نعملش حاجة
    if (_isLoading[providerId] == true) return;

    // لو الـ cache صالح، ما نحملش تاني
    if (isCacheValid(providerId) && hasProducts(providerId)) return;

    _isLoading[providerId] = true;

    try {
      final products = await Provider2.getProducts(providerId);

      if (products != null && products.isNotEmpty) {
        _cache[providerId] = products;
        _lastUpdate[providerId] = DateTime.now();

        // بنبلغ الـ UI إن فيه داتا جديدة
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
      }
    } finally {
      _isLoading[providerId] = false;
    }
  }

  /// تحديث المنتجات بالقوة (refresh)
  Future<void> refreshProducts(int providerId) async {
    _lastUpdate.remove(providerId);
    _cache.remove(providerId);
    await loadProductsInBackground(providerId);
  }

  /// مسح الـ cache لكل المنتجات
  void clearAll() {
    _cache.clear();
    _isLoading.clear();
    _lastUpdate.clear();
    notifyListeners();
  }

  /// مسح cache provider معين
  void clearProvider(int providerId) {
    _cache.remove(providerId);
    _isLoading.remove(providerId);
    _lastUpdate.remove(providerId);
  }

  /// Pre-load المنتجات لمجموعة providers بدفعات صغيرة
  Future<void> preloadProviders(List<int> providerIds) async {
    // تحميل بدفعات 3 بالتوازي لعدم إرهاق الشبكة
    const batchSize = 3;
    for (int i = 0; i < providerIds.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, providerIds.length);
      final batch = providerIds.sublist(i, end);
      await Future.wait(batch.map((id) => loadProductsInBackground(id)));
    }
  }

  /// حفظ المنتجات في الـ cache مباشرة (لو جايين من مصدر تاني)
  void cacheProducts(int providerId, List<ProductData> products) {
    if (products.isNotEmpty) {
      _cache[providerId] = products;
      _lastUpdate[providerId] = DateTime.now();
      notifyListeners();
    }
  }
}
