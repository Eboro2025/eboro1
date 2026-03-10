import 'package:eboro/API/Categories.dart';
import 'package:eboro/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;

import 'package:url_launcher/url_launcher_string.dart';

class Aboutus extends StatefulWidget {
  @override
  Aboutus2 createState() => Aboutus2();
}

class Aboutus2 extends State<Aboutus> {
  String?it, en;
  int? selectedRadio;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Categories2.getAbouts();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        title: Text("About",
            style: TextStyle(color: Colors.white, fontSize: MyApp2.fontSize20)),
        iconTheme: new IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 30),
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    semanticContainer: true,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(20,20,10,20),
                          child: RichText(
                              text: TextSpan(children: <InlineSpan>[
                                WidgetSpan(
                                  alignment: ui.PlaceholderAlignment.middle,
                                  child: Icon(Icons.phone, color: myColor, size: 40),
                                ),
                                TextSpan(
                                    style: TextStyle(
                                      fontSize: MyApp2.fontSize20,
                                      color: Color(0xFF515C6F),
                                    ),
                                    text: "${Categories2.Abouts.phone}",
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        final Uri launchUri = Uri(
                                          scheme: 'tel',
                                          path: "${Categories2.Abouts.phone}",
                                        );
                                        await launchUrl(launchUri);
                                      }
                                ),
                              ])),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    semanticContainer: true,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(20,20,10,20),
                          child: RichText(
                              text: TextSpan(children: <InlineSpan>[
                                WidgetSpan(
                                  alignment: ui.PlaceholderAlignment.middle,
                                child: Icon(Icons.email, color: myColor, size: 40),
                                ),
                                TextSpan(
                                    style: TextStyle(
                                      fontSize: MyApp2.fontSize20,
                                      color: Color(0xFF515C6F),
                                    ),
                                  text: " ${Categories2.Abouts.email}",
                                    recognizer: TapGestureRecognizer()
                                     ..onTap = () =>
                                      launchUrlString("mailto:${Categories2.Abouts.email}?subject=Eboro Support")
                                      ),
                              ])),
                        ),
                      ],
                    ),
                  ),


                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

}
