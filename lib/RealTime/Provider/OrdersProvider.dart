
import 'package:eboro/API/Chat.dart';
import 'package:eboro/API/Order.dart';
import 'package:eboro/Client/ClickOrder.dart';
import 'package:eboro/Client/MyOrders.dart';
import 'package:eboro/Client/OrderChat.dart';
import 'package:eboro/Helper/ChatData.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:flutter/material.dart';

class OrdersProvider with ChangeNotifier
{
  List<OrderData>? All;
  OrderData Opend_Order = OrderData();
  List<ChatData>? Opend_Order_chat;

  updateOrder() async {
    All = await Order2().getOrders();
    notifyListeners();
  }

  updateChat(ID , context, [bool flag = true]) async {
    Opend_Order_chat = await Chat2().getChat(ID);
    if(flag)
    {
      Navigator.push(context, MaterialPageRoute(builder: (context) => OrderChat(id: ID.toString())),);
    }
    notifyListeners();
  }

  addChat(ID , _message, context) async {
    await Chat2().addChat(ID , _message , context);
    Opend_Order_chat = await updateChat(ID,context,false);
    notifyListeners();
  }


  updateAllOrder(context , [bool flag = true]) async {
    Progress.progressDialogue(context);
    await updateOrder();
    Progress.dimesDialog(context);
    if(flag)
    {
      Navigator.push(context, MaterialPageRoute(builder: (context) => MyOrders()));
    }
    notifyListeners();
  }

  updateSelectedOrder(context, ID , [bool flag = true]) async
  {
    Progress.progressDialogue(context);
    if(ID != null)
    {
      await updateOrder();
      Opend_Order = All![ID];
      await updateChat(ID,context,false);
    }
    if(flag)
    {
      Progress.dimesDialog(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) => ClickOrder(i: ID)));
    }
    notifyListeners();
  }

  // timer(context) async
  // {
  //   print("timer open for order : ");
  //   await updateOrder();
  //   orderTimer = Timer.periodic(Duration(minutes: 1), (Timer t) =>  timer(context));
  // }


}