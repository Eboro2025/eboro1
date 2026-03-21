import 'dart:convert';

import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/BranchData.dart';
import 'package:eboro/Helper/CategoryData.dart';
import 'package:eboro/Helper/OfferData.dart';
import 'package:eboro/Helper/ShippingData.dart';
import 'package:eboro/Helper/TypesData.dart';
import 'package:eboro/Helper/UserData.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;

class ProviderData {
  bool get acceptsCash => accept_cash == true;

  final int? id;
  final bool? accept_cash;
  final String? name;
  final int? vip;
  final String? rate;
  ShippingData? Delivery; // Distance
  final List<BranchData>? branch;
  final List<TypesData>? type;
  final List<TypesData>? typeInner;
  OfferData? offer; // Made non-final to allow filter updates
  final String? description;
  final String? duration;
  final String? lock;
  final CategoryData? category;
  final String? logo;
  final String? rateRatio;
  final String? rate_user;
  final UserData? user;
  final bool? has_delivery;
  final String? created_at;
  String? state;
  final String? nextOpeningTime; // أول ميعاد فتح
  Map<String, dynamic>? rawJson; // kept for lazy delivery fetch
  bool outOfDeliveryRange = false; // المحل خارج نطاق التوصيل

  ProviderData({
    this.id,
    this.name,
    this.vip,
    this.rate,
    this.Delivery,
    this.type,
    this.typeInner,
    this.offer,
    this.branch,
    this.rate_user,
    this.rateRatio,
    this.description,
    this.duration,
    this.lock,
    this.category,
    this.logo,
    this.user,
    this.has_delivery,
    this.created_at,
    this.state,
    this.nextOpeningTime,
    this.accept_cash,
  });

  static Future<ShippingData?> fetchDeliveryData(
      Map<String, dynamic> jsonMap) async {
    try {
      int id = jsonMap['id'];
      String? latStr = Auth2.user?.activeLat;
      String? longStr = Auth2.user?.activeLong;

      // لو ما فيه موقع حقيقي للمستخدم، ما نحسب التوصيل
      if (latStr == null || longStr == null || latStr.isEmpty || longStr.isEmpty) return null;
      double latVal = double.tryParse(latStr) ?? 0.0;
      double longVal = double.tryParse(longStr) ?? 0.0;
      if (latVal == 0.0 && longVal == 0.0) return null;

      // نستخدم الإحداثيات كـ string مباشرة للحفاظ على الدقة
      String myUrl = "$globalUrl/api/delivery-fees/${id}/${latStr}/${longStr}";

      final headers = <String, String>{
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
      };
      if (MyApp2.token != null && MyApp2.token!.isNotEmpty) {
        headers['Authorization'] = MyApp2.token!;
      }
      final response = await http.get(Uri.parse(myUrl), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        Map<String, dynamic> A = json.decode(response.body)
            as Map<String, dynamic>;
        String? ship = A['shipping']?.toString();

        bool success = A['success'] == true;
        if (success && ship != null && ship.isNotEmpty) {
          return ShippingData.fromJson(A);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  factory ProviderData.fromJson(Map<String, dynamic> json) {
    // Create the object without Delivery
    ProviderData provider = ProviderData(
      id: json['id'],
      name: json['name'],
      rateRatio: json['rateRatio'],
      rate_user: json['rate_user'],
      vip: json['vip'],
      has_delivery: json['has_delivery'],
      state: json['state'],
      rate: json['rate'].toString(),
      offer: json['offer'] != null && json['offer'] is Map
          ? OfferData.fromJson(json['offer'])
          : null,
      type: json['type'] != null && json['type'] is List
          ? (json['type'] as List).map((i) => TypesData.fromJson(i)).toList()
          : null,
      typeInner: json['typeInner'] != null && json['typeInner'] is List
          ? (json['typeInner'] as List)
              .map((i) => TypesData.fromJson(i))
              .toList()
          : null,
      branch: json['branch'] != null && json['branch'] is List
          ? (json['branch'] as List).map((i) => BranchData.fromJson(i)).toList()
          : null,
      description: json['description'],
      duration: json['duration'],
      lock: json['lock'],
      category: json['category'] != null
          ? CategoryData.fromJson(json['category'])
          : null,
      logo: json['logo'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      created_at: json['created_at'],
      nextOpeningTime: json['next_opening_time'],
      accept_cash: json['accept_cash'] == true || json['accept_cash'] == 1 || json['accept_cash'].toString() == '1',
    );

    provider.rawJson = json;
    return provider;
  }
}
