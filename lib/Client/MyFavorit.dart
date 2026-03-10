import 'package:eboro/API/Favorite.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/Widget/Favorits.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class MyFavorite extends StatefulWidget {
  @override
  MyFavorite2 createState() => MyFavorite2();
}

class MyFavorite2 extends State<MyFavorite> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: myColor,
          centerTitle: true,
          title: Text(AppLocalizations.of(context)!.translate("myfavorite"),
              style: TextStyle(color: Colors.white, fontSize: MyApp2.H! * .03)),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (Favorite2.favorite == null || Favorite2.favorite!.isEmpty)
                Container(
                  width: MyApp2.W! * .75,
                  height: MyApp2.W! * .75,
                  child: Image.asset('images/icons/favorite.png'),
                )
              else
                Expanded(child: Favorites()),
            ],
          ),
        ),
      ),
    );
  }
}
