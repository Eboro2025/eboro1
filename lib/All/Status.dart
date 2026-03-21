import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class Status extends StatefulWidget {
  @override
  Status2 createState() => Status2(0);
  final String?status;
  Status({Key? key,required this.status}) : super(key: key);
}

class Status2 extends State <Status> {
  final int index;
  Status2(this.index);

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
              width: MyApp2.W! *.5,
              child: Image.asset(
                    "images/icons/lock.png"
              ),
            ),

            Container(height: 10,),

            Text(
                AppLocalizations.of(context)!.translate("systemLocked"),
                style: TextStyle(fontSize: MyApp2.W! *.07, color: myColor2,  fontWeight: FontWeight.w900,)
            ),

            Container(height: 10,),

            Text(widget.status.toString(),style: TextStyle(fontSize: MyApp2.W! *.06, color: myColor2,)
            ),

          ],
        ),
      ),
    );
  }


}