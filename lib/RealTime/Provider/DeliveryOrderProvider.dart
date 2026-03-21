
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/DeliveryAPI.dart';
import 'package:eboro/API/Order.dart';
import 'package:eboro/All/SendNotification.dart';
import 'package:eboro/Delivery/ClickOrderDelivery.dart';
import 'package:eboro/Delivery/Delivery.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:flutter/material.dart';
import 'package:eboro/main.dart';
class DeliveryOrderProvider with ChangeNotifier //
{
  List<OrderData>? order = List<OrderData>.empty(growable: true);
  List<OrderData>? orderDelivery = List<OrderData>.empty(growable: true);
  OrderData? selectedOrder = OrderData();

  AudioCache? cache; // you have this
  AudioPlayer? player; // create this


  void _playFile() async{
    await player!.play(UrlSource('$globalUrl/public/uploads/sound/sound.mp3') , mode: PlayerMode.lowLatency, volume: 5);
  }


  void _stopFile() {
    player?.stop();
  }

  updateOrder() async
  {
    await DeliveryAPI2().editLocation();
    orderDelivery = await DeliveryAPI2().deliveryOrder();
    order = await DeliveryAPI2().getOrders(null , null, Auth2.user!.id);

    if(selectedOrder != null && orderDelivery != null && orderDelivery!.length > 0)
      selectedOrder = orderDelivery!.firstWhereOrNull((element) => selectedOrder!.id == element.id);


    if (orderDelivery != null && orderDelivery!.where((element) => element.status!.toLowerCase() == "to delivering").isNotEmpty)
    {
      if(player == null || player!.state != PlayerState.playing)
      {
        _stopFile();
        _playFile();
        SendNotification.PushNotification("Eboro Notifications","Find out ${orderDelivery!.length} orders , you have 1 min to accept one of them");
      }
    }
    else
    {
      if(player != null  && player!.state == PlayerState.playing)
        _stopFile();
    }
    notifyListeners();
  }

  getOrder(context, bool flag) async {
    order = await DeliveryAPI2().getOrders(null , null, Auth2.user!.id);

    if(flag)
    {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Delivery()));
    }
    notifyListeners();
  }

  bool _isNavigatingToOrder = false;

  updateOrderByID(iD , context , bool flag) async {
    if (_isNavigatingToOrder) return; // منع التكرار
    _isNavigatingToOrder = true;
    // Progress.progressDialogue(context);
    var newOrder = await DeliveryAPI2().getOrders(iD);
    if(newOrder != null)
      selectedOrder = newOrder[0];
    // Progress.dimesDialog(context);
    if(flag)
    {
      Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryClickOrder()));
    }
    _isNavigatingToOrder = false;
    notifyListeners();
  }

  updateOrderState(context , status, iD , reason) async {
    Progress.progressDialogue(context);
    await Order2().editOrder(status, iD, reason);
    // await updateOrder first to refresh lists (sound, delivery queue, etc.)
    await updateOrder();
    // Then fetch the specific order to ensure selectedOrder has the latest state
    var newOrder = await DeliveryAPI2().getOrders(iD);
    if(newOrder != null)
    {
      selectedOrder = newOrder[0];
    }
    Progress.dimesDialog(context);
    notifyListeners();
  }

  /// Confirm delivery using the customer's code
  Future<bool> confirmDeliveryWithCode(
      BuildContext context, String orderId, String code) async {
    Progress.progressDialogue(context);
    try {
      var result = await Order2().confirmDeliveryCode(orderId, code);
      if (result['success'] == true) {
        await updateOrder();
        var newOrder = await DeliveryAPI2().getOrders(orderId);
        if (newOrder != null) {
          selectedOrder = newOrder[0];
        }
        Progress.dimesDialog(context);
        notifyListeners();
        return true;
      } else {
        Progress.dimesDialog(context);
        return false;
      }
    } catch (e) {
      Progress.dimesDialog(context);
      return false;
    }
  }

  /// Upload photo proof when customer not found
  Future<bool> uploadDeliveryProofPhoto(
      BuildContext context, String orderId, File imageFile,
      double lat, double lng) async {
    Progress.progressDialogue(context);
    try {
      var result =
          await Order2().uploadDeliveryProof(orderId, imageFile, lat, lng);
      if (result['success'] == true) {
        await updateOrder();
        var newOrder = await DeliveryAPI2().getOrders(orderId);
        if (newOrder != null) {
          selectedOrder = newOrder[0];
        }
        Progress.dimesDialog(context);
        notifyListeners();
        return true;
      } else {
        Progress.dimesDialog(context);
        return false;
      }
    } catch (e) {
      Progress.dimesDialog(context);
      return false;
    }
  }

  updateOrderTimerByID(iD) async {
    var newOrder = await ((DeliveryAPI2().getOrders(iD) as FutureOr<List<OrderData>?>) as FutureOr<List<OrderData>>);
    selectedOrder = newOrder[0];
    notifyListeners();
  }




}