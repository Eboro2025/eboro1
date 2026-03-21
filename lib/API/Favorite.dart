import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/FavoriteData.dart';
import 'package:flutter/material.dart';
import 'package:eboro/Helper/HttpInterceptor.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class Favorite extends StatefulWidget {
  @override
  Favorite2 createState() => Favorite2();
}

class Favorite2 extends State<Favorite> {

  static List<FavoriteData>? favorite;

  static const String _cacheKey = 'favorites_cache';

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

  /// Load favorites from local cache
  static Future<List<FavoriteData>?> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached == null || cached.isEmpty) return null;
      final List<dynamic> jsonList = json.decode(cached);
      favorite = jsonList
          .map((j) => FavoriteData.fromJson(j as Map<String, dynamic>))
          .toList();
      return favorite;
    } catch (_) {
      return null;
    }
  }

  /// Save favorites to local cache
  static Future<void> saveToCache(List<FavoriteData>? favorites) async {
    if (favorites == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = favorites
          .where((f) => f.provider?.rawJson != null)
          .map((f) => f.toJson())
          .toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
    } catch (_) {}
  }

  static Future<List<FavoriteData>?> getFavorite() async {
    try {
      String myUrl = "$globalUrl/api/user-favorite";
      final response = await http.get(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });

      if (response.statusCode == 200) {
        Iterable data = json.decode(response.body)['data'];
        favorite = List<FavoriteData>.from(
            data.map((item) => FavoriteData.fromJson(item)));
        // Save to local cache
        saveToCache(favorite);
      }
    } catch (_) {}
    return favorite;
  }

  static Future<bool> removeFromFavorite(i, context) async {
    try {
      String myUrl = "$globalUrl/api/add-to-favorite";

      final response = await HttpInterceptor.post(myUrl, headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }, body: {
        'provider_id': i.toString(),
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static show(String message, context) async {
    Auth2.show(message);
  }
}
