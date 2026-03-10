import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/All/language.dart';
import 'package:eboro/Auth/Profile.dart';
import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/Delivery/CalenderDayCheck.dart';
import 'package:eboro/Delivery/CalenderDayClicked.dart';
import 'package:eboro/Delivery/Delivery.dart';
import 'package:eboro/Delivery/DeliveryReport.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:date_format/date_format.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Calender extends StatefulWidget {
  @override
  Calender2 createState() => Calender2(0);
}

class Calender2 extends State <Calender> {
  final int index;
  Calender2(this.index);
  late List days;
  late List days2;
  String?now3;
  int currentTabIndex = 2;
  onTapped(int index) {
    setState(() {
      currentTabIndex = index;
      if(currentTabIndex == 0)
        Navigator.push(context, MaterialPageRoute(builder: (context) => Delivery()),);
      if(currentTabIndex == 1)
        Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryReport()));
    });
  }

  @override
  initState() {
    // TODO: implement initState
    super.initState();
    DateTime now = new DateTime.now();
    now3 = formatDate(
        DateTime.parse(now.toString()),
        [yyyy, '-', mm, '-', dd]).toString();
    String now2;
    String day;
    for (int i = 0; i <= 7; i++) {
      now2 = formatDate(
          DateTime.parse(now.add(Duration(days: i)).toString()),
          [yyyy, '-', mm, '-', dd]).toString();
      day = formatDate(
          DateTime.parse(now.add(Duration(days: i)).toString()),
          [D]).toString();
      days2.add(day.toString());
      days.add(now2.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
        ],
        backgroundColor: myColor,
        centerTitle: true,
        title: const Text('Calender',
            style: TextStyle( color: Colors.white, fontSize: 22)),
        iconTheme: new IconThemeData(color: Colors.white),
      ),

      body: Center(
        child: new ListView(children: [
          for(int i = 0; i < days.length; i++)(
          GestureDetector(
              child: Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                margin: new EdgeInsets.all(10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: new Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(5),
                  child: Text(days[i] + " " + days2[i], style: TextStyle(color: Colors.white, fontSize: 20)),
                  height: 50.0,
                  color: Colors.teal,
                ),
              ),
            onTap: () {
                if(days[i] != now3)
                Navigator.push(context, MaterialPageRoute(builder: (context) => CalenderDayCheck(day :days[i].toString())));
              else
                Navigator.push(context, MaterialPageRoute(builder: (context) => CalenderDayClicked(day :days[i].toString())));
            },
          )
          )
        ]),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                    colorFilter: new ColorFilter.mode(Colors.black.withOpacity(.2), BlendMode.darken),
                    image: AssetImage(
                      'images/icons/menuback.jpg',
                    ),
                    fit: BoxFit.fill
                ),
              ),
              currentAccountPicture: Container(
                width: MediaQuery.of(context).size.width *.1,
                height: MediaQuery.of(context).size.width *.1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(200.0)),
                  border: Border.all(color: Colors.grey, width: 2.5),
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(
                          Auth2.user!.image.toString()
                      ),
                      fit: BoxFit.cover
                  ),
                ),
              ),
              accountEmail: Text(
                  Auth2.user!.email.toString(), style: TextStyle(fontSize: MediaQuery
                 .of(context)
                 .size
                 .width *.05,
                color: Colors.white,
              )),
              accountName: Text(
                  Auth2.user!.name.toString(), style: TextStyle(fontSize: MediaQuery
                 .of(context)
                 .size
                 .width *.05,
                color: Colors.white,
              )),),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate("myprofile"), style: TextStyle(color: myColor2),),
              leading: Icon(Icons.person_outline, color: myColor, size: 25),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyProfile()),
                );
              },
            ),
            ListTile(
              title: Text('${AppLocalizations.of(context)!.translate("language")}', style: TextStyle(color: myColor2),),
              leading: Icon(Icons.language, color: myColor, size: 25),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Language()),
                );
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate("logout"), style: TextStyle(color: myColor2),),
              leading: Icon(Icons.logout, color: myColor, size: 25),
              onTap: () {
                deleteToken();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex,
        onTap: onTapped,
        selectedItemColor: myColor,
        unselectedItemColor: Colors.black38,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.shopping_bag_outlined),
            label: "${AppLocalizations.of(context)!.translate("orders")}",
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.insert_chart_outlined),
            label: "${AppLocalizations.of(context)!.translate("reports")}",
          ),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.calendarAlt),
              label: "${AppLocalizations.of(context)!.translate("calender")}",
          )
        ],
      ),
    );
  }

  void deleteToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove('token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }


}