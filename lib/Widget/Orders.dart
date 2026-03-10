import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Chat.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:date_format/date_format.dart';
import 'package:provider/provider.dart';

class Orders extends StatefulWidget {
  @override
  Orders2 createState() => Orders2();
}

class Orders2 extends State<Orders> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final order = Provider.of<UserOrderProvider>(context);
    return Container(
      child: Column(children: [
        for (int i = 0; i < order.order!.length; i++)
          (Container(
              padding: EdgeInsets.only(right: 15, left: 15, top: 5, bottom: 5),
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  padding:
                      EdgeInsets.only(right: 20, left: 20, top: 5, bottom: 5),
                  child: GestureDetector(
                    child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
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
                          padding: EdgeInsets.only(
                              right: 30, left: 30, top: 10, bottom: 10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.order![i].created_at != null &&
                                              order.order![i].created_at!
                                                  .isNotEmpty
                                          ? formatDate(
                                              safeDateParse(
                                                  order.order![i].created_at!),
                                              [
                                                  dd,
                                                  '/',
                                                  mm,
                                                  '/',
                                                  yyyy
                                                ]).toString()
                                          : 'N/A',
                                      style: TextStyle(
                                          fontSize: MyApp2.fontSize14),
                                    ),
                                    Text(
                                      order.order![i].created_at != null &&
                                              order.order![i].created_at!
                                                  .isNotEmpty
                                          ? formatDate(
                                              safeDateParse(
                                                  order.order![i].created_at!),
                                              [hh, ':', nn, " ", am]).toString()
                                          : '',
                                      style: TextStyle(
                                          fontSize: MyApp2.fontSize14),
                                    ),
                                    Text(
                                        '${AppLocalizations.of(context)!.translate("order_id")} : #' +
                                            order.order![i].id.toString(),
                                        style: TextStyle(
                                            color: Colors.black45,
                                            fontSize: MyApp2.fontSize14)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        '${AppLocalizations.of(context)!.translate("price")} : ',
                                        style: TextStyle(
                                            color: Colors.black45,
                                            fontSize: MyApp2.fontSize14)),
                                    Text(
                                        order.order![i].total_price.toString() +
                                            ' € ',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: MyApp2.fontSize14)),
                                    Text(
                                        '${AppLocalizations.of(context)!.translate("status")} : ',
                                        style: TextStyle(
                                            color: Colors.black45,
                                            fontSize: MyApp2.fontSize14)),
                                    if (order.order![i].status == 'pending')
                                      Text(
                                          '${AppLocalizations.of(context)!.translate("pending")}',
                                          style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: MyApp2.fontSize14)),
                                    if (order.order![i].status == 'in progress')
                                      Text(
                                          '${AppLocalizations.of(context)!.translate("in_progress")}',
                                          style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: MyApp2.fontSize14)),
                                    if (order.order![i].status ==
                                            'to delivering' ||
                                        order.order![i].status == 'on way')
                                      Text(
                                          '${AppLocalizations.of(context)!.translate("to_delivering")}',
                                          style: TextStyle(
                                              color: Colors.cyan,
                                              fontSize: MyApp2.fontSize14)),
                                    if (order.order![i].status ==
                                        'on delivering')
                                      Text(
                                          '${AppLocalizations.of(context)!.translate("on_delivering")}',
                                          style: TextStyle(
                                              color: Colors.indigo,
                                              fontSize: MyApp2.fontSize14)),
                                    if (order.order![i].status == 'delivered')
                                      Text(
                                          '${AppLocalizations.of(context)!.translate("delivered")}',
                                          style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: MyApp2.fontSize14)),
                                    if (order.order![i].status == 'complete')
                                      Text(
                                          '${AppLocalizations.of(context)!.translate("complete")}',
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: MyApp2.fontSize14)),
                                    if (order.order![i].status == 'cancelled')
                                      Text(
                                          '${AppLocalizations.of(context)!.translate("cancelled")}',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: MyApp2.fontSize14)),
                                    if (order.order![i].status ==
                                        'User Not Found')
                                      Text(
                                          '${AppLocalizations.of(context)!.translate("user_not_found")}',
                                          style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: MyApp2.fontSize14)),
                                    if (order.order![i].status ==
                                        'SyS_cancelled')
                                      Text(
                                          '${AppLocalizations.of(context)!.translate("SyS_cancelled")}',
                                          style: TextStyle(
                                              color: Colors.deepPurple,
                                              fontSize: MyApp2.fontSize14)),
                                  ],
                                ),
                              ]),
                        )),
                    onTap: () {
                      Chat2().getChat(order.order![i].id);
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => ClickOrder(i: i)));
                    },
                  ),
                ),
                new Align(
                  alignment: Alignment.centerLeft,
                  child: Ink(
                    child: Column(
                      children: [
                        if (order.order![i].status == 'pending')
                          Container(
                            padding: EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.deepOrange),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Image.asset(
                              'images/icons/pending.png',
                              height: 25,
                              width: 25,
                              color: Colors.deepOrange,
                            ),
                          ),
                        if (order.order![i].status == 'in progress')
                          Container(
                            padding: EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.lightBlue),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Image.asset(
                              'images/icons/sync.png',
                              height: 25,
                              width: 25,
                              color: Colors.blue,
                            ),
                          ),
                        if (order.order![i].status == 'to delivering' ||
                            order.order![i].status == 'on way')
                          Container(
                            padding: EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.cyan),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Image.asset(
                              'images/icons/shopping-bagg.png',
                              height: 25,
                              width: 25,
                              color: Colors.cyan,
                            ),
                          ),
                        if (order.order![i].status == 'on delivering')
                          Container(
                            padding: EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.indigo),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Image.asset(
                              'images/icons/scooterr.png',
                              height: 25,
                              width: 25,
                              color: Colors.indigo,
                            ),
                          ),
                        if (order.order![i].status == 'delivered')
                          Container(
                            padding: EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.amber),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Image.asset(
                              'images/icons/checkk.png',
                              height: 25,
                              width: 25,
                              color: Colors.amber,
                            ),
                          ),
                        if (order.order![i].status == 'cancelled')
                          Container(
                            padding: EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.red),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Image.asset(
                              'images/icons/close.png',
                              height: 25,
                              width: 25,
                              color: Colors.red,
                            ),
                          ),
                        if (order.order![i].status == 'complete')
                          Container(
                            padding: EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.green),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Image.asset(
                              'images/icons/check.png',
                              height: 25,
                              width: 25,
                              color: Colors.green,
                            ),
                          ),
                        if (order.order![i].status == 'User Not Found')
                          Container(
                            padding: EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.orange),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Image.asset(
                              'images/icons/unknown.png',
                              height: 25,
                              width: 25,
                              color: Colors.orange,
                            ),
                          ),
                        if (order.order![i].status == 'SyS_cancelled')
                          Container(
                            padding: EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.deepPurple),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Image.asset(
                              'images/icons/sys.png',
                              height: 25,
                              width: 25,
                              color: Colors.deepPurple,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ])))
      ]),
    );
  }
}
