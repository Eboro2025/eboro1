import 'package:eboro/Helper/FilterData.dart';
import 'package:eboro/Helper/MealData.dart';
import 'package:eboro/Helper/ProductData.dart';
import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/Helper/TypeData.dart';
import 'package:eboro/Widget/Search.dart';
import 'package:eboro/Helper/JsonHelper.dart';
import 'package:eboro/API/Categories.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/HttpInterceptor.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// دالة top-level لتشغيلها في isolate عبر compute()
/// تقوم بإصلاح JSON + فك التشفير + تحويل لـ ProductData في thread منفصل
List<ProductData> _parseProductsInIsolate(String responseBody) {
  String fixedJson = fixBrokenJson(responseBody);
  final jsonData = json.decode(fixedJson);
  if (jsonData["data"] != null && jsonData["data"] is List) {
    return List<ProductData>.from(
      (jsonData["data"] as List).map((item) => ProductData.fromJson(item)),
    );
  }
  return [];
}

class Providerr extends StatefulWidget {
  @override
  Provider2 createState() => Provider2();
}

class Provider2 extends State<Providerr> {
  static List<ProviderData>? provider;
  static List<ProductData>? product;
  static List<MealData>? meal;
  static List<TypeData>? type;
  static List<FilterData>? filter;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

  static DateTime? _lastProvidersFetch;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  static void clearCache() {
    _lastProvidersFetch = null;
    provider = null;
  }

  static Future<List<ProviderData>?> getProviders(categoryId) async {
    try {
      // Return cached data if fresh (only for logged-in users, not guests)
      final isGuest = Auth2.user?.email == "info@eboro.com";
      if (!isGuest &&
          provider != null &&
          provider!.isNotEmpty &&
          _lastProvidersFetch != null &&
          DateTime.now().difference(_lastProvidersFetch!) <
              _cacheValidDuration) {
        return provider;
      }

      String myUrl = "$globalUrl/api/get/provider-by-cat";
      Map<String, String> body = {};
      if (categoryId != null && categoryId.toString() != 'null') {
        body['category_id'] = categoryId.toString();
      } else if (Categories2.categories != null && Categories2.categories!.isNotEmpty) {
        // Server requires category_id — default to first available category
        body['category_id'] = Categories2.categories!.first.id.toString();
      }
      // Send current delivery coordinates so server calculates correct distance
      if (Auth2.user?.activeLat != null) {
        body['lat'] = Auth2.user!.activeLat!;
      }
      if (Auth2.user?.activeLong != null) {
        body['long'] = Auth2.user!.activeLong!;
      }


      final response = await http
          .post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
          'Connection': 'keep-alive',
        },
        body: body,
      )
          .timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw Exception('Providers request timeout');
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseBody = response.body.trim();
          if (responseBody.isEmpty) {
            return provider ?? [];
          }

          // Handle truncated JSON by finding last complete object
          String jsonToParse = responseBody;
          if (!responseBody.endsWith('}')) {
            final lastBracket = responseBody.lastIndexOf('}');
            if (lastBracket > 100) {
              jsonToParse = responseBody.substring(0, lastBracket + 1);
              // Fixed truncated JSON
            }
          }

          final decoded = json.decode(jsonToParse);
          if (decoded is! Map) return provider ?? [];

          final data = decoded['data'] as List?;
          if (data == null || data.isEmpty) return provider ?? [];

          provider = List<ProviderData>.from(
              data.map((item) => ProviderData.fromJson(item)));

          _lastProvidersFetch = DateTime.now();
          // Providers loaded successfully
        } catch (parseError) {
          // Parse error
          // Keep using cached data if available
          if (provider == null || provider!.isEmpty) {
            provider = [];
          }
          return provider;
        }
      } else {
        // HTTP error
      }
    } catch (e) {
      // Exception
    }
    return provider ?? [];
  }

  /// تنظيف cache عند الرجوع من PayPal لتجنب بيانات قديمة
  static void clearProvidersCache() {
    _lastProvidersFetch = null;
    // Cache cleared
  }

  static Future<List<ProductData>?> getProducts(id) async {
    try {
      String myUrl = "$globalUrl/api/filter/branch-product";

      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': "${MyApp2.token}",
        },
        body: {
          'provider_id': id.toString(),
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Products request timeout');
        },
      );

      if (response.statusCode == 200) {
        try {
          // تشغيل إصلاح JSON + الـ parsing في isolate منفصل لعدم تعطيل الـ UI
          product = await compute(_parseProductsInIsolate, response.body);
        } catch (_) {
          product = [];
        }
      } else {
        product = [];
      }
    } catch (_) {
      product = [];
    }
    return product;
  }

  static Future<List<MealData>?> getMeals(id) async {
    try {
      String myUrl = "$globalUrl/api/get/product-meal/$id";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': "${MyApp2.token}",
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Meals request timeout');
        },
      );

      if (response.statusCode == 200) {
        Iterable A = json.decode(response.body)["data"];
        meal = List<MealData>.from(A.map((A) => MealData.fromJson(A)));
      }
    } catch (_) {}
    return meal;
  }

  static Future<List<TypeData>?> getTypes(id) async {
    try {
      String myUrl = "$globalUrl/api/get/Filter_types/$id";

      final response = await http.get(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });

      if (response.statusCode == 200) {
        Iterable A = await json.decode(response.body)["data"];
        type = List<TypeData>.from(A.map((A) => TypeData.fromJson(A)));
      }
    } catch (_) {}
    return type;
  }

  static Future<List<FilterData>?> showFilter(i, n, context) async {
    try {
      var myUrl = Uri.parse('$globalUrl/api/get/Filter_types/${i.toString()}').replace(
          queryParameters: {
            if (Search2.vType.isNotEmpty)
              'type[]': [
                for (var item in Search2.vType) item.toString(),
              ],
            if (Search2.type_id2.isNotEmpty)
              'vtype[]': [
                for (var item in Search2.type_id2) item.toString(),
              ],
          });
      final response = await http.get(myUrl, headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });

      if (response.statusCode == 200) {
        Iterable A = json.decode(response.body)['data'];
        filter = List<FilterData>.from(A.map((A) => FilterData.fromJson(A)));
      }
    } catch (_) {}
    return filter;
  }

  /// أكثر 10 منتجات مبيعاً في الشهر الماضي
  static Future<List<ProductData>> getTopProducts() async {
    try {
      String myUrl = "$globalUrl/api/top-products";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Top products request timeout');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] != null && jsonData['data'] is List) {
          return (jsonData['data'] as List)
              .map((item) => ProductData.fromJson(item))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<FilterData>?> editProduct(
      String name, String price, String id, context) async {
    try {
      var myUrl = '$globalUrl/api/edit/branch-product/$id';
      final response = await HttpInterceptor.post(myUrl, headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }, body: {
        'name': name,
        'price': price,
      });

      if (response.statusCode == 200) {}
    } catch (_) {}
    return filter;
  }
}
