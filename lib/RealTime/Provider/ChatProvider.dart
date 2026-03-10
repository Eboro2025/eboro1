
import 'package:eboro/Delivery/ChatDelivery.dart';
import 'package:eboro/Helper/ChatData.dart';
import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier //
{
  List<ChatData>? Allchat;

  updateOrderChat(ID) async {
    Allchat = await chatDelivery2().getChats(ID);
    notifyListeners();
  }
//a
  addOrderChat(_message , ID) async {
    await chatDelivery2().addChat(_message,ID);
    Allchat = await chatDelivery2().getChats(ID);
    notifyListeners();
  }

}