import 'package:eboro/Client/Contact%20Us/Contact.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class Contacts extends StatefulWidget {
  @override
  Contacts2 createState() => Contacts2();
}

class Contacts2 extends State <Contacts> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        title: Text(AppLocalizations.of(context)!.translate("mycontacts"), style: TextStyle( color: Colors.white, fontSize: MyApp2.fontSize20)),
        iconTheme: new IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: EdgeInsets.only(left: 10, right: 10, top: 5),
        children: <Widget>[
          ListView.builder(
            physics: ClampingScrollPhysics(),
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: 1,
            itemBuilder: (ctx, i) => Contact(),
          ),
        ],
      ),
    );
  }

}

