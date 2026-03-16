import 'package:eboro/API/Auth.dart';
import 'package:eboro/Client/CheckOut.dart';
import 'package:eboro/Client/SuccessfulOrder.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:flutter/material.dart';
import 'package:eboro/main.dart';
import 'package:eboro/Helper/JsonHelper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:provider/provider.dart';

// إصلاح JSON الفاسد من Orders API
String fixOrdersJson(String jsonStr) {
  // إصلاح علامات الاقتباس الزيادة في الأرقام: ":123" → ":123
  jsonStr = jsonStr.replaceAllMapped(
    RegExp(r'":(\d+)"'),
    (match) => '":${match.group(1)}',
  );

  // إصلاح علامات الاقتباس المزدوجة في النصوص: ":"text"" → ":"text"
  jsonStr = jsonStr.replaceAllMapped(
    RegExp(r'":"([^"]*?)""'),
    (match) => '":"${match.group(1)}"',
  );

  // إصلاح علامات الاقتباس الزيادة في null: ":null" → ":null
  jsonStr = jsonStr.replaceAll('":null"', '":null');

  // إصلاح الأخطاء الأخرى
  return jsonStr
      .replaceAll('"name:"', '"name":"') // "name:"Sauces" → "name":"Sauces"
      .replaceAll('"payment:"', '"payment":"') // "payment:"0" → "payment":"0"
      .replaceAll(',name":', ',"name":') // {id:185,name" → {id:185,"name"
      .replaceAll('"Delivery_Price":"1",6"', '"Delivery_Price":"1.6"')
      .replaceAll('"Salsa Ktchup,"', '"Salsa Ktchup"');
}

class Order extends StatefulWidget {
  @override
  Order2 createState() => Order2();
}

class Order2 extends State<Order> {
  // static List<OrderData> order;
  static Map<String, dynamic>? B;

  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

  Future<bool> vOrder(String order_id, String date) async {
    try {
      String myUrl = "$globalUrl/api/edit-order";
      final response = await http.post(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }, body: {
        'ordar_at': date,
        'order_id': order_id,
        'status': 'pending',
      });
      // response handled
    } catch (_) {}
    return true;
  }

  Future<bool> makeOrder(context,
      {String card = "",
      String exp = "",
      String cvv = "",
      String? date = "",
      String? type = "1",
      comment = "",
      gratuity = "",
      options = "",
      posate = true,
      String? transactionId}) async {
    try {
      // التحقق من البيانات الأساسية
      if (Auth2.user?.activeLat == null || Auth2.user?.activeLong == null) {
        Auth2.show("Location data is missing. Please set your location.");
        try {
          Navigator.pop(context);
        } catch (_) {} // إغلاق Progress dialog
        return false;
      }

      if (date == null || date.isEmpty || date == "null") {
        Auth2.show("Please select delivery date and time");
        try {
          Navigator.pop(context);
        } catch (_) {} // إغلاق Progress dialog
        return false;
      }

      String myUrl = "$globalUrl/api/add-new-order";

      // إعداد البيانات المرسلة
      Map<String, String> requestBody = {
        "drop_lat": "${Auth2.user?.activeLat ?? ''}",
        "drop_long": "${Auth2.user?.activeLong ?? ''}",
        "drop_address": "${Auth2.user?.activeAddress ?? ''}",
        "payment": type ?? "0",
        "flag": "json",
        "ordar_at": date ?? ""
      };

      // إضافة البيانات الاختيارية فقط إذا كانت موجودة
      if (options != null && options.toString().isNotEmpty && options != "") {
        requestBody["options"] = options.toString();
      }
      if (gratuity != null &&
          gratuity.toString().isNotEmpty &&
          gratuity != "") {
        requestBody["gratuity"] = gratuity.toString();
      }
      if (comment != null && comment.toString().isNotEmpty && comment != "") {
        requestBody["comment"] = comment.toString();
      }
      if (posate != null) {
        requestBody["posate"] = posate ? "1" : "0";
      }
      if ((type == '1' || type == '3' || type == '4') &&
          transactionId != null &&
          transactionId.isNotEmpty) {
        requestBody["transaction_id"] = transactionId;
      }

      debugPrint('🔵 [makeOrder] URL: $myUrl');
      debugPrint('🔵 [makeOrder] Payment type: $type');
      debugPrint('🔵 [makeOrder] Full request body: $requestBody');

      final response = await http.post(Uri.parse(myUrl),
          headers: {
            'apiLang': MyApp2.apiLang.toString(),
            'Accept': 'application/json',
            'Authorization': "${MyApp2.token}",
          },
          body: requestBody);

      debugPrint('🔵 [makeOrder] Response status: ${response.statusCode}');
      debugPrint('🔵 [makeOrder] Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map? A = json.decode(response.body);

        debugPrint('🔵 [makeOrder] Parsed response: $A');
        debugPrint('🔵 [makeOrder] Payment type: $type');

        if (type == "2" && A.toString().contains("paypal")) {
          debugPrint('🔵 [makeOrder] PayPal link: ${A?['link']}');
          // إغلاق Progress dialog أولاً قبل فتح PayPal WebView
          try {
            Navigator.pop(context);
          } catch (_) {}
          // فتح PayPal مع الحفاظ على الصفحات السابقة (نستخدم push بدلاً من pushAndRemoveUntil)
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => WebViewClass(link: A?['link'])));
          return true;
        } else if (type == "2") {
          // PayPal لكن ما فيه رابط paypal - يعني فيه خطأ
          debugPrint(
              '🔴 [makeOrder] PayPal error - no paypal link in response: $A');
          String errorMsg = A?['link']?['original']?['message'] ??
              A?['message'] ??
              A?['data']?['message'] ??
              "PayPal error";
          try {
            Navigator.pop(context);
          } catch (_) {}
          Auth2.show(errorMsg);
          return false;
        } else if (A.toString().isNotEmpty) {
          if (A.toString().contains('Done') || A.toString().contains('Fatto')) {
            // تفريغ الـ Cart بعد نجاح الطلب
            final cart = Provider.of<CartTextProvider>(context, listen: false);
            await cart.clearCart(context);
            // إزالة جميع الصفحات (MyCart + Progress dialog + Bottom sheet) ثم فتح صفحة النجاح
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => SuccessfulOrder()),
                (route) => false);
            return true;
          } else {
            String errorMsg =
                A?['link']?['original']?['message'] ?? A?['message'] ?? "error";
            try {
              Navigator.pop(context);
            } catch (_) {} // إغلاق Progress dialog
            Auth2.show(errorMsg);
            return false;
          }
        } else {
          try {
            Navigator.pop(context);
          } catch (_) {} // إغلاق Progress dialog
          Auth2.show("Empty response from server");
          return false;
        }
      } else if (response.statusCode == 403) {
        // Alcohol age verification - codice fiscale required
        String errorMsg = "Accesso negato";
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map) {
            errorMsg = errorData['message'] ?? errorMsg;
          }
        } catch (_) {}

        try {
          Navigator.pop(context);
        } catch (_) {}

        // Show dialog to enter codice fiscale
        if (context.mounted) {
          await _showCodiceFiscaleDialog(context, errorMsg);
        }
        return false;
      } else if (response.statusCode == 500) {
        // محاولة استخراج رسالة الخطأ من الـ response
        String errorMsg = "Server error (500). Please try again later.";
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map) {
            errorMsg = errorData['message'] ??
                errorData['error'] ??
                errorData['errors']?.toString() ??
                errorMsg;
          }
        } catch (_) {}

        Auth2.show(errorMsg);
        try {
          Navigator.pop(context);
        } catch (_) {} // إغلاق Progress dialog
        return false;
      } else {
        // محاولة استخراج رسالة الخطأ
        String errorMsg = "Server error (${response.statusCode})";
        try {
          final errorData = json.decode(response.body);
          debugPrint(
              '🔴 [makeOrder] Error response (${response.statusCode}): $errorData');
          if (errorData is Map) {
            // Laravel 422 validation errors
            if (errorData['errors'] != null && errorData['errors'] is Map) {
              final errors = errorData['errors'] as Map;
              final allErrors =
                  errors.values.expand((v) => v is List ? v : [v]).join('\n');
              errorMsg = allErrors.isNotEmpty
                  ? allErrors
                  : (errorData['message'] ?? errorMsg);
              debugPrint('🔴 [makeOrder] Validation errors: $errors');
            } else {
              errorMsg = errorData['message'] ?? errorData['error'] ?? errorMsg;
            }
          }
        } catch (e) {
          debugPrint('🔴 [makeOrder] Error parsing response: $e');
        }

        Auth2.show(errorMsg);
        try {
          Navigator.pop(context);
        } catch (_) {} // إغلاق Progress dialog
        return false; // فشل الطلب
      }
    } catch (e) {
      Auth2.show("Error: $e");
      try {
        Navigator.pop(context);
      } catch (_) {} // إغلاق Progress dialog
      return false; // فشل الطلب
    }
  }

  Future<void> _showCodiceFiscaleDialog(BuildContext context, String message) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Verifica Età', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 16,
              style: TextStyle(fontFamily: 'monospace', fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Codice Fiscale',
                hintText: 'RSSMRA85M01H501Z',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: myColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final cf = controller.text.trim().toUpperCase();
              if (cf.length != 16) {
                Auth2.show('Il Codice Fiscale deve essere di 16 caratteri');
                return;
              }
              Navigator.pop(ctx);
              // Save codice fiscale via API
              await Auth2.editUserDetails(
                null, null, null, null, null, null, null, null, null,
                context,
                codiceFiscale: cf,
              );
              Auth2.show('Codice Fiscale salvato. Riprova l\'ordine.');
            },
            child: Text('Salva', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<List<OrderData>?> getOrders([id = null, branch_id = null]) async {
    List<OrderData>? order;

    if (Auth2.user == null) {
      return [];
    }

    try {
      String myUrl = "$globalUrl/api/search-order";
      final response = await http.post(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }, body: {
        'user_id': Auth2.user!.id.toString(),
        if (branch_id != null) 'branch_id': branch_id.toString(),
        if (id != null) 'id': id.toString(),
      });

      if (response.statusCode == 200) {
        try {
          // محاولة parse مباشرة بدون تصليح
          try {
            var decoded = json.decode(response.body);
            Iterable A = decoded['data'];
            order = List<OrderData>.from(A.map((A) => OrderData.fromJson(A)));
            return order;
          } catch (_) {
            // Direct parse failed, trying with fixes
          }

          // إصلاح JSON الفاسد
          String jsonBody = fixBrokenJson(response.body);
          jsonBody = fixOrdersJson(jsonBody);

          // محاولة parse بعد التصليح
          try {
            var decoded = json.decode(jsonBody);
            Iterable A = decoded['data'];

            order = [];
            for (var orderJson in A) {
              try {
                order.add(OrderData.fromJson(orderJson));
              } catch (_) {}
            }
          } catch (_) {
            // محاولة أخيرة: استخراج orders يدوياً
            order = _extractOrdersManually(jsonBody);
            if (order == null || order!.isEmpty) {
              order = [];
            }
          }
        } catch (_) {
          order = [];
        }
      } else {
        order = [];
      }
    } catch (_) {
      order = [];
    }
    return order;
  }

  List<OrderData>? _extractOrdersManually(String jsonBody) {
    try {
      // محاولة استخراج كل order object بشكل منفصل
      final orders = <OrderData>[];

      // البحث عن بداية data array
      final dataMatch = RegExp(r'"data"\s*:\s*\[').firstMatch(jsonBody);
      if (dataMatch == null) {
        return null;
      }

      int startPos = dataMatch.end;
      int braceCount = 0;
      int orderStart = -1;

      for (int i = startPos; i < jsonBody.length; i++) {
        final char = jsonBody[i];

        if (char == '{') {
          if (braceCount == 0) {
            orderStart = i;
          }
          braceCount++;
        } else if (char == '}') {
          braceCount--;
          if (braceCount == 0 && orderStart >= 0) {
            // وجدنا order كامل
            final orderJson = jsonBody.substring(orderStart, i + 1);
            try {
              final orderData = OrderData.fromJson(json.decode(orderJson));
              orders.add(orderData);
            } catch (_) {}
            orderStart = -1;
          }
        } else if (char == ']' && braceCount == 0) {
          // نهاية الـ array
          break;
        }
      }

      return orders.isEmpty ? null : orders;
    } catch (_) {
      return null;
    }
  }

  Future<OrderData?> Rate(id, value, comment) async {
    String myUrl = "$globalUrl/api/add-order-rate";
    http.post(Uri.parse(myUrl), headers: {
      'apiLang': MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    }, body: {
      'order_id': "${id}",
      'value': "${value}",
      'comment': "${comment}",
    }).then((response) async {});
    return null;
  }

  Future<OrderData?> editOrder(String status, String order_id, String? reason,
      {int? deliveryTime}) async {
    OrderData? order;

    String myUrl = "$globalUrl/api/edit-order";
    final response = await http.post(Uri.parse(myUrl), headers: {
      'apiLang': MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    }, body: {
      'status': status,
      'order_id': order_id,
      'refuse_reason': reason ?? '',
      if (deliveryTime != null) 'Delivery_time': deliveryTime.toString(),
    });
    B = json.decode(response.body);
    if (response.statusCode == 200) {
      order = OrderData.fromJson(B!);
    }

    return order;
  }

  /// Confirm delivery with verification code
  Future<Map<String, dynamic>> confirmDeliveryCode(
      String orderId, String deliveryCode) async {
    String myUrl = "$globalUrl/api/order/confirm-delivery";
    final response = await http.post(Uri.parse(myUrl), headers: {
      'apiLang': MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    }, body: {
      'order_id': orderId,
      'delivery_code': deliveryCode,
    });
    return json.decode(response.body);
  }

  /// Request refund for an order (with optional image proof)
  Future<Map<String, dynamic>> requestRefund(
      String orderId, String reason, String? description,
      {File? imageFile}) async {
    String myUrl = "$globalUrl/api/order/request-refund";

    if (imageFile != null) {
      // Multipart request with image
      var request = http.MultipartRequest('POST', Uri.parse(myUrl));
      request.headers.addAll({
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });
      request.fields['order_id'] = orderId;
      request.fields['reason'] = reason;
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return json.decode(response.body);
    } else {
      // Simple POST without image
      final response = await http.post(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }, body: {
        'order_id': orderId,
        'reason': reason,
        if (description != null && description.isNotEmpty)
          'description': description,
      });
      return json.decode(response.body);
    }
  }

  /// Upload delivery proof photo with GPS location
  Future<Map<String, dynamic>> uploadDeliveryProof(
      String orderId, File imageFile, double lat, double lng) async {
    String myUrl = "$globalUrl/api/order/upload-delivery-proof";

    var request = http.MultipartRequest('POST', Uri.parse(myUrl));
    request.headers.addAll({
      'apiLang': MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    });

    request.fields['order_id'] = orderId;
    request.fields['lat'] = lat.toString();
    request.fields['long'] = lng.toString();

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return json.decode(response.body);
  }
}
