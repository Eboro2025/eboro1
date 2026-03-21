import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/All/language.dart';
import 'package:eboro/Auth/Profile.dart';
import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/Delivery/Calender.dart';
import 'package:eboro/Delivery/Delivery.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:date_format/date_format.dart';
import 'package:url_launcher/url_launcher.dart';


class DeliveryReport extends StatefulWidget {
  @override
  DeliveryReport2 createState() => DeliveryReport2();
}

class DeliveryReport2 extends State <DeliveryReport> {
  int currentTabIndex = 1;
  String?from, to, from3, to3;
  DateTime? from2, to2;
  onTapped(int index) {
    setState(() {
      currentTabIndex = index;
      if(currentTabIndex == 0)
        Navigator.push(context, MaterialPageRoute(builder: (context) => Delivery()),);
      if(currentTabIndex == 2)
        Navigator.push(context, MaterialPageRoute(builder: (context) => Calender()));
    });
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
        child:Scaffold(
          backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        title: Text('${AppLocalizations.of(context)!.translate("delivery")}',
            style: TextStyle( color: Colors.white, fontSize: 22)),
        iconTheme: new IconThemeData(color: Colors.white),
        bottom: TabBar(
          tabs: [
            Tab(icon: Text('${AppLocalizations.of(context)!.translate("reports")}', style: TextStyle())),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
        ),
      ),
      body: Center(
         child:reports(context)
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
        )
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



  Widget reports(BuildContext context) {
    return Container(
      child:ListView(
          children: [
            Container(
                padding: EdgeInsets.all(5),
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              MaterialButton(
                  shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                  color: myColor,
                  onPressed: () {
                    DatePicker.showDatePicker(context,
                        showTitleActions: true,
                        onConfirm: (date) {
                          setState(() {
                            from2 = date;
                            from = formatDate(
                                DateTime.parse(date.toString()),
                                [D, ' ', dd, '/', mm, '/', yyyy]).toString();
                            from3 = formatDate(
                                DateTime.parse(date.toString()),
                                [dd, '-', mm, '-', yyyy]).toString();
                            if(to != null) {
                              if (to2!.isBefore(from2!))
                                setState(() {
                                  to2 = from2;
                                  to = from;
                                });
                            }
                          });
                        }, locale: LocaleType.en);
                  },
                  child: Text(
                    from.toString() != 'null'  ? from.toString() : 'From',
                    style: TextStyle(fontSize: 14, color: Colors.white, ),
                  )),
              MaterialButton(
                  shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                  color: myColor,
                  onPressed: () {
                    DatePicker.showDatePicker(context,
                        showTitleActions: true,
                        onConfirm: (date) {
                          setState(() {
                            to2 = date;
                            to = formatDate(
                                DateTime.parse(date.toString()),
                                [D, ' ', dd, '/', mm, '/', yyyy]).toString();
                            to3 = formatDate(
                                DateTime.parse(date.toString()),
                                [dd, '-', mm, '-', yyyy]).toString();
                            if(from != null) {
                              if (to2!.isBefore(from2!))
                                setState(() {
                                  to2 = from2;
                                  to = from;
                                });
                            }
                          });
                        }, locale: LocaleType.en);
                  },
                  child: Text(
                    to.toString() != 'null'  ? to.toString() : 'To',
                    style: TextStyle(fontSize: 14, color: Colors.white, ),
                  )),
            ],)),
                Container(
                    padding: EdgeInsets.only(right:15,left: 15,top: 5,bottom: 5),
                    child: Stack(
                        alignment: Alignment.center,
                        children: [
                             Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                      topLeft: Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.25),
                                        spreadRadius: 2.5,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  child: Container(
                                    padding: EdgeInsets.only(right:30, left: 30,top: 10,bottom: 10),
                                    child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text('Your Orders', style: TextStyle( color: myColor2, fontSize: 20)),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  GestureDetector(child: Container(padding: EdgeInsets.only(right: 10), child: Icon(FontAwesomeIcons.fileCsv, color: Color(0xFF1D6F42), size: 25,),),
                                                    onTap: () {
                                                      downloadCsv() async {
                                                        if(from3 == null || from3 == null ){
                                                          Auth2.show('Choose date first');
                                                        }
                                                        else{
                                                          String url = '$globalUrl/' + 'Delivery_Orders_Report/csv/' + from3.toString() + '/' + to3.toString();
                                                          launch(url);
                                                        }
                                                      }
                                                      downloadCsv();
                                                  },),
                                                  // 0xFFF40F02
                                                  // Container(padding: EdgeInsets.all(10),child: Icon(FontAwesomeIcons.fileWord, color: Color(0xFF2b579a), size: 25,),),
                                                  GestureDetector(child: Container(padding: EdgeInsets.only(left: 10),child: Icon(FontAwesomeIcons.fileExcel, color: Color(0xFF1D6F42), size: 25,),),
                                                    onTap: () {
                                                      downloadExcel() async {
                                                        if(from3 == null || from3 == null ){
                                                          Auth2.show('Choose date first');
                                                        }else{
                                                          String url = '$globalUrl/' + 'Delivery_Orders_Report/'+Auth2.user!.id.toString()+'/excel/' + from3.toString() + '/' + to3.toString();
                                                          launch(url);
                                                        }
                                                      }
                                                      downloadExcel();
                                                    },),
                                                ],
                                              ),
                                            ],
                                          ),
                                  ),
                               padding: EdgeInsets.only(right:20,left: 20,top: 5,bottom: 5),
                             ),
                        ]))
          ]
      ),
    );
  }

}