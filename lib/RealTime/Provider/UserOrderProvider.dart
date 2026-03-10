import 'dart:async';
import 'dart:io';

import 'package:eboro/API/Chat.dart';
import 'package:eboro/API/Order.dart';
import 'package:eboro/Client/ClickOrder.dart';
import 'package:eboro/Client/MyOrders.dart';
import 'package:eboro/Client/OrderChat.dart';
import 'package:eboro/Helper/ChatData.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:flutter/material.dart';

class UserOrderProvider with ChangeNotifier {
  List<OrderData>? order;
  OrderData selectedOrder = OrderData();
  OrderData OldOrder = OrderData();
  List<ChatData>? chat;
  Timer? orderTimer;
  int? ID;

  /// Ensure rating dialog opens only once per orderId
  final Set<int> _shownRateForOrderIds = {};

  bool hasShownRate(int orderId) => _shownRateForOrderIds.contains(orderId);

  void markRateShown(int orderId) {
    _shownRateForOrderIds.add(orderId);
  }

  /// Cache: last time orders were fetched
  DateTime? _lastFetchTime;
  bool _isFetching = false;

  /// Load orders with 30-second cache
  updateOrder({bool force = false}) async {
    // If there is a request in progress, don't make another one
    if (_isFetching) return;

    // If not forced and loaded less than 30 seconds ago, return cache
    if (!force && _lastFetchTime != null && order != null) {
      final diff = DateTime.now().difference(_lastFetchTime!).inSeconds;
      if (diff < 30) {
        return;
      }
    }

    _isFetching = true;
    order = await Order2().getOrders();
    _lastFetchTime = DateTime.now();
    _isFetching = false;
    notifyListeners();
  }

  updateChat(ID, context, [bool flag = true]) async {
    chat = await Chat2().getChat(ID);
    if (flag) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderChat(id: ID.toString())),
      );
    }
    notifyListeners();
  }

  addChat(ID, _message, context, {File? imageFile}) async {
    await Chat2().addChat(ID, _message, context, imageFile: imageFile);
    chat = await Chat2().getChat(ID);
    notifyListeners();
  }

  updateOpenOrder(context, [bool flag = true]) async {
    Progress.progressDialogue(context);
    await updateOrder(force: true);
    Progress.dimesDialog(context);
    if (flag) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyOrders()),
      );
    }
    notifyListeners();
  }

  updateOrderByID(context, iD, bool flag) async {
    var branchId = selectedOrder.branch?.id;
    var newOrder = await Order2().getOrders(iD, branchId);
    if (newOrder != null && newOrder.isNotEmpty) selectedOrder = newOrder[0];
    if (flag) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ClickOrder(i: ID)),
      );
    }
    notifyListeners();
  }

  updateSelectedOrder(context, ID, [bool flag = true]) async {
    Progress.progressDialogue(context);
    if (ID != null) {
      this.ID = ID;
      if (order != null && order!.length > ID) {
        selectedOrder = order![ID];
        // Fetch full data with branch_id to get Delivery_time
        var branchId = selectedOrder.branch?.id;
        if (selectedOrder.id != null) {
          var freshOrder = await Order2().getOrders(selectedOrder.id, branchId);
          if (freshOrder != null && freshOrder.isNotEmpty) {
            selectedOrder = freshOrder[0];
          }
        }
      }
    }
    Progress.dimesDialog(context);
    if (flag) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ClickOrder(i: ID)),
      );
    }
    notifyListeners();
  }

  /// Submit order rating using the real API: Order2().Rate(orderId, value, comment)
  /// Since the API accepts comment only, we include the reasons inside the comment in a structured way.
  Future<void> submitOrderRate({
    required int orderId,
    required int value,
    required String comment,
    required List<String> reasons,
    required BuildContext context,
  }) async {
    try {
      Progress.progressDialogue(context);

      final reasonsText =
          reasons.isEmpty ? "" : "Motivi: ${reasons.join(', ')}\n";
      final finalComment = "${reasonsText}${comment.trim()}".trim();

      await Order2().Rate(orderId, value, finalComment);

      Progress.dimesDialog(context);

      // Update data after submission
      await updateOrder(force: true);
      notifyListeners();
    } catch (e) {
      Progress.dimesDialog(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante l'invio della valutazione: $e")),
      );
    }
  }
}
