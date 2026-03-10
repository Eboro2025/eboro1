import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/FavoriteData.dart';
import 'package:flutter/material.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class Favorite extends StatefulWidget {
  @override
  Favorite2 createState() => Favorite2();
}
//a
class Favorite2 extends State <Favorite> {

  static List<FavoriteData>? favorite;

  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }


  static Future<List<FavoriteData>?> getFavorite() async {
    try{
      String myUrl = "$globalUrl/api/user-favorite";
      final response = await http.get(Uri.parse(myUrl),headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });

      if(response.statusCode == 200)
      {
        Iterable A = json.decode(response.body)['data'];
        favorite = List<FavoriteData>.from(A.map((A)=> FavoriteData.fromJson(A)));
      }
      else
      {
        // print("Favorite() no data");
      }

    }catch (e) {
      // print(e);
    }
    return favorite;
  }

  static Future<bool> removeFromFavorite(i, context) async {
    try {
      String myUrl = "$globalUrl/api/add-to-favorite";
      // print('🔄 Toggle favorite for provider: $i');
      // print('🔗 URL: $myUrl');
      // print('🔑 Token: ${MyApp2.token?.substring(0, 20)}...');

      final response = await http.post(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }, body: {
        'provider_id': i.toString(),
      });

      // print('📡 Response status: ${response.statusCode}');
      // print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        // print('✅ Favorite toggled successfully: $jsonData');
        return true;
      } else {
        // print("❌ Favorite failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      // print('❌ Favorite error: $e');
      return false;
    }
  }


  static show (String message, context) async {
    Auth2.show(message);
  }
}