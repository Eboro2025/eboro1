import 'dart:async';
import 'dart:convert';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/ChatData.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class chatDelivery extends StatefulWidget {
  @override
  chatDelivery2 createState() => chatDelivery2();
}

class chatDelivery2 extends State <chatDelivery> {

  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }



  Future<List<ChatData>?> getChats(id) async {
    List<ChatData>? ChatValues;
    try{
      String myUrl = "$globalUrl/api/get/delivery/chat/" + id.toString();
      final response = await
      http.get(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });
      // print(response.body);
      if(response.statusCode == 200)
      {
        Iterable A = json.decode(response.body)['data'];
        ChatValues = List<ChatData>.from(A.map((A)=> ChatData.fromJson(A)));
      }
      else
      {
        // print("no data");
      }

    }catch (e) {
      // print(e);
    }
    return ChatValues;
  }

  Future<void> addChat(_message , id) async {
    try{
      String myUrl = "$globalUrl/api/add/chat/delivery";
      final response = await  http.post(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },body: {
        'order_id' : id.toString(),
        'user_id' : Auth2.user!.id.toString(),
        'text' : _message.toString()
      });
      if(response.statusCode == 200)
      {
        // print("update");
      }
      else
      {
        // print("no data");
      }

    }catch (e) {
      // print(e);
    }
  }

}