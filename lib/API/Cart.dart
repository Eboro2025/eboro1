import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/CartData.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

//a
class Cart {
  Future<CartData?> getCart() async {
    CartData? cart;

    try {
      String myUrl = "$globalUrl/api/user-cart";
      final response = await http.get(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseBody = response.body.trim();

          if (!responseBody.endsWith('}') && !responseBody.endsWith(']')) {
            return null;
          }

          final responseData = json.decode(responseBody);

          if (responseData is Map && responseData.containsKey('data')) {
            Map<String, dynamic> A = responseData['data'];
            cart = CartData.fromJson(A);
          }
        } catch (_) {}
      }
    } catch (_) {}
    return cart;
  }

  Future<String> restCartItem(context) async {
    try {
      final cart = Provider.of<CartTextProvider>(context, listen: false);
      String myUrl = "$globalUrl/api/rest-cart-item/";
      final response = await http.get(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });

      if (response.statusCode == 200) {
        cart.updateCart();
      }
    } catch (_) {}
    return "Cart was rest";
  }

  Future<String> deleteCartItem(id, context) async {
    try {
      String myUrl = "$globalUrl/api/delete-cart-item/" + id.toString();
      final response = await http.get(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });

      if (response.statusCode == 200) {
        Map B = json.decode(response.body);
        if (B['errors'] != null) Auth2.show(B['errors'].toString());
        if (B['message'] != null) Auth2.show(B['message'].toString());
      }
    } catch (_) {}
    return "The Item was deleted successfully ";
  }

  Future<String> addToCart(extrasIDs, id, _itemCount) async {
    try {
      String myUrl = "$globalUrl/api/add-cart";

      final Map<String, String> requestBody = {};

      // تحويل extrasIDs لـ List لو كان String مفصول بفاصلة
      List<String> extrasList = [];
      if (extrasIDs != null && extrasIDs.toString().isNotEmpty) {
        if (extrasIDs is String) {
          extrasList = extrasIDs.split(',').map((e) => e.trim()).toList();
          extrasList.removeWhere((e) => e.isEmpty);
        } else if (extrasIDs is List) {
          extrasList = extrasIDs.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        }
      }

      // إضافة الـ extras بصيغة extras[0], extras[1], etc. (لـ Laravel)
      if (extrasList.isNotEmpty) {
        for (var i = 0; i < extrasList.length; i++) {
          requestBody['extras[$i]'] = extrasList[i];
        }
      }

      requestBody['qty'] = _itemCount.toString();
      requestBody['product_id'] = id.toString();

      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': "${MyApp2.token}",
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        Map B = json.decode(response.body);
        if (B['errors'] != null) Auth2.show(B['errors'].toString());
      }
    } catch (_) {}
    return "The item was added successfully";
  }
}
