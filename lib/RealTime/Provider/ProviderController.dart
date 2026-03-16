import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:eboro/API/Favorite.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/Helper/FavoriteData.dart';
import 'package:eboro/Helper/MealData.dart';
import 'package:eboro/Helper/ProductData.dart';
import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/Helper/ShippingData.dart';
import 'package:eboro/Helper/TypeData.dart';
import 'package:eboro/Providers/ClickProvider.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:http/http.dart' as http;

import '../../API/Auth.dart';
import '../../Widget/Search.dart';

// top-level function لـ compute isolate (لا تستخدم static variables)
List<ProviderData> _parseProvidersIsolate(String jsonStr) {
  final List<dynamic> list = json.decode(jsonStr);
  return list
      .map((j) => ProviderData.fromJson(j as Map<String, dynamic>))
      .toList();
}

class ProviderController with ChangeNotifier {
  List<ProviderData>? providers = List<ProviderData>.empty(growable: true);
  List<ProviderData>? filteredProviders =
      List<ProviderData>.empty(growable: true);
  List<FavoriteData>? Favorites = List<FavoriteData>.empty(growable: true);
  List<ProductData>? products = List<ProductData>.empty(growable: true);
  List<MealData>? Meals = List<MealData>.empty(growable: true);
  List<TypeData>? Types = List<TypeData>.empty(growable: true);
  String? categoryId;

  // Loading flags to prevent multiple simultaneous API calls
  bool _isLoadingProviders = false;
  bool _isLoadingProducts = false;

  // Completers to allow waiting for in-progress loads
  Completer<void>? _providersCompleter;
  Completer<void>? _productsCompleter;

  // Generation counter to cancel stale delivery data fetches
  int _deliveryFetchGeneration = 0;

  /// حالة التحميل مكشوفة للـ UI لعرض skeleton loading
  bool get isLoading => _isLoadingProviders;

  // ===== Local Cache =====
  static const String _cacheKey = 'providers_cache';
  static const String _deliveryCacheKey = 'delivery_cache';
  static const String _deliveryLatLngKey = 'delivery_cache_latlng';

  /// انتظار تحميل المحلات
  Future<void> waitForProviders() async {
    if (providers != null && providers!.isNotEmpty) return;
    if (_providersCompleter != null) {
      await _providersCompleter!.future;
    }
  }

  /// مسح cache التوصيل (يُستدعى عند تغيير العنوان)
  Future<void> clearDeliveryCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deliveryCacheKey);
      await prefs.remove(_deliveryLatLngKey);
      print('DEBUG: Delivery cache cleared');
    } catch (_) {}
  }

  /// تحميل المزودين من الـ cache المحلي فوراً (بدون انتظار API)
  /// ما بيعمل fetch للـ delivery من الـ API - ده بيتم في Providers() بعدها
  Future<bool> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached == null || cached.isEmpty) return false;

      // تحليل JSON في isolate منفصل لعدم تجميد الـ UI
      providers = await compute(_parseProvidersIsolate, cached);
      providers!.sort((a, b) {
        final aOpen = a.state == '1' ? 0 : 1;
        final bOpen = b.state == '1' ? 0 : 1;
        return aOpen.compareTo(bOpen);
      });
      filteredProviders = providers;

      // تحميل بيانات التوصيل من الـ cache لو العنوان ما اتغيرش
      final deliveryRestored = await _loadDeliveryFromCache();

      // لو الكاش ما رجع بيانات توصيل (عنوان مختلف)، نخفي المحلات مؤقتاً
      if (!deliveryRestored && providers != null) {
        final hasLocation = Auth2.user?.activeLat != null &&
            Auth2.user!.activeLat!.isNotEmpty &&
            Auth2.user?.activeLong != null &&
            Auth2.user!.activeLong!.isNotEmpty;
        if (hasLocation) {
          for (final p in providers!) {
            p.outOfDeliveryRange = true;
          }
        }
      }

      notifyListeners();

      return true;
    } catch (_) {
      return false;
    }
  }

  /// حفظ المزودين في الـ cache المحلي
  Future<void> _saveToCache(List<ProviderData>? providersList) async {
    if (providersList == null || providersList.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // نحفظ rawJson لكل provider (أخف من إعادة التحويل)
      final jsonList = providersList
          .where((p) => p.rawJson != null)
          .map((p) => p.rawJson!)
          .toList();
      if (jsonList.isNotEmpty) {
        await prefs.setString(_cacheKey, json.encode(jsonList));
      }
    } catch (_) {}
  }

  /// حفظ بيانات التوصيل في الـ cache مع lat/long الحالي
  Future<void> _saveDeliveryToCache() async {
    if (providers == null || providers!.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = Auth2.user?.activeLat?.toString() ?? '';
      final lng = Auth2.user?.activeLong?.toString() ?? '';

      // حفظ بيانات التوصيل لكل provider (بما فيهم اللي خارج النطاق)
      final Map<String, dynamic> deliveryMap = {};
      for (final p in providers!) {
        if (p.id == null) continue;
        if (p.outOfDeliveryRange) {
          deliveryMap[p.id.toString()] = {'outOfRange': true};
        } else if (p.Delivery != null) {
          deliveryMap[p.id.toString()] = {
            'shipping': p.Delivery!.shipping,
            'Tax': p.Delivery!.Tax,
            'Time': p.Delivery!.Time,
            'Duration': p.Delivery!.Duration,
            'Distance': p.Delivery!.Distance,
            'OrderMin': p.Delivery!.OrderMin,
          };
        }
      }

      if (deliveryMap.isNotEmpty) {
        await prefs.setString(_deliveryCacheKey, json.encode(deliveryMap));
        await prefs.setString(_deliveryLatLngKey, '$lat,$lng');
      }
    } catch (_) {}
  }

  /// تحميل بيانات التوصيل من الـ cache لو العنوان نفسه
  Future<bool> _loadDeliveryFromCache() async {
    try {
      // لو المستخدم ما حدد موقعه، ما نحمل cache التوصيل عشان ما نخفي المحلات
      final latStr = Auth2.user?.activeLat;
      final longStr = Auth2.user?.activeLong;
      if (latStr == null ||
          longStr == null ||
          latStr.isEmpty ||
          longStr.isEmpty) return false;
      final latVal = double.tryParse(latStr) ?? 0.0;
      final longVal = double.tryParse(longStr) ?? 0.0;
      if (latVal == 0.0 && longVal == 0.0) return false;

      final prefs = await SharedPreferences.getInstance();
      final cachedLatLng = prefs.getString(_deliveryLatLngKey);
      if (cachedLatLng == null) return false;

      final currentLatLng = '$latStr,$longStr';

      // لو العنوان اتغير، الـ cache مش صالح
      if (cachedLatLng != currentLatLng) return false;

      final cachedDelivery = prefs.getString(_deliveryCacheKey);
      if (cachedDelivery == null) return false;

      final Map<String, dynamic> deliveryMap = json.decode(cachedDelivery);
      if (deliveryMap.isEmpty) return false;

      int restored = 0;
      for (final p in providers!) {
        final data = deliveryMap[p.id.toString()];
        if (data == null) continue;

        if (data['outOfRange'] == true) {
          p.outOfDeliveryRange = true;
          restored++;
        } else {
          p.Delivery = ShippingData.fromJson(data);
          p.outOfDeliveryRange = false;
          restored++;
        }
      }

      return restored > 0;
    } catch (_) {
      return false;
    }
  }

  // Banner filtered providers - shown in a dedicated section
  List<ProviderData>? bannerProviders;
  String? bannerTitle;

  /// Set banner filtered providers (shown in dedicated section under banners)
  void setBannerProviders(List<ProviderData>? providers, {String? title}) {
    bannerProviders = providers;
    bannerTitle = title;
    notifyListeners();
  }

  /// Clear banner filter
  void clearBannerFilter() {
    bannerProviders = null;
    bannerTitle = null;
    notifyListeners();
  }

  /// Refresh only favorites without reloading providers
  Future<void> refreshFavorites() async {
    if (Auth2.user?.email != null && Auth2.user!.email != "info@eboro.com") {
      Favorites = await Favorite2.getFavorite();
      notifyListeners();
    }
  }

  /// Toggle favorite locally (optimistic) ثم يحدث من الـ API
  Future<void> toggleFavorite(
      ProviderData provider, BuildContext context) async {
    final isFav = Favorites?.any((f) => f.provider?.id == provider.id) ?? false;

    // تحديث فوري (optimistic)
    if (isFav) {
      Favorites?.removeWhere((f) => f.provider?.id == provider.id);
    } else {
      Favorites ??= [];
      Favorites!.add(FavoriteData(id: 0, provider: provider));
    }
    notifyListeners();

    // API call
    await Favorite2.removeFromFavorite(provider.id, context);
    await refreshFavorites();
  }

  updateProvider(categoryId, {bool force = false}) async {
    // لو فيه تحميل شغال، استنى يخلص بدل ما نتجاهل
    if (_isLoadingProviders && !force) {
      if (_providersCompleter != null) {
        await _providersCompleter!.future;
      }
      return;
    }
    _isLoadingProviders = true;
    _providersCompleter = Completer<void>();
    notifyListeners(); // Initial loading state

    try {
      this.categoryId = categoryId;
      final typesCategoryId = categoryId ?? '1';

      // تحميل كل البيانات بالتوازي: providers + types + favorites
      final providersFuture = Provider2.getProviders(categoryId);
      final typesFuture = Provider2.getTypes(typesCategoryId);
      final favoritesFuture =
          (Auth2.user?.email != null && Auth2.user!.email != "info@eboro.com")
              ? Favorite2.getFavorite()
              : Future.value(<FavoriteData>[]);

      final results = await Future.wait([
        providersFuture,
        typesFuture,
        favoritesFuture,
      ]);

      providers = results[0] as List<ProviderData>?;
      Types = results[1] as List<TypeData>?;
      Favorites = results[2] as List<FavoriteData>?;

      filteredProviders = providers;

      _saveToCache(providers);

      // مسح بيانات التوصيل القديمة - نخفي المحلات لحد ما نحسب المسافة الجديدة
      if (providers != null) {
        final hasLocation = Auth2.user?.activeLat != null &&
            Auth2.user!.activeLat!.isNotEmpty &&
            Auth2.user?.activeLong != null &&
            Auth2.user!.activeLong!.isNotEmpty;
        for (final p in providers!) {
          p.Delivery = null;
          // لو عنده موقع، نخفي المحلات مؤقتاً لحد ما نحسب المسافة
          // لو ما عنده موقع، نعرض الكل
          p.outOfDeliveryRange = hasLocation;
        }
      }

      await _loadDeliveryFromCache();

      // Load delivery data in background without blocking UI
      _fetchDeliveryDataProgressively();
      _preloadTopProducts();
    } finally {
      _isLoadingProviders = false;
      _providersCompleter?.complete();
      _providersCompleter = null;
      notifyListeners(); // Single notify after all data is ready
    }
  }

  void _fetchDeliveryDataProgressively() async {
    _deliveryFetchGeneration++;
    final currentGeneration = _deliveryFetchGeneration;

    final list = providers;
    if (list == null || list.isEmpty) return;

    // لو المستخدم ما حدد موقعه، ما نحسب التوصيل ونعرض كل المحلات
    final latStr = Auth2.user?.activeLat;
    final longStr = Auth2.user?.activeLong;
    if (latStr == null || longStr == null || latStr.isEmpty || longStr.isEmpty) return;
    final latVal = double.tryParse(latStr) ?? 0.0;
    final longVal = double.tryParse(longStr) ?? 0.0;
    if (latVal == 0.0 && longVal == 0.0) return;

    // تحميل رسوم التوصيل على دفعات عشان المحلات تظهر تدريجياً
    final toFetch = list.where((p) => p.Delivery == null && p.rawJson != null).toList();
    if (toFetch.isEmpty) return;

    // دفعات أكبر (10 بدل 5) مع notify أقل لتقليل الـ flickering
    const batchSize = 10;
    for (var i = 0; i < toFetch.length; i += batchSize) {
      if (_deliveryFetchGeneration != currentGeneration) return;

      final batch = toFetch.skip(i).take(batchSize).toList();
      await Future.wait(batch.map((p) async {
        if (_deliveryFetchGeneration != currentGeneration) return;
        try {
          final result = await ProviderData.fetchDeliveryData(p.rawJson!);
          if (_deliveryFetchGeneration != currentGeneration) return;
          if (result != null) {
            p.Delivery = result;
            p.outOfDeliveryRange = false;
          } else {
            p.outOfDeliveryRange = true;
          }
        } catch (_) {}
      }));

      // نحدث الـ UI بعد كل دفعة عشان المحلات تظهر تدريجياً
      if (_deliveryFetchGeneration == currentGeneration) {
        notifyListeners();
      }
    }

    // حفظ بيانات التوصيل في الـ cache للتحميل الفوري لاحقاً
    if (_deliveryFetchGeneration == currentGeneration) {
      _saveDeliveryToCache();
    }
  }

  Providers(categoryId, context) async {
    // لو فيه تحميل شغال، استنى يخلص وبعدين حمّل بالـ category الجديدة
    if (_isLoadingProviders) {
      if (_providersCompleter != null) {
        await _providersCompleter!.future;
      }
    }
    _isLoadingProviders = true;
    _providersCompleter = Completer<void>();
    notifyListeners();

    try {
      this.categoryId = categoryId;
      final typesCategoryId = categoryId ?? '1';

      final results = await Future.wait([
        Provider2.getProviders(categoryId),
        if (Auth2.user?.email != null && Auth2.user!.email != "info@eboro.com")
          Favorite2.getFavorite()
        else
          Future.value(<FavoriteData>[]),
        Provider2.getTypes(typesCategoryId),
      ]);

      providers = results[0] as List<ProviderData>?;
      Favorites = results[1] as List<FavoriteData>?;
      Types = results[2] as List<TypeData>?;

      filteredProviders?.clear();
      providers!.sort((a, b) {
        final aOpen = a.state == '1' ? 0 : 1;
        final bOpen = b.state == '1' ? 0 : 1;
        return aOpen.compareTo(bOpen);
      });
      filteredProviders = providers;

      Search2.type_id2.clear();

      _saveToCache(providers);

      // مسح بيانات التوصيل القديمة - نخفي المحلات لحد ما نحسب المسافة الجديدة
      final hasLocation = Auth2.user?.activeLat != null &&
          Auth2.user!.activeLat!.isNotEmpty &&
          Auth2.user?.activeLong != null &&
          Auth2.user!.activeLong!.isNotEmpty;
      for (final p in providers!) {
        p.Delivery = null;
        p.outOfDeliveryRange = hasLocation;
      }

      await _loadDeliveryFromCache();

      _fetchDeliveryDataProgressively();
      _preloadTopProducts();
    } finally {
      _isLoadingProviders = false;
      _providersCompleter?.complete();
      _providersCompleter = null;
      notifyListeners(); // Single notify after all data is ready
    }
  }

  /// تحميل منتجات أول 3 محلات في الخلفية عشان تكون جاهزة فوراً
  void _preloadTopProducts() async {
    if (providers == null || providers!.isEmpty) return;
    final topProviders = providers!.take(3).toList();
    for (final p in topProviders) {
      if (p.id == null) continue;
      // نحمل في الخلفية بدون blocking
      Provider2.getProducts(p.id).then((_) {}).catchError((_) {});
    }
  }

  /// تحميل صور أول المحلات مسبقاً عشان تظهر فوراً بدون تحميل
  void precacheProviderImages(BuildContext context) {
    if (providers == null || providers!.isEmpty) return;
    final topProviders = providers!.take(6).toList();
    for (final p in topProviders) {
      final url = fixImageUrl(p.logo?.toString());
      if (url.isEmpty) continue;

      // تحقق سريع لتجنب 404 أثناء الـ precache
      http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 4))
          .then((response) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          precacheImage(CachedNetworkImageProvider(url), context)
              .catchError((_) {});
        }
      }).catchError((_) {});
    }
  }

  /// تحميل المنتجات - بدون blocking الـ navigation
  /// [flag] = true يعني navigate فورا وتحميل المنتجات في الـ background
  updateProduct(ProviderData? provider, context, [bool flag = false]) async {
    // لو flag = true، نروح للصفحة فورا والمنتجات هتتحمل هناك
    if (flag) {
      Progress.dimesDialog(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ClickProvider(
                  name: provider?.name, providerID: provider?.id)));

      _loadProductsInBackground(provider?.id);
      return;
    }

    // لو فيه تحميل شغال، استنى يخلص
    if (_isLoadingProducts) {
      if (_productsCompleter != null) {
        await _productsCompleter!.future;
      }
      return;
    }
    _isLoadingProducts = true;
    _productsCompleter = Completer<void>();

    try {
      final results = await Future.wait([
        Provider2.getProducts(provider?.id),
        Provider2.getMeals(provider?.id),
      ]);
      products = results[0] as List<ProductData>?;
      Meals = results[1] as List<MealData>?;

      Provider2.product = products;
      Provider2.meal = Meals;

      notifyListeners();
    } finally {
      _isLoadingProducts = false;
      _productsCompleter?.complete();
      _productsCompleter = null;
    }
  }

  /// تحميل المنتجات في الـ background
  void _loadProductsInBackground(int? providerId) async {
    if (providerId == null) return;
    // لو فيه تحميل شغال، استنى يخلص
    if (_isLoadingProducts) {
      if (_productsCompleter != null) {
        await _productsCompleter!.future;
      }
    }
    _isLoadingProducts = true;
    _productsCompleter = Completer<void>();

    try {
      final results = await Future.wait([
        Provider2.getProducts(providerId),
        Provider2.getMeals(providerId),
      ]);
      products = results[0] as List<ProductData>?;
      Meals = results[1] as List<MealData>?;

      Provider2.product = products;
      Provider2.meal = Meals;

      notifyListeners();
    } finally {
      _isLoadingProducts = false;
      _productsCompleter?.complete();
      _productsCompleter = null;
    }
  }

  updateScreen(List<ProviderData>? providers) async {
    filteredProviders = providers;
    notifyListeners();
  }
}
