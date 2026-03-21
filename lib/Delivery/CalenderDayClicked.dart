import 'dart:async';
import 'package:date_format/date_format.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:progress_dialog/progress_dialog.dart';
import 'dart:convert';


class CalenderDayClicked extends StatefulWidget {
  @override
  CalenderDayClicked2 createState() => CalenderDayClicked2(0);
  final String? day;
  CalenderDayClicked({Key? key, required this.day}) : super(key: key);
}

class CalenderDayClicked2 extends State <CalenderDayClicked> {
  final int index;
  CalenderDayClicked2(this.index);
  late List name;
  late List oID;
  late List branch;
  late List total;
  late List date;
  String names = "";
  String branches = "";
  late List time2;
  // ProgressDialog pr;
  int counter = 0;

  @override
  initState() {
    timer();
    super.initState();
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

  List time = [
    '00:00', '00:30', '01:00', '01:30', '02:00', '02:30', '03:00', '03:30', '04:00', '04:30', '05:00', '05:30',
    '06:00', '06:30', '07:00', '07:30', '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30', '22:00', '22:30', '23:00', '23:30'];

  authenticate2() async {
    showDialog();
    String myUrl = "$globalUrl/api/search-order";
    http.post(Uri.parse(myUrl), headers: {
      'apiLang' : MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    },body: {
      'delivery_id' : Auth2.user!.id.toString()
    }).then((response) async {
      dimesDialog();
      setState(() {
        Iterable A = json.decode(response.body)['data'];
        List<OrderData> branchDetails = List<OrderData>.from(A.map((A)=> OrderData.fromJson(A)));
        for (OrderData items in branchDetails)
        {
          if(formatDate(
              safeDateParse(items.ordar_at.toString()),
              [yyyy, '-', mm, '-', dd]).toString() == widget.day)
         {
           name.add(items.user!.name.toString());
           oID.add(items.id.toString());
           branches = "";
           for (var items_Details in items.content!) {
             branches += items_Details.product!.branch!.name.toString() + ",";
           }
           branch.add(branches);
           total.add(items.Delivery_Price.toString());
           date.add(formatDate(
               safeDateParse(items.ordar_at.toString()),
               [yyyy, '-', mm, '-', dd]).toString());

           String Hour = formatDate(
               safeDateParse(items.ordar_at.toString()),
               [HH]).toString();

           int min = int.parse(formatDate(
               safeDateParse(items.ordar_at.toString()),
               [nn]).toString());
           time2.add(Hour +':'+ (min > 29  ? "30":"00"));
         }
        }
      });
    });
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
          if(time2.length != 0)
            for(int i = 0; i < time.length; i++)//24
              for(int k = 0; k < time2.length; k++)//1
                new Stack(
                  children: <Widget>[
                    new Padding(
                        padding: const EdgeInsets.only(left: 50.0),
                        child: time[i].contains(time2[k])   ? Card(
                          semanticContainer: true,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          margin: new EdgeInsets.all(20.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: new Container(
                            padding: EdgeInsets.all(5),
                            width: double.infinity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${AppLocalizations.of(context)!.translate("order_id")} : #' + oID[k], style: TextStyle(color: Colors.white)),
                                    Text(name[k], style: TextStyle(color: Colors.white)),
                                  ],),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(branch[k], style: TextStyle(color: Colors.white)),
                                    Text('${AppLocalizations.of(context)!.translate("price")} : ' + total[k] + ' €', style: TextStyle(color: Colors.white))
                                  ],)
                              ],),
                            height: 50.0,
                            color:Colors.green,
                          ),
                        ):
                        !time2.contains(time[i]) && k==0
                            ? Card(
                          semanticContainer: true,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          margin: new EdgeInsets.all(20.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: new Container(
                            padding: EdgeInsets.all(5),
                            width: double.infinity,
                            height: 50.0,
                          ),
                          elevation: 0,
                        ): Card()),
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
                              color: myColor2),
                          child: Text( time[i], style: TextStyle(color: Colors.white),),
                        ),
                      ),
                    )
                  ],
                )
            else
            for(int i = 0; i < time.length; i++)//24
            new Stack(
              children: <Widget>[
                new Padding(
                    padding: const EdgeInsets.only(left: 50.0),
                    child: Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      margin: new EdgeInsets.all(20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: new Container(
                        padding: EdgeInsets.all(5),
                        width: double.infinity,
                        height: 50.0,
                      ),
                      elevation: 0,
                    )),
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
                          color: myColor2),
                      child: Text( time[i], style: TextStyle(color: Colors.white),),
                    ),
                  ),
                )
              ],
            )
        ]),
      ),
    );
  }


}