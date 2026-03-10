
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/AboutData.dart';
import 'package:eboro/Helper/CategoryData.dart';
import 'package:eboro/Helper/JsonHelper.dart';
import 'package:flutter/material.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Auth/Signin.dart';
import '../Providers/AllProviders.dart';

class Categories extends StatefulWidget {
  @override
  Categories2 createState() => Categories2();
}
//a
class Categories2 extends State <Categories> {

  static List<CategoryData>? categories;
  static late AboutData Abouts;

  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }


  static Future<void> getCategories() async {
    try {
      String myUrl = "$globalUrl/api/get/categories";

      final response = await http.get(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang ?? 'it',
        'Accept': 'application/json',
        'Authorization': MyApp2.token ?? "",
      });

      if (response.statusCode == 200) {
        Iterable A = json.decode(response.body)['data'];
        categories =
            List<CategoryData>.from(A.map((A) => CategoryData.fromJson(A)));
      }
    } catch (_) {}
  }

  static delete_user(context) async {
    String myUrl = "$globalUrl/api/delete-user/"+Auth2.user!.id.toString();

    http.get(Uri.parse(myUrl), headers: {
      'apiLang' : MyApp2.apiLang??'it',
      'Accept': 'application/json',
      'Authorization': MyApp2.token??"",
    }).then((response) async {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }


  static getGuestCategories({bool flag =false,context}) async {
    String myUrl = "$globalUrl/api/get/categories";

    http.get(Uri.parse(myUrl), headers: {
      'apiLang' : MyApp2.apiLang??'it',
      'Accept': 'application/json',
      'Authorization': MyApp2.token??"",
    }).then((response) async {
      Iterable A = json.decode(response.body)['data'];
      categories = List<CategoryData>.from(A.map((A)=> CategoryData.fromJson(A)));
      if(flag)
      {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AllProviders(catID: null, name: null)),
        );
      }
    });
  }


  static Future<void> getAbouts() async {
    try{
      String myUrl = "$globalUrl/api/setting-details";
      final response = await http.get(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
      });

      if(response.statusCode == 200){
        try {
          String fixedJson = fixBrokenJson(response.body);
          Map<String , dynamic> A = json.decode(fixedJson);
          Abouts = AboutData.fromJson(A);
        } catch (_) {}
      }

    }catch (_) {}
  }
}
