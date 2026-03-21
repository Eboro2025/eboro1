import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PremiumApi {
  // Cache premium provider IDs for 5 minutes
  static List<int>? _cachedPremiumIds;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Get list of premium provider IDs
  static Future<List<int>> getPremiumProviderIds({bool forceRefresh = false}) async {
    // Return cached IDs if valid
    if (!forceRefresh && _cachedPremiumIds != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedPremiumIds!;
      }
    }

    try {
      String myUrl = "$globalUrl/api/premium/provider-ids";
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
        List<int> ids = [];

        if (jsonData['data'] != null) {
          for (var id in jsonData['data']) {
            ids.add(id is int ? id : int.parse(id.toString()));
          }
        }

        // Update cache
        _cachedPremiumIds = ids;
        _cacheTime = DateTime.now();

        return ids;
      } else {
        return _cachedPremiumIds ?? [];
      }
    } catch (e) {
      return _cachedPremiumIds ?? [];
    }
  }

  /// Check if a provider is premium
  static Future<bool> isPremiumProvider(int providerId) async {
    List<int> premiumIds = await getPremiumProviderIds();
    return premiumIds.contains(providerId);
  }

  /// Clear cache (call when needed to refresh data)
  static void clearCache() {
    _cachedPremiumIds = null;
    _cacheTime = null;
  }
}
