import 'package:eboro/main.dart';
import 'package:eboro/Helper/DailySpecialData.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DailySpecialApi {
  // Cache daily specials for 5 minutes
  static List<DailySpecialData>? _cachedSpecials;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Get today's daily specials
  static Future<List<DailySpecialData>> getTodaySpecials({bool forceRefresh = false}) async {
    // Return cached data if valid
    if (!forceRefresh && _cachedSpecials != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedSpecials!;
      }
    }

    try {
      String myUrl = "$globalUrl/api/daily-specials";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<DailySpecialData> specials = [];

        if (jsonData['data'] != null) {
          for (var item in jsonData['data']) {
            specials.add(DailySpecialData.fromJson(item));
          }
        }

        // Update cache
        _cachedSpecials = specials;
        _cacheTime = DateTime.now();

        return specials;
      } else {
        return _cachedSpecials ?? [];
      }
    } catch (e) {
      // print('Error loading daily specials: $e');
      return _cachedSpecials ?? [];
    }
  }

  /// Get provider IDs that have daily specials today
  static Future<List<int>> getProviderIdsWithSpecials({bool forceRefresh = false}) async {
    try {
      String myUrl = "$globalUrl/api/daily-specials/provider-ids";
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

        return ids;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Clear cache (call when needed to refresh data)
  static void clearCache() {
    _cachedSpecials = null;
    _cacheTime = null;
  }
}
