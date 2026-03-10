import 'package:eboro/Helper/BannerData.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BannerApi {
  // Cache banners for 5 minutes
  static List<BannerData>? _cachedBanners;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  static Future<List<BannerData>> getActiveBanners({bool forceRefresh = false}) async {
    // Return cached banners if valid
    if (!forceRefresh && _cachedBanners != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedBanners!;
      }
    }

    try {
      String myUrl = "$globalUrl/api/banners";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<BannerData> banners = [];

        if (jsonData['data'] != null) {
          for (var item in jsonData['data']) {
            banners.add(BannerData.fromJson(item));
          }
        }

        // Update cache
        _cachedBanners = banners;
        _cacheTime = DateTime.now();

        return banners;
      } else {
        // Return cached data on error if available
        return _cachedBanners ?? [];
      }
    } catch (e) {
      // print('Error loading banners: $e');
      // Return cached data on error if available
      return _cachedBanners ?? [];
    }
  }

  /// تحديث المحلات المرتبطة بالبانر
  static Future<bool> updateBannerProviders(int bannerId, List<int> providerIds) async {
    try {
      String myUrl = "$globalUrl/api/banners/$bannerId/providers";
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
          'Content-Type': 'application/json',
        },
        body: json.encode({'provider_ids': providerIds}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // مسح الـ cache لتحديث البيانات
        _cachedBanners = null;
        _cacheTime = null;
        return true;
      }
      return false;
    } catch (e) {
      // print('Error updating banner providers: $e');
      return false;
    }
  }
}
