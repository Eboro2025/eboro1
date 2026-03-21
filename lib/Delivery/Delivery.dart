import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/All/Aboutus.dart';
import 'package:eboro/All/language.dart';
import 'package:eboro/Auth/Profile.dart';
import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/Delivery/Calender.dart';
import 'package:eboro/Delivery/DeliveryReport.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/RealTime/Widget/DeliveryOrderWidget.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
// import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Delivery extends StatefulWidget {
  @override
  Delivery2 createState() => Delivery2(0);
}

class Delivery2 extends State <Delivery> with WidgetsBindingObserver{
  final int index;
  Delivery2(this.index);

  // ProgressDialog pr;
  String?online;
  bool isSwitched = false;
  String?mp3myUrl;
  AudioPlayer audioPlugin = AudioPlayer();
  int tab = 2;
  int currentTabIndex = 0;

  onTapped(int index) {
    setState(() {
      currentTabIndex = index;
      if(currentTabIndex == 1)
       {
         Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryReport()),);
       }
      else if(currentTabIndex == 2)
       {
         Navigator.push(context, MaterialPageRoute(builder: (context) => Calender()),);
       }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    showState();
  }

  @mustCallSuper
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  showState() async {
    if (Auth2.user!.online.toString() == "0") {
      isSwitched = false;
    }
    if (Auth2.user!.online.toString() == "1") {
      isSwitched = true;
    }
  }

  _onRememberMeChanged(bool newValue) {
    setState(() {
      isSwitched = newValue;
      if (isSwitched == true) {
        online = '1';
      }
      if (isSwitched == false) {
        online = '0';
      }
      Auth2.editUserDetails(null, null, null, null, null, null, null, null, online, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tab,
      child:Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          actions: [
            Column(
              children: [

                Expanded(
                  flex: 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Switch(
                          activeThumbColor: Colors.red,
                          value: isSwitched,
                          onChanged: _onRememberMeChanged
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10,right: 10),
                        child: Text(
                          "${isSwitched  ? 'ON' : 'OFF'}",
                          textScaleFactor: 1.3,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          backgroundColor: myColor,
          centerTitle: true,
          title: Text('${AppLocalizations.of(context)!.translate("delivery")}',
              style: TextStyle( color: Colors.white, fontSize: 22)),
          iconTheme: new IconThemeData(color: Colors.white),
          bottom: TabBar(
            tabs: [
              Tab(icon: Text(AppLocalizations.of(context)!.translate("active"), style: TextStyle())),
              Tab(icon: Text(AppLocalizations.of(context)!.translate("previous"), style: TextStyle())),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
          ),
        ),
        body: Container(
          child: TabBarView(
            children: [
              Container(child: DeliveryOrderWidget(status: 'active')),
              Container(child: DeliveryOrderWidget(status: 'previous')),
            ],
          ),
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
                currentAccountPicture: Card(
                  semanticContainer: true,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child:CachedNetworkImage(
                    fit: BoxFit.fill,
                    useOldImageOnUrlChange: true,
                    imageUrl: Auth2.user!.image!,
                    progressIndicatorBuilder: (context, url, downloadProgress) =>
                        CircularProgressIndicator(value: downloadProgress.progress),
                    errorWidget: (context, url, error) => Image.asset('images/icons/profile.png'),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(200),
                    side: BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                  ),
                  elevation: 3,
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
                title: Text('${AppLocalizations.of(context)!.translate("about")}', style: TextStyle(color: myColor2),),
                leading: Icon(Icons.info, color: myColor, size: 25),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Aboutus()),
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
                label: AppLocalizations.of(context)!.translate("orders"),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.insert_chart_outlined),
                label: AppLocalizations.of(context)!.translate("reports"),
            ),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.calendarAlt),
                label: "${AppLocalizations.of(context)!.translate("calender")}",
            )
          ],
        ),
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