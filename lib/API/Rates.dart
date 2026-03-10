import 'package:flutter/material.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eboro/Helper/ProviderRateData.dart';

class Rates extends StatefulWidget {
  @override
  Rates2 createState() => Rates2();
}

//a
class Rates2 extends State<Rates> {
  static List<ProviderRateData>? rate;

  @override
  initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

  static getRates() async {
    try {
      String myUrl = "$globalUrl/api/user-Rates";
      http.get(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      }).then((response) async {
        var jsonData = json.decode(response.body);
        if (jsonData['data'] != null) {
          Iterable A = jsonData['data'];
          rate = List<ProviderRateData>.from(
              A.map((A) => ProviderRateData.fromJson(A)));
        }
      });
    } catch (error) {
      // print('❌ getRates error: $error');
    }
  }

  static rateProvider(value, comment, id, context) async {
    String myUrl = "$globalUrl/api/add-to-Rate";
    http.post(Uri.parse(myUrl), headers: {
      'apiLang': MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    }, body: {
      'provider_id': "${id}",
      'value': "${value}",
      'comment': "${comment}"
    }).then((response) async {
      getRates();
      // print("Ratesfsfds${response.body} : ${id}");
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProviderScreen(catID: widget.catID,name: widget.name,)));
    });
  }
}
