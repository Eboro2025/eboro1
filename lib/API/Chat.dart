import 'dart:io';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/ChatData.dart';
import 'package:flutter/material.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//a
class Chat extends StatefulWidget {
  @override
  Chat2 createState() => Chat2();
}

class Chat2 extends State <Chat> {


  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }


  Future<List<ChatData>?> getChat(i) async {
    List<ChatData>? chat;
    try{
      String myUrl = "$globalUrl/api/get/chat/" + i.toString();
      final response = await
      http.get(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });
      // // print(response.body);
      if(response.statusCode == 200){
        Iterable A = json.decode(response.body)['data'];
        chat = List<ChatData>.from(A.map((A)=> ChatData.fromJson(A)));
      }
      else
      {
        // print("no data");
      }

    }catch (e) {
      // print(e);
    }
    return chat;
  }

  Future<String> addChat(i, _message, context, {File? imageFile}) async {
    try{
      String myUrl = "$globalUrl/api/add/chat";
      final body = <String, String>{
        'order_id' : i.toString(),
        'user_id' : Auth2.user!.id.toString(),
        'text' : (_message ?? '').toString(),
      };

      // Attach base64 image if provided
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        body['base64Image'] = base64Encode(bytes);
        body['fileNames'] = imageFile.path.split('.').last;
      }

      final response = await
      http.post(Uri.parse(myUrl), headers: {
        'apiLang' : MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': MyApp2.token.toString(),
      },body: body);
      // // print(response.body);
      if(response.statusCode == 200){
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OrderChat(id: i)));
        // print("done");
      }
      else
      {
        // print("no data");
      }

    }catch (e) {
      // print(e);
    }
    return "done";
  }

}