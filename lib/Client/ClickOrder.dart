
import 'dart:async';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/RealTime/Widget/OrderInsideWidget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClickOrder extends StatefulWidget {
  final int? i;
  ClickOrder({Key? key, this.i,}) : super(key: key);
  @override
  Clickwidget  createState() => Clickwidget();
}

class Clickwidget extends State <ClickOrder> {

  Timer? ordersTimer;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(minutes: 5), (Timer t) => checkInternetState());

  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }


  checkInternetState() async {
    final order = Provider.of<UserOrderProvider>(context , listen: false);
    await order.updateOrderByID(context, order.selectedOrder.id,false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: OrderInsideWidget(i: widget.i));
  }


}