import 'package:eboro/Helper/ProductData.dart';
import 'package:eboro/Helper/UserData.dart';
import 'package:eboro/Helper/JsonHelper.dart';
import 'package:flutter/material.dart';
import 'package:eboro/main.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Helper/OrderData.dart';
//a
class DeliveryAPI extends StatefulWidget {
  @override
  DeliveryAPI2 createState() => DeliveryAPI2();
}

class DeliveryAPI2 extends State <DeliveryAPI> {
  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }


  Future<List<OrderData>?> deliveryOrder() async {
    List<OrderData>? delivery;
    try{
      String myUrl = "$globalUrl/api/delivery-for-order";
      final response = await http.post(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });
      if(response.statusCode == 200){
        Iterable A = json.decode(response.body)['data'];
        delivery = List<OrderData>.from(A.map((A)=> OrderData.fromJson(A)));
        // print('delivery Orders Length :' + delivery.length.toString());

      }
      else
      {
        // print("no data");
      }

    }catch (e) {
      // print(e);
    }
    return delivery;
  }
  Future<UserData?> editLocation() async {
    UserData? delivery;
    try{
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      String droLat = position.latitude.toString();
      String dropLong = position.longitude.toString();
      String myUrl = "$globalUrl/api/edit-profile";
      final response = await http.post(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },body: {
        'lat': droLat,
        'long': dropLong,
        // "lat": "45.4918469",
        // "long": "9.1919609",
      }
      );
      if(response.statusCode == 200){
        Map<String, dynamic> A = json.decode(response.body)['data'];
        delivery = UserData.fromJson(A);
      }
      else
      {
        // print("no data");
      }

    }catch (e) {
      // print(e);
    }
    return delivery;
  }



  Future<List<OrderData>?> getOrders([id = null , branch_id = null , delivery_id = null]) async {
    List<OrderData>? order;
    try{
      String myUrl = "$globalUrl/api/search-order";
      final response = await
      http.post(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },
          body:
          {
            if(delivery_id != null)
              'delivery_id': delivery_id.toString(),
            if(branch_id != null)
              'branch_id': branch_id.toString(),
            if(id != null)
              'id': id.toString(),
          });
      if(response.statusCode == 200){
        final fixedJson = fixBrokenJson(response.body);
        Iterable A = json.decode(fixedJson)['data'];
        order = List<OrderData>.from(A.map((A)=> OrderData.fromJson(A)));

      }
      else
      {
        // print("getOrders() no data");
      }

    }catch (e) {
      // print(e);
    }
    return order;
  }

  /// تنبيه الزبون ان السائق قريب (100 متر)
  Future<void> notifyCustomerNearby(String orderId) async {
    try {
      String myUrl = "$globalUrl/api/order/notify-approaching";
      await http.post(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }, body: {
        'order_id': orderId,
      });
    } catch (_) {}
  }

  Future<List<ProductData>?> getProducts(i, context) async {
    List<ProductData>? product;
    try{
      String myUrl = "$globalUrl/api/filter/branch-product";
      final response = await http.post(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },body: {
        'provider_id': i.toString(),
      });
      if(response.statusCode == 200){
        final fixedJson = fixBrokenJson(response.body);
        Iterable A = json.decode(fixedJson)['data'];
        product = List<ProductData>.from(A.map((A)=> ProductData.fromJson(A)));
        // print('All products Length : ' + product.length.toString());
      }
      else
      {
        // print("getProducts() no data");
      }

    }catch (e) {
      // print(e);
    }
    return product;
  }

}