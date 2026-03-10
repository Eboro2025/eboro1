import 'dart:async';
import 'package:date_format/date_format.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/DeliveryAPI.dart';
import 'package:eboro/Delivery/ClickOrderDelivery.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/RealTime/Provider/DeliveryOrderProvider.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:math' show cos, sqrt, asin;


class DeliveryOrderWidget extends StatefulWidget
{
  @override
  DeliveryOrder2 createState() => new DeliveryOrder2();

  final String? status;
  DeliveryOrderWidget({Key? key,required this.status,}) : super(key: key);
}

class DeliveryOrder2 extends State<DeliveryOrderWidget>
{

  Timer? timer;
  bool _isNavigating = false; // منع الضغط المتكرر

  @override
  void initState() {
    super.initState();
    _startTimer(60);
  }


  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer(sec) {
    timer = Timer.periodic(Duration(seconds: sec??60), (Timer t) => checkInternetState(context));
  }
  void _stopTimer() {
    timer?.cancel();
  }

  checkInternetState(context) async {
    if(Auth2.user!.online == 1)
    {
      final order = Provider.of<DeliveryOrderProvider>(context , listen: false);
      await order.updateOrder();
    }
  }

  @override
  Widget build(BuildContext context)
  {

    late List<String>? Allow_states;
    final order = Provider.of<DeliveryOrderProvider>(context);
    List<OrderData>? newOrder;
    if(Auth2.user!.online.toString() == '1') {
      if (widget.status == "pending")
        Allow_states = ["to delivering"];
      else if (widget.status == "active")
        Allow_states = ['on way', 'on delivering', 'delivered'];
      else if (widget.status == "previous")
        Allow_states = ['complete', 'user not found', 'cancelled' ,'interrupt','SyS_cancelled','doneRefund'];
    }
    if(Auth2.user!.type == "Delivery")
    {
      if(order.order != null)
      {
        newOrder = order.order!.where((element) => (Allow_states!.contains(element.status!.toLowerCase().toString()))
        ).toList();
      }
      if (widget.status == "pending")
      {
        if(order.orderDelivery != null)
        {
          newOrder = order.orderDelivery!.where((element) => (Allow_states!.contains(element.status!.toLowerCase().toString()))
          ).toList();
        }
      }
    }

    Future<void> refresh() async {
      if(Auth2.user!.online == 1)
      {
        final order = Provider.of<DeliveryOrderProvider>(context , listen: false);
        await order.updateOrder();
      }
    }

    double calculateDistance(lat1, lon1, lat2, lon2){
      var p = 0.017453292519943295;
      var c = cos;
      var a = 0.5 - c((double.parse(lat2) - double.parse(lat1)) * p)/2 +
          c(double.parse(lat1) * p) * c(double.parse(lat2)  * p) *
              (1 - c((double.parse(lon2) - double.parse(lon1)) * p))/2;
      return 12742 * asin(sqrt(a));
    }

    return Container(
        child: RefreshIndicator(
          onRefresh: refresh,
          child:ListView(
              children: [
                for(int i=0 ; newOrder!= null && i < newOrder.length ;i++)
                  Container(
                      padding: EdgeInsets.only(right:15,left: 15,top: 5,bottom: 5),
                      child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.only(right:20,left: 20,top: 5,bottom: 5),
                              child:GestureDetector(
                                child:Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all( Radius.circular(20),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.15),
                                          spreadRadius: 3,
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    width: MediaQuery.of(context).size.width,
                                    child: Container(
                                      padding: EdgeInsets.only(right:30, left: 30,top: 10,bottom: 20),
                                      child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('${AppLocalizations.of(context)!.translate("status")} : ', style: TextStyle( color: Colors.black45, fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'pending')
                                                      Text('${AppLocalizations.of(context)!.translate("pending")}', style: TextStyle( color: Colors.amber, fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'in progress')
                                                      Text('${AppLocalizations.of(context)!.translate("in_progress")}', style: TextStyle( color: Colors.blue, fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'to delivering')
                                                      Text('${AppLocalizations.of(context)!.translate("to_delivering")}', style: TextStyle( color: Colors.cyan[900], fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'on way')
                                                      Text('${AppLocalizations.of(context)!.translate("on_way")}', style: TextStyle( color: Colors.brown, fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'on delivering')
                                                      Text('${AppLocalizations.of(context)!.translate("on_delivering")}', style: TextStyle( color: Colors.indigo, fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'delivered')
                                                      Text('${AppLocalizations.of(context)!.translate("delivered")}', style: TextStyle( color: Colors.amber, fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'complete')
                                                      Text('${AppLocalizations.of(context)!.translate("complete")}', style: TextStyle( color: Colors.green, fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'cancelled' || newOrder[i].status == 'interrupt')
                                                      Text('${AppLocalizations.of(context)!.translate("cancelled")}', style: TextStyle( color: Colors.red, fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'User Not Found')
                                                      Text('${AppLocalizations.of(context)!.translate("user_not_found")}', style: TextStyle( color: Colors.orange, fontSize: MyApp2.fontSize14)),
                                                    if(newOrder[i].status == 'SyS_cancelled')
                                                      Text('${AppLocalizations.of(context)!.translate("SyS_cancelled")}', style: TextStyle( color: Colors.deepPurple, fontSize: MyApp2.fontSize14)),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Text(formatDate(safeDateParse(newOrder[i].ordar_at.toString()) ,[dd, '/', mm, '-', yyyy , '  ' ,hh, ':', nn, " ",am]).toString(), style: TextStyle(fontSize: MyApp2.fontSize14),),
                                                    Container(
                                                      padding: EdgeInsets.all(7.5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        border: Border.all(color: Colors.cyan[900]!),
                                                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                                      ),
                                                      child: Text(newOrder[i].Delivery_Price.toString() + ' € ', style: TextStyle( color: Colors.black45, fontSize: MyApp2.fontSize14)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Padding(padding: EdgeInsets.only(bottom: 10),),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(7.5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(color: Colors.cyan[900]!),
                                                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                                  ),
                                                  child: Text('#${newOrder[i].id}', style: TextStyle( color: Colors.black45, fontSize: MyApp2.fontSize14)),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.all(7.5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(color: Colors.cyan[900]!),
                                                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                                  ),
                                                  child: Text('${widget.status != 'previous' ? calculateDistance(Auth2.user!.lat,Auth2.user!.long,newOrder[i].branch!.lat,newOrder[i].branch!.long).ceil()*5 : '--'} mins', style: TextStyle( color: Colors.black45, fontSize: MyApp2.fontSize14)),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.all(7.5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(color: Colors.cyan[900]!),
                                                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                                  ),
                                                  child: Text('${widget.status != 'previous' ? calculateDistance(Auth2.user!.lat,Auth2.user!.long,newOrder[i].branch!.lat,newOrder[i].branch!.long).toStringAsFixed(2): '--'} KM', style: TextStyle( color: Colors.black45, fontSize: MyApp2.fontSize14)),
                                                ),
                                              ],
                                            ),
                                          ]
                                      ),

                                    )
                                ),
                                onTap: () async {
                                  if (_isNavigating) return; // منع الضغط المتكرر
                                  _isNavigating = true;
                                  Progress.progressDialogue(context);
                                  var alina = await DeliveryAPI2().getOrders(newOrder![i].id);
                                  if(alina != null)
                                  {
                                    order.selectedOrder = alina[0];
                                    order.player?.stop();
                                    Progress.dimesDialog(context);
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DeliveryClickOrder()));
                                  }
                                  _isNavigating = false;
                                },
                              ),
                            ),
                            new Align(alignment: Alignment.centerLeft,
                              child: Ink(child: Column(children: [
                                if(newOrder[i].status == 'pending')
                                  Container(
                                    padding: EdgeInsets.all(7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.deepOrange),
                                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                    ),
                                    child: Image.asset('images/icons/pending.png',height: 25,width: 25, color: Colors.deepOrange,),
                                  ),
                                if(newOrder[i].status == 'in progress')
                                  Container(
                                    padding: EdgeInsets.all(7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.lightBlue),
                                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                    ),
                                    child: Image.asset('images/icons/sync.png',height: 25,width: 25, color: Colors.blue,),
                                  ),
                                if(newOrder[i].status == 'to delivering'|| newOrder[i].status == 'on way')
                                  Container(
                                    padding: EdgeInsets.all(7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.cyan[900]!),
                                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                    ),
                                    child: Image.asset('images/icons/shopping-bagg.png',height: 25,width: 25, color: Colors.cyan[900],),
                                  ),
                                if(newOrder[i].status == 'on delivering')
                                  Container(
                                    padding: EdgeInsets.all(7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.indigo),
                                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                    ),
                                    child: Image.asset('images/icons/scooterr.png',height: 25,width: 25, color: Colors.indigo,),
                                  ),
                                if(newOrder[i].status == 'delivered')
                                  Container(
                                    padding: EdgeInsets.all(7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.amber),
                                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                    ),
                                    child: Image.asset('images/icons/checkk.png',height: 25,width: 25, color: Colors.amber,),
                                  ),
                                if(newOrder[i].status == 'cancelled' || newOrder[i].status == 'interrupt')
                                  Container(
                                    padding: EdgeInsets.all(7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.red),
                                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                    ),
                                    child: Image.asset('images/icons/close.png',height: 25,width: 25, color: Colors.red,),
                                  ),
                                if(newOrder[i].status == 'complete')
                                  Container(
                                    padding: EdgeInsets.all(7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.green),
                                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                    ),
                                    child: Image.asset('images/icons/check.png',height: 25,width: 25, color: Colors.green,),
                                  ),
                                if(newOrder[i].status == 'User Not Found')
                                  Container(
                                    padding: EdgeInsets.all(7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.orange),
                                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                    ),
                                    child: Image.asset('images/icons/unknown.png',height: 25,width: 25, color: Colors.orange,),
                                  ),
                                if(newOrder[i].status == 'SyS_cancelled')
                                  Container(
                                    padding: EdgeInsets.all(7.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.deepPurple),
                                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                    ),
                                    child: Image.asset('images/icons/sys.png',height: 25,width: 25, color: Colors.deepPurple,),
                                  ),
                              ],
                              ),
                              ),
                            ),
                          ]
                      )
                  )
              ]
          ),
        )
    );
  }
}