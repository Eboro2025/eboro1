import 'package:eboro/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:eboro/main.dart';

class Internet extends StatefulWidget {
  @override
  Internet2 createState() => Internet2(0);
}

class Internet2 extends State <Internet> {
  final int index;
  Internet2(this.index);

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                width: 200,
                height: 200,
                child:
                new Image.asset(
                    "images/icons/internet.png"
              ),
            ),
            Container(height: 10,),
            Text(AppLocalizations.of(context)!.translate("noInternet"), style: TextStyle(fontSize: 24, color: myColor2,  fontWeight: FontWeight.w900,
                )
            ),
            Container(height: 10,),
          ],
        ),
      ),
    );
  }


}