import 'package:eboro/Helper/OfferData.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OfferAPI {
  
  /// جلب كل العروض النشطة
  static Future<List<OfferData>?> getActiveOffers() async {
    try {
      String myUrl = "$globalUrl/api/offers/active";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
      );
      
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<OfferData> offers = [];
        
        if (jsonData['data'] != null) {
          for (var item in jsonData['data']) {
            offers.add(OfferData.fromJson(item));
          }
        }
        
        return offers;
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }
  
  /// جلب عروض التوصيل المجاني
  static Future<List<OfferData>?> getFreeDeliveryOffers() async {
    try {
      String myUrl = "$globalUrl/api/offers/free-delivery";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
      );
      
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<OfferData> offers = [];
        
        if (jsonData['data'] != null) {
          for (var item in jsonData['data']) {
            offers.add(OfferData.fromJson(item));
          }
        }
        
        return offers;
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }
  
  /// جلب عروض 2x1
  static Future<List<OfferData>?> getTwoForOneOffers() async {
    try {
      String myUrl = "$globalUrl/api/offers/two-for-one";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
      );
      
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<OfferData> offers = [];
        
        if (jsonData['data'] != null) {
          for (var item in jsonData['data']) {
            offers.add(OfferData.fromJson(item));
          }
        }
        
        return offers;
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }
  
  /// جلب عروض خصم
  static Future<List<OfferData>?> getDiscountOffers() async {
    try {
      String myUrl = "$globalUrl/api/offers/discount";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
      );
      
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<OfferData> offers = [];
        
        if (jsonData['data'] != null) {
          for (var item in jsonData['data']) {
            offers.add(OfferData.fromJson(item));
          }
        }
        
        return offers;
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }
  
  /// جلب عروض فرع معين
  static Future<List<OfferData>?> getOffersByBranch(int branchId) async {
    try {
      String myUrl = "$globalUrl/api/offers/branch/$branchId";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
      );
      
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        List<OfferData> offers = [];
        
        if (jsonData['data'] != null) {
          for (var item in jsonData['data']) {
            offers.add(OfferData.fromJson(item));
          }
        }
        
        return offers;
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }
  
  /// التحقق من كود العرض
  static Future<Map<String, dynamic>?> validateOfferCode(String code) async {
    try {
      String myUrl = "$globalUrl/api/offers/validate";
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
        body: {
          'code': code,
        },
      );
      
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
