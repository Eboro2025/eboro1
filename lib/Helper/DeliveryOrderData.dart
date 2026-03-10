import 'package:eboro/Helper/BranchData.dart';
import 'package:eboro/Helper/ContentData.dart';
import 'package:eboro/Helper/RateData.dart';
import 'package:eboro/Helper/UserData.dart';

class DeliveryOrderData {
  final int? id;
  final UserData? user;
  final String?drop_lat;
  final String?drop_long;
  final String?address;
  final String?total_price;
  final List<BranchData>? branch;
  final String?status;
  final String?payment;
  final String?tax_price;
  final String?shipping_price;
  final UserData? cashier;
  final UserData? delivery;
  final List<ContentData>? content;
  final List<RateData>? Rate;
  final int? Delivery_time;
  final String?Delivery_Price;
  final String?ordar_at;
  final String?created_at;


  DeliveryOrderData({
    this.id,
    this.user,
    this.drop_lat,
    this.drop_long,
    this.address,
    this.total_price,
    this.branch,
    this.status,
    this.payment,
    this.tax_price,
    this.shipping_price,
    this.cashier,
    this.delivery,
    this.content,
    this.Rate,
    this.Delivery_time,
    this.Delivery_Price,
    this.ordar_at,
    this.created_at,
  });

  factory DeliveryOrderData.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderData(
      id: json['id'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      drop_lat: json['drop_lat'],
      drop_long: json['drop_long'],
      address: json['address'],
      total_price: json['total_price'],
      branch: json['branch'] != null && json['branch'] is List ? (json['branch'] as List).map((i) => BranchData.fromJson(i)).toList() : null,
      status: json['status'],
      payment: json['payment'].toString(),
      tax_price: json['tax_price'],
      shipping_price: json['shipping_price'],
      cashier: json['cashier'] != null ?  UserData.fromJson(json['cashier']): null,
      delivery:  json['delivery'] != null ? UserData.fromJson(json['delivery']): null,
      content: json['content'] != null && json['content'] is List ? (json['content'] as List).map((i) => ContentData.fromJson(i)).toList() : [],
      Rate:  json['Rate'] != null && json['Rate'] is List ?  (json['Rate'] as List).map((i) => RateData.fromJson(i)).toList() : null ,
      Delivery_time: json['Delivery_time'] != null ? int.tryParse(json['Delivery_time'].toString()) : null,
      Delivery_Price: json['Delivery_Price'],
      ordar_at: json['ordar_at'],
      created_at: json['created_at'],
    );
  }
}
