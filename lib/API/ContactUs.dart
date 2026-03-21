import 'package:eboro/API/Auth.dart';
import 'package:eboro/Client/Contact%20Us/Contacts.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:flutter/material.dart';
import 'package:eboro/Helper/HttpInterceptor.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eboro/Helper/ContactsData.dart';


class ContactUsAPI {
  static late List<ContactsData> contact;
//a
  getContacts(context) async {
    Progress.progressDialogue(context);
    String myUrl = "$globalUrl/api/user/contact";
    http.get(Uri.parse(myUrl), headers: {
      'apiLang' : MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    }).then((response) async {
      Progress.dimesDialog(context);
      Iterable? A = json.decode(response.body)['data'];
      contact = List<ContactsData>.from(A!.map((A)=> ContactsData.fromJson(A)));
      Navigator.push(context, MaterialPageRoute(builder: (context) => Contacts()));
    });
  }

  writeContact(String email, String phone, String name, String topic, String message, context, {String? base64Image, String? fileNames}) async {
    Progress.progressDialogue(context);
    String myUrl = "$globalUrl/api/contact-us";
    HttpInterceptor.post(myUrl, headers: {
      'apiLang' : MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    }, body: {
      'email': email,
      'phone': phone,
      'name': name,
      'subject' : topic,
      'message' : message,
      if (base64Image != null) 'base64Image': base64Image,
      if (base64Image != null) 'fileNames': fileNames,
      if (base64Image != null) 'flag': 'json',
    }).then((response) async {
      Progress.dimesDialog(context);
      Map A =  json.decode(response.body);
      if(A['errors'] != null)
        Auth2.show(A['errors'].toString());
      if(A['message'] != null)
        Auth2.show(A['message'].toString());
      if(A['status'] == "success") {
        getContacts(context);
      }
    });
  }
}