import 'dart:async';
import 'dart:convert';

import 'package:date_format/date_format.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalenderDayCheck extends StatefulWidget {
  @override
  CalenderDayCheck2 createState() => CalenderDayCheck2(0);
  final String? day;
  CalenderDayCheck({Key? key, required this.day}) : super(key: key);
}

class CalenderDayCheck2 extends State <CalenderDayCheck> {
  final int index;
  CalenderDayCheck2(this.index);
  List booked = [];
  List date = [];
  List time2 = [];
  // ProgressDialog pr;

  @override
  initState() {
    super.initState();
    timer();
  }

  timer() async {
    var _duration = new Duration(milliseconds: 1);
    return new Timer(_duration, authenticate2);
  }

  showDialog() async {
    // pr = ProgressDialog(context,type: ProgressDialogType.Normal, isDismissible: false);
    /*pr.update(
      message: "Please wait...",
      progressWidget: Container(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
      messageTextStyle: TextStyle(
          color: myColor, fontSize: 18, fontWeight: FontWeight.w600),
    );
    await pr.show();*/
  }

  dimesDialog() async {
    // await pr.hide();
  }

  List time = [ '00:00', '00:30', '01:00', '01:30', '02:00', '02:30', '03:00', '03:30', '04:00', '04:30',
    '05:00', '05:30', '06:00', '06:30', '07:00', '07:30', '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30', '22:00', '22:30',
    '23:00', '23:30'];

  authenticate2() async {
    Progress.progressDialogue(context);
    String myUrl = "$globalUrl/api/get/delivery-calendar";
    http.get(Uri.parse(myUrl), headers: {
      'apiLang' : MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    }).then((response) async {
      Progress.dimesDialog(context);
      Map B = json.decode(response.body);
      if ((B["message"] != null && B["message"].contains("Unauthenticated")) ||
          MyApp2.token== null) {
        void deleteToken() async {
          SharedPreferences preferences = await SharedPreferences.getInstance();
          await preferences.clear();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
        deleteToken();
      }
      else {
        setState(() {
          List branchDetails = json.decode(response.body)['data'];
          for (var branchDetails in branchDetails) {
            date.add(formatDate(
                safeDateParse(branchDetails['booked_at'].toString()),
                [yyyy, '-', mm, '-', dd]).toString());
            time2.add(formatDate(
                safeDateParse(branchDetails['booked_at'].toString()),
                [HH, ':', nn]).toString());
            for(int i = 0; i < date.length; i++){
              if(date[i].toString() == widget.day) {
                booked.add(time2[i].toString());
              }
            }
          }
        });
      }
    });
  }

  void showAlertDialog(i) async{
    showGeneralDialog(
      barrierLabel: "Label",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 500),
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height*.25,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.25),
                  spreadRadius: 2.5,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Be ' + time[i] + ' booked',
                    style: TextStyle(
                        fontSize: 20,

                        decoration: TextDecoration.none,
                        color: myColor
                    ),
                  ),
                  Text(
                    'Are you sure to be ' + time[i] + ' booked?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w100,
                        color: myColor2
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          padding: EdgeInsets.only(right: 10, left: 10),
                          width: MediaQuery.of(context).size.width*.5,
                          height: MediaQuery.of(context).size.width*.125,
                          child:MaterialButton(
                            child: Text(
                              'Yes',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            color: myColor,
                            textColor: Colors.white,
                            onPressed: () {
                                authenticate2() async {
                                  String myUrl = "$globalUrl/api/add/delivery-calendar";
                                  http.post(Uri.parse(myUrl), headers: {
                                    'apiLang' : MyApp2.apiLang.toString(),
                                    'Accept': 'application/json',
                                    'Authorization': "${MyApp2.token}",
                                  },body: {
                                    'user_id' : Auth2.user!.id.toString(),
                                    'booked_at' : widget.day! + " " + time[i] + ':00'
                                  }).then((response) async {
                                    Map B = json.decode(response.body);
                                    if ((B["message"] != null && B["message"].contains("Unauthenticated")) ||
                                        MyApp2.token== null) {
                                      void deleteToken() async {
                                        SharedPreferences preferences = await SharedPreferences.getInstance();
                                        await preferences.clear();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => LoginScreen()),
                                        );
                                      }
                                      deleteToken();
                                    }
                                    else {
                                      setState(() {
                                        booked.add(time[i]);
                                      });
                                    }
                                  });
                                }
                                authenticate2();
                                Navigator.pop(context, true);
                            },
                          )),
                    ],
                  )
                ],
              ),),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
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
        title: Text(widget.day.toString(),
            style: TextStyle( color: Colors.white, fontSize: 22)),
        iconTheme: new IconThemeData(color: Colors.white),
      ),

      body: Center(
        child: new ListView(children: [
          for(int i = 0; i < time.length; i++)(
              new Stack(
                children: <Widget>[
                  new Padding(
                    padding: const EdgeInsets.only(left: 50.0),
                    child: GestureDetector(
                        child: Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      margin: new EdgeInsets.all(20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: new Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(5),
                        child: booked.contains(time[i])  ? Text('Booked', style: TextStyle(color: Colors.white, fontSize: 20)) : Text('Be booked', style: TextStyle(color: Colors.white, fontSize: 20)),
                        height: 50.0,
                        color: booked.contains(time[i]) ? Colors.red : Colors.amber,
                      ),
                    ),
                      onTap: booked.contains(time[i]) ?  (){

                      }: () {
                        setState(() {
                          showAlertDialog(i);
                        });
                      },
                    )
                  ),
                  new Positioned(
                    top: 0.0,
                    bottom: 0.0,
                    left: 35.0,
                    child: new Container(
                      height: double.infinity,
                      width: 1.0,
                      color: Colors.black,
                    ),
                  ),
                  new Positioned(
                    top: 20.0,
                    left: 10.0,
                    child: new Container(
                      height: 50.0,
                      width: 50.0,
                      decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: new Container(
                        alignment: Alignment.center,
                        height: 30.0,
                        width: 30.0,
                        decoration: new BoxDecoration(
                            shape: BoxShape.circle,
                            color: myColor),
                        child: Text(time[i], style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  )
                ],
              )
          )
        ]),
      ),
    );
  }


}