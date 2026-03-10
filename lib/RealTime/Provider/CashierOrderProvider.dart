import 'package:collection/collection.dart' show IterableExtension;
import 'package:eboro/API/CashierAPI.dart';
import 'package:eboro/API/Order.dart';

import 'package:eboro/Helper/BranchStaffData.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/Helper/ProductData.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:flutter/material.dart';
//a
class CashierOrderProvider with ChangeNotifier
{
  List<OrderData>? All;
  List<BranchStaffData>?  BranchStaff;
  List<ProductData>?  Products;

  OrderData? OOrder = new OrderData();






  updateOrder() async
  {

    if(Products != null &&Products!.length > 0)
      Products!.clear();

    BranchStaff = await CashierAPI2().branchStaff();
    All = await CashierAPI2().getOrders(null , BranchStaff![0].branch!.id);
    Products = await CashierAPI2().getProducts(BranchStaff![0].branch!.provider!.id);

    if(OOrder != null && All != null && All!.length > 0)
      OOrder = All!.firstWhereOrNull((element) => OOrder!.id == element.id);

    notifyListeners();
  }

  updateOrderByID(iD , context ,   bool flag , [player]) async {
    // Progress.progressDialogue(context);
    BranchStaff = await CashierAPI2().branchStaff();
    var newOrder = await CashierAPI2().getOrders(iD , BranchStaff![0].branch!.id);
    if(newOrder != null)
      OOrder = newOrder[0];
    // Progress.dimesDialog(context);
    if(flag)
    {
      Progress.dimesDialog(context);
     
    }
    notifyListeners();
  }

  ordersStateEdit(String state, String id, String? reason, context, {int? deliveryTime}) async
  {
    await Order2().editOrder(state, id, reason, deliveryTime: deliveryTime);
    await updateOrder();
    notifyListeners();
  }

  productsEdit(String name, String price, String id,String start_outofstock,String end_outofstock, context) async
  {
    await CashierAPI2().editProducts(name, price, id , start_outofstock, end_outofstock, context);
    Products = await CashierAPI2().getProducts(BranchStaff![0].branch!.provider!.id);
    notifyListeners();
  }



}