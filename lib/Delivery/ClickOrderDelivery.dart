import 'dart:async';
import 'dart:io';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/gestures.dart';
import 'package:eboro/API/DeliveryAPI.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:date_format/date_format.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/RealTime/Widget/ChatTextWidget.dart';
import 'package:eboro/Delivery/Delivery.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/RealTime/Provider/DeliveryOrderProvider.dart';
import 'package:eboro/Widget/BottomDialog.dart';
import 'package:eboro/Widget/DeliveryOrderState.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sunmi_thermal_printer/sunmi_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;

import 'package:url_launcher/url_launcher_string.dart';

class DeliveryClickOrder extends StatefulWidget {
  @override
  DeliveryClickOrder2  createState() => DeliveryClickOrder2(0);
}

class DeliveryClickOrder2 extends State <DeliveryClickOrder> {
  final int index;

  DeliveryClickOrder2(this.index);


  // SunmiThermalPrinter _printer;
  String?subtotal;
  late List <String> checked;
  Timer? timer;
  bool _hasNotifiedCustomerNearby = false; // notify customer only once

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 65), (Timer t) => checkInternetState(context));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }


  checkInternetState(context) async {
    if(Auth2.user!.online == 1)
    {
      final order = Provider.of<DeliveryOrderProvider>(context , listen: false);
      await order.updateOrder();
      // Notify customer when driver reaches 100 meters
      _checkProximityToCustomer(order);
    }
  }

  void _checkProximityToCustomer(DeliveryOrderProvider order) async {
    if (_hasNotifiedCustomerNearby) return;
    final selectedOrder = order.selectedOrder;
    if (selectedOrder == null) return;
    if (selectedOrder.status != 'on delivering') return;
    if (selectedOrder.drop_lat == null || selectedOrder.drop_long == null) return;
    if (Auth2.user?.lat == null || Auth2.user?.long == null) return;

    try {
      double distanceKm = _calculateDistance(
        Auth2.user!.lat.toString(),
        Auth2.user!.long.toString(),
        selectedOrder.drop_lat!,
        selectedOrder.drop_long!,
      );
      // 0.1 KM = 100 meters
      if (distanceKm <= 0.1) {
        _hasNotifiedCustomerNearby = true;
        await DeliveryAPI2().notifyCustomerNearby(selectedOrder.id.toString());
      }
    } catch (_) {}
  }

  double _calculateDistance(String lat1, String lon1, String lat2, String lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((double.parse(lat2) - double.parse(lat1)) * p) / 2 +
        c(double.parse(lat1) * p) * c(double.parse(lat2) * p) *
            (1 - c((double.parse(lon2) - double.parse(lon1)) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  cheked() async {
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context, listen: false);
    List? check = MyApp2.prefs.getStringList('checked');
    if(deliveryOrder.selectedOrder!.status == 'on delivering' && !check!.contains(deliveryOrder.selectedOrder!.id.toString())) {
      Future.delayed(Duration.zero, () => showAlertDialog(context));
    }
  }

  void showAlertDialog(BuildContext context) async{
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context, listen: false);
    SharedPreferences pref = await SharedPreferences.getInstance();
    showGeneralDialog(
      barrierLabel: "Label",
      barrierDismissible: false,
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
                    'Check Order',
                    style: TextStyle(
                        fontSize: 20,

                        decoration: TextDecoration.none,
                        color: myColor
                    ),
                  ),
                  Text(
                    'Do not forget to check the order?',
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
                              'Ok',
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
                              setState(() {
                                checked.add(deliveryOrder.selectedOrder!.id.toString());
                                pref.setStringList('checked', checked);
                                Navigator.pop(context, true);
                              });
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

  void handleClick(String value) {
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context, listen: false);
    switch (value) {
      case 'Chat':
        timer!.cancel();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatTextWidget(id: deliveryOrder.selectedOrder!.id.toString())),);
        break;
    // case 'Print':
    //       () async {
    //     await _loadTestData();
    //     _printer.exec();
    //   }();
    //   break;
    // case 'Cancel':
    //   showGeneralDialog(
    //     barrierLabel: "Label",
    //     barrierDismissible: true,
    //     barrierColor: Colors.black.withOpacity(0.5),
    //     transitionDuration: Duration(milliseconds: 500),
    //     context: context,
    //     pageBuilder: (context, anim1, anim2) {
    //       return Align(
    //         alignment: Alignment.bottomCenter,
    //         child: Container(
    //           width: MediaQuery.of(context).size.width,
    //           height: MediaQuery.of(context).size.height*.25,
    //           decoration: BoxDecoration(
    //             color: Colors.white,
    //             borderRadius: BorderRadius.only(
    //               topLeft: Radius.circular(20),
    //               topRight: Radius.circular(20),
    //             ),
    //             boxShadow: [
    //               BoxShadow(
    //                 color: Colors.grey.withOpacity(0.25),
    //                 spreadRadius: 2.5,
    //                 blurRadius: 5,
    //               ),
    //             ],
    //           ),
    //           child: Container(
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.center,
    //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //               children: [
    //                 Text(
    //                   'Cancel Order',
    //                   style: TextStyle(
    //                       fontSize: 20,
    //
    //                       decoration: TextDecoration.none,
    //                       color: myColor
    //                   ),
    //                 ),
    //                 Text(
    //                   'Are you sure you want to cancel this order?',
    //                   textAlign: TextAlign.center,
    //                   style: TextStyle(
    //                       fontSize: 16,
    //                       decoration: TextDecoration.none,
    //                       fontWeight: FontWeight.w100,
    //                       color: myColor2
    //                   ),
    //                 ),
    //                 Row(
    //                   children: [
    //                     Container(
    //                         padding: EdgeInsets.only(right: 10, left: 10),
    //                         width: MediaQuery.of(context).size.width*.5,
    //                         height: MediaQuery.of(context).size.width*.125,
    //                         child:MaterialButton(
    //                           child: Text(
    //                             'No',
    //                             style: TextStyle(
    //                               fontSize: 20,
    //                             ),
    //                           ),
    //                           shape: RoundedRectangleBorder(
    //                             borderRadius: BorderRadius.circular(50),
    //                           ),
    //                           color: Colors.red,
    //                           textColor: Colors.white,
    //                           onPressed: () {
    //                             Navigator.pop(context);
    //                           },
    //                         )),
    //                     Container(
    //                         padding: EdgeInsets.only(right: 10, left: 10),
    //                         width: MediaQuery.of(context).size.width*.5,
    //                         height: MediaQuery.of(context).size.width*.125,
    //                         child:MaterialButton(
    //                           child: Text(
    //                             'Yes',
    //                             style: TextStyle(
    //                               fontSize: 20,
    //
    //                             ),
    //                           ),
    //                           shape: RoundedRectangleBorder(
    //                             borderRadius: BorderRadius.circular(50),
    //                           ),
    //                           color: Colors.green,
    //                           textColor: Colors.white,
    //                           onPressed: () {
    //                             setState(() {
    //                               authenticate3() async {
    //                                 String myUrl = "$globalUrl/api/edit-order";
    //                                 http.post(Uri.parse(myUrl), headers: {
    //                                   'apiLang' : MyApp2.apiLang.toString(),
    //                                   'Accept': 'application/json',
    //                                   'Authorization': "${MyApp2.token}",
    //                                 },
    //                                     body: {
    //                                       'delivery_id': Auth2.user.id.toString(),
    //                                       'status': 'delivery_cancel',
    //                                       'order_id': deliveryOrder.selectedOrder.id,
    //                                       'drop_address': deliveryOrder.selectedOrder.address.toString()
    //                                     }).then((response) async {
    //                                   setState(() {
    //                                     // print(response.body);
    //                                   });
    //                                   Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>
    //                                       Delivery()), (Route<dynamic> route) => false);
    //                                 });
    //                               }
    //                               authenticate3();
    //                             });
    //                           },
    //                         )),
    //                   ],
    //                 )
    //               ],
    //             ),),
    //         ),
    //       );
    //     },
    //     transitionBuilder: (context, anim1, anim2, child) {
    //       return SlideTransition(
    //         position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(anim1),
    //         child: child,
    //       );
    //     },
    //   );
    //   break;
    }
  }

  Widget build(BuildContext context) {
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        iconTheme: new IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: IconButton( //back
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>   Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Delivery())),
        ),
        actions: [
          if(deliveryOrder.selectedOrder != null && (deliveryOrder.selectedOrder!.status.toString() == 'on way' ||
              deliveryOrder.selectedOrder!.status.toString() == 'on delivering' ||
              deliveryOrder.selectedOrder!.status.toString() == 'delivered' ))
            PopupMenuButton<String>(
              onSelected: handleClick,
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'Chat',
                    child: Text('Chat'),
                  ),
                ];
              },
            ),
        ],
        title: Text(
            'Order ' + "[" + deliveryOrder.selectedOrder!.id.toString() + "]", style: TextStyle(
            color: Colors.white, fontSize: 22)),
      ),
      body: new ListView(children: [
        Column(children: <Widget>[
          if(deliveryOrder.selectedOrder!.delivery == Auth2.user!.id || deliveryOrder.selectedOrder!.delivery == null) ...[
            DeliveryOrderState(),
            Container(
                padding: EdgeInsets.all(10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate("date"),
                            style: TextStyle(
                              fontSize: MyApp2.fontSize16,
                              color: myColor,
                              fontWeight: FontWeight.w900,

                            ),
                          ),
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: MyApp2.fontSize16,
                              color: myColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatDate(safeDateParse(deliveryOrder.selectedOrder!.ordar_at.toString()) ,[dd, '/', mm, '/', yyyy]).toString(), style: TextStyle(fontSize: MyApp2.fontSize14, color: myColor2),),
                          Text(formatDate(safeDateParse(deliveryOrder.selectedOrder!.ordar_at.toString()) ,[hh, ':', nn, " ",am]).toString(), style: TextStyle(fontSize: MyApp2.fontSize14, color: myColor2),),
                        ],),
                        if(deliveryOrder.selectedOrder!.branch!.has_delivery == '0')(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(color: myColor2,),
                                Text(
                                  AppLocalizations.of(context)!.translate("address") + " - " + deliveryOrder.selectedOrder!.branch!.name.toString(),
                                  style: TextStyle(
                                    fontSize: MyApp2.fontSize16,
                                    color: myColor,
                                    fontWeight: FontWeight.w900,

                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(children: <InlineSpan>[
                                        WidgetSpan(
                                          alignment: ui.PlaceholderAlignment.middle,
                                          child: Icon(Icons.location_on_outlined, color: myColor, size: MyApp2.fontSize20),
                                        ),
                                        TextSpan(
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: myColor2,
                                            ),
                                            text: "${deliveryOrder.selectedOrder!.branch!.address.toString()}",
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = ()  async {
                                                final availableMaps = await MapLauncher.isMapAvailable(MapType.google);
                                                if (availableMaps != null && availableMaps) {
                                                  await MapLauncher.showMarker(
                                                    mapType: MapType.google,
                                                    coords: Coords(
                                                        double.parse(deliveryOrder.selectedOrder!.branch!.lat!),
                                                        double.parse(deliveryOrder.selectedOrder!.branch!.long!)),
                                                    title: "Select Map",
                                                    // description: "",
                                                  );
                                                }
                                              }
                                        ),
                                      ],
                                      ),
                                    ),
                                  ],
                                )
                              ],)),
                      if(!deliveryOrder.selectedOrder!.status!.contains("to delivering"))
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: myColor2,),
                            Text(
                              AppLocalizations.of(context)!.translate("address") + " - " + deliveryOrder.selectedOrder!.user!.name.toString(),
                              style: TextStyle(
                                fontSize: MyApp2.fontSize16,
                                color: myColor,
                                fontWeight: FontWeight.w900,

                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(children: <InlineSpan>[
                                    WidgetSpan(
                                      alignment: ui.PlaceholderAlignment.middle,
                                      child: Icon(Icons.location_on_outlined, color: myColor, size: MyApp2.fontSize20),
                                    ),
                                    TextSpan(
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: myColor2,
                                        ),
                                        text: '${deliveryOrder.selectedOrder!.address.toString()}',
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            final availableMaps = await MapLauncher.isMapAvailable(MapType.google);
                                            if (availableMaps != null && availableMaps) {
                                              await MapLauncher.showMarker(
                                                mapType: MapType.google,
                                                coords: Coords(
                                                    double.parse(deliveryOrder.selectedOrder!.drop_lat!),
                                                    double.parse(deliveryOrder.selectedOrder!.drop_long!)),
                                                title: "Select Map",
                                                // description: "",
                                              );
                                            }
                                          }
                                    ),
                                  ],
                                  ),
                                ),
                              ],
                            )
                          ],),
                      Divider(color: myColor2,),
                      if(!deliveryOrder.selectedOrder!.status!.contains("to delivering"))
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate("mobilenumber"),
                              style: TextStyle(
                                fontSize: MyApp2.fontSize16,
                                color: myColor,
                                fontWeight: FontWeight.w900,

                              ),),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(children: <InlineSpan>[
                                    WidgetSpan(
                                      alignment: ui.PlaceholderAlignment.middle,
                                      child: Icon(Icons.phone, color: myColor, size: MyApp2.fontSize20),
                                    ),
                                    TextSpan(
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: myColor2,
                                        ),
                                        text: '${deliveryOrder.selectedOrder!.user!.mobile.toString()}',
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            launchUrlString("tel://${deliveryOrder.selectedOrder!.user!.mobile.toString()}");
                                          }
                                    ),
                                  ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(color: myColor2,),
                          ],),
                      Text(
                        '${AppLocalizations.of(context)!.translate("items")}',
                        style: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: myColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      for(int a = 0; a < deliveryOrder.selectedOrder!.content!.length; a++)
                        (
                            // && CashierAPI2.branch.where((x) => x.branch.id == deliveryOrder.selectedOrder.content[a].product.branch.id).isNotEmpty
                            deliveryOrder.selectedOrder!.content![a].product!.branch != null  ?
                            Container(
                              margin: EdgeInsets.all(MyApp2.W! * .025),
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
                              child: Container(
                                padding: EdgeInsets.all(5),
                                child:Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Card(
                                          semanticContainer: true,
                                          clipBehavior: Clip.antiAliasWithSaveLayer,
                                          child: CachedNetworkImage(
                                            height: MyApp2.W! * .22,
                                            width: MyApp2.W! * .22,
                                            fit: BoxFit.cover,
                                            useOldImageOnUrlChange: true,
                                            imageUrl: deliveryOrder.selectedOrder!.content![a].product!.image.toString(),
                                            progressIndicatorBuilder: (context, url, downloadProgress) =>
                                                CircularProgressIndicator(value: downloadProgress.progress),
                                            errorWidget: (context, url, error) => Image.asset("images/icons/logo.png", color: Colors.black26),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25.0),
                                          ),
                                          elevation: 5,
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          child:
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Row(
                                                children: <Widget>[
                                                  Text(
                                                    deliveryOrder.selectedOrder!.content![a].qty.toString() + ' x ',
                                                    style: TextStyle(fontSize: MyApp2.fontSize14, color: myColor2,),
                                                  ),
                                                  Text(
                                                    deliveryOrder.selectedOrder!.content![a].product!.name.toString(),
                                                    style: TextStyle(fontSize: MyApp2.fontSize14, color: myColor2,),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: <Widget>[
                                                  Text(
                                                    deliveryOrder.selectedOrder!.content![a].qty.toString() + ' x ',
                                                    style: TextStyle(fontSize: MyApp2.fontSize14, color: myColor2,),
                                                  ),
                                                  Text(
                                                    deliveryOrder.selectedOrder!.content![a].product!.price.toString() + ' €',
                                                    style: TextStyle(fontSize: MyApp2.fontSize14, color: myColor2,),
                                                  ),
                                                ],
                                              ),
                                              if(deliveryOrder.selectedOrder!.content![a].sauce.toString() != 'null')(
                                                  Row(
                                                    children: <Widget>[
                                                      Card(
                                                        semanticContainer: true,
                                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                                        child: CachedNetworkImage(
                                                          height: MediaQuery.of(context).size.width * .075,
                                                          width: MediaQuery.of(context).size.width * .075,
                                                          fit: BoxFit.fill,
                                                          useOldImageOnUrlChange: true,
                                                          imageUrl: deliveryOrder.selectedOrder!.content![a].sauce!.image.toString(),
                                                          progressIndicatorBuilder: (context, url, downloadProgress) =>
                                                              CircularProgressIndicator(value: downloadProgress.progress),
                                                          errorWidget: (context, url, error) => Image.asset("images/icons/logo.png", color: Colors.black26),
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(200.0),
                                                        ),
                                                        elevation: 5,
                                                      ),
                                                      Container(
                                                          child: Text(
                                                            deliveryOrder.selectedOrder!.content![a].sauce!.name.toString() + ' - ',
                                                            style: TextStyle(fontSize: MyApp2.fontSize14, color: myColor2,),
                                                          )
                                                      ),
                                                      Container(
                                                          child: Text(
                                                            deliveryOrder.selectedOrder!.content![a].sauce!.price.toString() + ' €',
                                                            style: TextStyle(fontSize: MyApp2.fontSize14, color: myColor2,),
                                                          )
                                                      )
                                                    ],
                                                  )
                                              ),
                                              Row(children: [
                                                GestureDetector(
                                                  child: Icon(Icons.location_on, color: myColor2, size: MyApp2.fontSize16,),
                                                  onTap: () async {
                                                    final availableMaps = await MapLauncher.isMapAvailable(MapType.google);
                                                    if (availableMaps != null && availableMaps) {
                                                      await MapLauncher.showMarker(
                                                        mapType: MapType.google,
                                                        coords: Coords(double.parse(deliveryOrder.selectedOrder!.branch!.lat!), double.parse(deliveryOrder.selectedOrder!.branch!.long!)),
                                                        title: "Select Map",
                                                        // description: "",
                                                      );
                                                    }

                                                  },),
                                                SizedBox(width: 10,),
                                                Text(
                                                  deliveryOrder.selectedOrder!.branch!.name.toString(),
                                                  style: TextStyle(fontSize: MyApp2.fontSize14, color: myColor2,),
                                                ),
                                              ],)
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ) : Container()),
                      Divider(color: myColor2,),
                      Column(children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate("subtotal"),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: myColor,
                                  fontWeight: FontWeight.w900,

                                ),
                              ),
                              Text(
                                (double.parse(deliveryOrder.selectedOrder!.total_price.toString()) -
                                    (double.parse(deliveryOrder.selectedOrder!.tax_price.toString()) +
                                        (double.parse(deliveryOrder.selectedOrder!.shipping_price.toString()))))
                                    .toStringAsFixed(2).toString() + ' €',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: myColor2,

                                ),
                              ),
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate("shipping"),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: myColor,
                                  fontWeight: FontWeight.w900,

                                ),
                              ),
                              Text(
                                deliveryOrder.selectedOrder!.shipping_price.toString() + ' €',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: myColor2,

                                ),
                              ),
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate("tax"),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: myColor,
                                  fontWeight: FontWeight.w900,

                                ),
                              ),
                              Text(
                                deliveryOrder.selectedOrder!.tax_price.toString() + ' €',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: myColor2,

                                ),
                              ),
                            ]),
                        Divider(color: myColor2,),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate("total") + ' ' + AppLocalizations.of(context)!.translate("price"),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: myColor,
                                  fontWeight: FontWeight.w900,

                                ),
                              ),
                              Text(
                                deliveryOrder.selectedOrder!.total_price.toString() + ' €',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: myColor2,

                                ),
                              ),
                            ])
                      ],
                      )
                    ]
                )
            ),
            Column(children: [
              pending(context)
            ],)
          ]else ...[
            Container(
                padding: EdgeInsets.all(25),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '${AppLocalizations.of(context)!.translate("not_allow")}',
                        style: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: myColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ]
                )
            ),
          ]

        ],)
      ],
      ),
    );
  }


  // === Launch Navigation to Customer ===
  void _launchNavigationToCustomer() async {
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context, listen: false);
    final order = deliveryOrder.selectedOrder;
    if (order == null || order.drop_lat == null || order.drop_long == null) return;
    try {
      final availableMaps = await MapLauncher.isMapAvailable(MapType.google);
      if (availableMaps != null && availableMaps) {
        await MapLauncher.showDirections(
          mapType: MapType.google,
          destination: Coords(
            double.parse(order.drop_lat!),
            double.parse(order.drop_long!),
          ),
          destinationTitle: order.user?.name ?? order.address ?? "Customer",
          origin: order.branch?.lat != null && order.branch?.long != null
              ? Coords(
                  double.parse(order.branch!.lat!),
                  double.parse(order.branch!.long!),
                )
              : null,
          originTitle: order.branch?.name ?? "Restaurant",
        );
      }
    } catch (e) {
      // fallback: open marker only
      try {
        await MapLauncher.showMarker(
          mapType: MapType.google,
          coords: Coords(
            double.parse(order.drop_lat!),
            double.parse(order.drop_long!),
          ),
          title: order.user?.name ?? "Customer",
        );
      } catch (_) {}
    }
  }

  // === Delivery Code Verification Dialog ===
  void _showDeliveryCodeDialog(BuildContext context, String orderId) {
    final TextEditingController codeController = TextEditingController();
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Codice di Consegna', style: TextStyle(color: myColor, fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chiedi al cliente il codice di consegna a 4 cifre',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '----',
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cliente Non Trovato', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(dialogContext);
                _showDeliveryProofFlow(context, orderId);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: myColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Verifica', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                if (codeController.text.length != 4) {
                  Auth2.show('Inserisci un codice a 4 cifre');
                  return;
                }
                Navigator.pop(dialogContext);
                bool success = await deliveryOrder.confirmDeliveryWithCode(
                  context, orderId, codeController.text,
                );
                if (success) {
                  Auth2.show('Consegna confermata!');
                } else {
                  Auth2.show('Codice non valido. Riprova.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // === Delivery Photo Proof Flow ===
  void _showDeliveryProofFlow(BuildContext context, String orderId) async {
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context, listen: false);

    // 1. Request permissions
    var cameraStatus = await Permission.camera.request();
    var locationStatus = await Permission.location.request();

    if (!cameraStatus.isGranted) {
      Auth2.show('Permesso fotocamera necessario');
      return;
    }
    if (!locationStatus.isGranted) {
      Auth2.show('Permesso posizione necessario');
      return;
    }

    // 2. Take photo
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );

    if (photo == null) {
      Auth2.show('Foto annullata');
      return;
    }

    // 3. Get GPS location
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      Auth2.show('Impossibile ottenere la posizione GPS');
      return;
    }

    // 4. Show preview dialog
    File imageFile = File(photo.path);
    String timestamp = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Prova di Consegna', style: TextStyle(color: myColor, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(imageFile, height: 200, fit: BoxFit.cover),
                ),
                SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(child: Text(
                    '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  )),
                ]),
                SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(timestamp, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Annulla'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: Text('Rifai Foto'),
              onPressed: () {
                Navigator.pop(dialogContext);
                _showDeliveryProofFlow(context, orderId);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: myColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Carica', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.pop(dialogContext);
                bool success = await deliveryOrder.uploadDeliveryProofPhoto(
                  context, orderId, imageFile, position.latitude, position.longitude,
                );
                if (success) {
                  Auth2.show('Prova caricata con successo!');
                } else {
                  Auth2.show('Errore nel caricamento. Riprova.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  //action button
  Widget pending(BuildContext context) {
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context, listen: false);
    if(deliveryOrder.selectedOrder != null)
    {
      if(deliveryOrder.selectedOrder!.status == 'to delivering') {
        return Container(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                    padding: EdgeInsets.only(right: 10, left: 10),
                    width: MediaQuery
                        .of(context)
                        .size
                        .width * .5,
                    height: MediaQuery
                        .of(context)
                        .size
                        .width * .125,
                    child: MaterialButton(
                      child: Text(
                        '${AppLocalizations.of(context)!.translate("on_way")}',
                        style: TextStyle(
                          fontSize: 20,

                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      color: myColor,
                      textColor: Colors.white,
                      onPressed: () async {
                        await deliveryOrder.updateOrderState(context , 'on way', deliveryOrder.selectedOrder!.id.toString(), null);
                      },
                    )),
              ],)
        );
      }
      else if(deliveryOrder.selectedOrder!.status == 'on way') {
        return Container(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                    padding: EdgeInsets.only(right: 10, left: 10),
                    width: MediaQuery
                        .of(context)
                        .size
                        .width * .5,
                    height: MediaQuery
                        .of(context)
                        .size
                        .width * .125,
                    child: MaterialButton(
                      child: Text(
                        '${AppLocalizations.of(context)!.translate("on_delivering")}',
                        style: TextStyle(
                          fontSize: 20,

                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      color: myColor,
                      textColor: Colors.white,
                      onPressed: ()  async {
                        await deliveryOrder.updateOrderState(context,'on delivering', deliveryOrder.selectedOrder!.id.toString(), null);
                        // After pickup, automatically open navigation to the customer
                        _launchNavigationToCustomer();
                      },
                    )),
              ],)
        );
      }
      else if(deliveryOrder.selectedOrder!.status == 'on delivering') {
        return Container(
            child: Column(
              children: [
                // Button to open navigation for delivery
                Container(
                  padding: EdgeInsets.only(right: 20, left: 20, bottom: 10),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width * .15,
                  child: MaterialButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Naviga al Cliente',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    color: Colors.green,
                    textColor: Colors.white,
                    onPressed: () {
                      _launchNavigationToCustomer();
                    },
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                        padding: EdgeInsets.only(right: 5, left: 5),
                        width: MediaQuery.of(context).size.width * .45,
                        height: MediaQuery.of(context).size.width * .125,
                        child: MaterialButton(
                          child: Text(
                            'Cliente Non Trovato',
                            style: TextStyle(fontSize: 14),
                          ),
                          shape: OutlineInputBorder(
                            borderSide: BorderSide(color: myColor, width: 1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          color: Colors.white,
                          textColor: myColor,
                          onPressed: () {
                            _showDeliveryProofFlow(context, deliveryOrder.selectedOrder!.id.toString());
                          },
                        )),
                    Container(
                        padding: EdgeInsets.only(right: 5, left: 5),
                        width: MediaQuery.of(context).size.width * .45,
                        height: MediaQuery.of(context).size.width * .125,
                        child: MaterialButton(
                          child: Text(
                            '${AppLocalizations.of(context)!.translate("delivered")}',
                            style: TextStyle(fontSize: 18),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          color: myColor,
                          textColor: Colors.white,
                          onPressed: () {
                            _showDeliveryCodeDialog(context, deliveryOrder.selectedOrder!.id.toString());
                          },
                        )),
                  ],
                ),
              ],
            )
        );
      }
      else if(deliveryOrder.selectedOrder!.status == 'delivered') {
        return Container(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                    padding: EdgeInsets.only(right: 10, left: 10),
                    width: MediaQuery
                        .of(context)
                        .size
                        .width * .5,
                    height: MediaQuery
                        .of(context)
                        .size
                        .width * .125,
                    child: MaterialButton(
                      child: Text(
                        '${AppLocalizations.of(context)!.translate("user_not_found")}',
                        style: TextStyle(
                          fontSize: 20,

                        ),
                      ),
                      shape: OutlineInputBorder(
                        borderSide: BorderSide(color: myColor, width: 1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      color: Colors.white,
                      textColor: myColor,
                      onPressed: () {
                        BottomDialog().cancelDialog(context, 'User Not Found',
                            deliveryOrder.selectedOrder!.id.toString());
                      },
                    )),
                Container(
                    padding: EdgeInsets.only(right: 10, left: 10),
                    width: MediaQuery
                        .of(context)
                        .size
                        .width * .5,
                    height: MediaQuery
                        .of(context)
                        .size
                        .width * .125,
                    child: MaterialButton(
                      child: Text(
                        '${AppLocalizations.of(context)!.translate("complete")}',
                        style: TextStyle(
                          fontSize: 20,

                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      color: myColor,
                      textColor: Colors.white,
                      onPressed: () async {
                        // BottomDialog().showAlertDialog(context, 'complete',
                        //     deliveryOrder.selectedOrder.id.toString());
                        deliveryOrder.updateOrderState(context,'complete', deliveryOrder.selectedOrder!.id.toString(), null);
                      },
                    )),
              ],)
        );
      }
      else{
        return Container();
      }
    }else {
      return Container();
    }
  }
  String formatCurrency(num val, [int pad = 10]) =>
      currencyFormat.format(val).padLeft(pad);
  NumberFormat currencyFormat = NumberFormat.currency(name: 'MYR', symbol: '');
  Future<void> _loadTestData() async {
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context, listen: false);
    var id = deliveryOrder.selectedOrder!.id;
    var timestamp = deliveryOrder.selectedOrder!.ordar_at;
    var clientName = deliveryOrder.selectedOrder!.user!.name;
    var clientAddress = deliveryOrder.selectedOrder!.user!.address;
    var clientPhone = deliveryOrder.selectedOrder!.user!.mobile;
    var itemsHeaderLeft = 'Items';
    var itemsHeaderRight = '€';
    var items = [
      for(int a = 0; a < deliveryOrder.selectedOrder!.content!.length; a++)(
          TestItem(
              name: deliveryOrder.selectedOrder!.content![a].product!.name.toString() ,
              price: num.parse(deliveryOrder.selectedOrder!.content![a].product!.price.toString() ),
              quantity: num.parse(deliveryOrder.selectedOrder!.content![a].qty.toString()),
              sauce: deliveryOrder.selectedOrder!.content![a].sauce != null ? deliveryOrder.selectedOrder!.content![a].sauce!.name : null,
              sauce_price: deliveryOrder.selectedOrder!.content![a].sauce != null ? deliveryOrder.selectedOrder!.content![a].sauce!.price : null
          )
      )
    ];

    /*_printer = SunmiThermalPrinter()
      ..bitmap(img.Image.fromBytes(
          36,
          36,
          (await rootBundle.load('images/icons/logoo.png'))
              .buffer
              .asUint8List())
          .getBytes())
      ..bold()
    // ..fontSize(height: 2, width: 2)
      ..printCenter(deliveryOrder.selectedOrder.id.toString())
      ..bold()
      ..printLR('Date/Time: ', timestamp)
      ..divider()
      ..printLR('Client Name: ', clientName)
      ..printLR('Client Address: ', clientAddress)
      ..printLR('Client Mobile: ', clientPhone)
      ..divider();
    for (var item in items) {
      _printer
        ..printLeft(item.branchs)
        ..printLR(item.name, item.price.toString() + ' €')
        ..printLeft(item.quantity.toString() + ' x ' + item.price.toString() + ' €')
        ..printLeft(item.sauce.toString() + ' x ' + item.sauce_price.toString() + ' €')
        ..newLine();
    }
    _printer
      ..divider()
      ..printLR('Shipping', deliveryOrder.selectedOrder.shipping_price + ' €')
      ..printLR('Tax', deliveryOrder.selectedOrder.tax_price + ' €')
      ..divider()
      ..fontSize(height: 2, width: 2)
      ..printLR('Total', deliveryOrder.selectedOrder.total_price + ' €')
      ..newLine()
      ..fontScale();*/
  }
}

class TestItem {
  final String?name;
  final num? price;
  final num? quantity;
  final String?branchs;
  final String?sauce;
  final String?sauce_price;

  TestItem({this.name, this.price, this.quantity, this.branchs, this.sauce, this.sauce_price});
}