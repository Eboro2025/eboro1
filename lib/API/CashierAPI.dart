import 'package:eboro/Helper/ProductData.dart';
import 'package:flutter/material.dart';
import 'package:eboro/Helper/HttpInterceptor.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Helper/BranchStaffData.dart';
import '../Helper/OrderData.dart';

class CashierAPI extends StatefulWidget {
  @override
  CashierAPI2 createState() => CashierAPI2();
}

class CashierAPI2 extends State <CashierAPI> {
  static List<ProductData>? product;
  static List<BranchStaffData>? branch;
  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }


  Future<List<BranchStaffData>?> branchStaff() async {
    try{
      String myUrl = "$globalUrl/api/filter/branch-staff";
      final response = await http.post(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });
      if(response.statusCode == 200){
        Iterable A = json.decode(response.body)['data'];
        branch = List<BranchStaffData>.from(A.map((A)=> BranchStaffData.fromJson(A)));

      }
      else
      {
        // print("getCart() no data");
      }

    }catch (e) {
      // print(e);
    }
    return branch;
  }

  Future<List<OrderData>?> getOrders([id = null , branch_id = null]) async {
    List<OrderData>? order;
    // try{
      String myUrl = "$globalUrl/api/search-order";
      final response = await
      http.post(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },
     body:
     {
       if(branch_id != null)
            'branch_id': branch_id.toString(),
       if(id != null)
            'id': id.toString(),
      });
      if(response.statusCode == 200){
        Iterable A = json.decode(response.body)['data'];
        order = List<OrderData>.from(A.map((A)=> OrderData.fromJson(A)));

      }
      else
      {
        // print("getOrders() no data");
      }

    /* }catch (e) {
      // print("getOrders");
      // print(e);
    }*/
    return order;
  }

  Future<List<ProductData>?> getProducts(i) async {
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
        Iterable A = json.decode(response.body)['data'];
        product = List<ProductData>.from(A.map((A)=> ProductData.fromJson(A)));
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

  Future<bool> toggleBranchStatus(int branchId, int status) async {
    try {
      String myUrl = "$globalUrl/api/toggle-branch-status/$branchId";
      // print(">>> toggleBranchStatus: url=$myUrl status=$status token=${MyApp2.token?.substring(0, 20)}...");
      final response = await http.post(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }, body: {
        'status': status.toString(),
      });
      // print(">>> toggleBranchStatus: response code=${response.statusCode} body=${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}");
      return response.statusCode == 200;
    } catch (e) {
      // print(">>> toggleBranchStatus() error: $e");
      return false;
    }
  }

  /// Fetch branch status for shop owner
  Future<Map<String, dynamic>?> getMyBranches() async {
    try {
      String myUrl = "$globalUrl/api/my-branches";
      final response = await http.get(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] as List? ?? [];
        if (list.isNotEmpty) {
          return {
            'name': list[0]['name'] ?? '',
            'status': list[0]['status'] ?? 'close',
            'id': list[0]['id'],
          };
        }
      }
    } catch (e) {
      // print("getMyBranches() error: $e");
    }
    return null;
  }

  editProducts(String name, String price, String id , String start_outofstock, String end_outofstock, context) async {
    try{
      String myUrl = '$globalUrl/api/edit/branch-product/$id';
      final response = await HttpInterceptor.post(myUrl, headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },body: {
        'name' : name,
        'price' : price,
        'start_outofstock' : start_outofstock,
        'end_outofstock' : end_outofstock,
      });

      if(response.statusCode == 200){ }
      else
      { }

    }catch (e) {
      // print(e);
    }
  }
}