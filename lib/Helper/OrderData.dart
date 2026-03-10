import 'package:eboro/Helper/ContentData.dart';
import 'package:eboro/Helper/LightBranchData.dart';
import 'package:eboro/Helper/RateData.dart';
import 'package:eboro/Helper/UserData.dart';

class OrderData {
  final int? id;
  final UserData? user;
  final String?drop_lat;
  final String?drop_long;
  final String?address;
  final String?total_price;
  // final List<BranchesData>? branch;//BranchData
  final LightBranchData? branch;//BranchData
  final String? comment;//comment
  final int? gratuity;//gratuity
  final String? options;//options
  // final List<BranchesData> branches;
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
  final String? accepted_at;
  final String? shipped_at;
  final String? delivering_at;
  final String? delivered_at;
  final int? user_orders_count;
  final String? delivery_code;
  final String? delivery_proof_image;
  final Map<String, dynamic>? refund_request;


  OrderData({
    this.id,
    this.user,
    this.drop_lat,
    this.drop_long,
    this.address,
    this.total_price,
    this.branch,
    this.comment,
    this.gratuity,
    this.options,
    // this.branches,
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
    this.accepted_at,
    this.shipped_at,
    this.delivering_at,
    this.delivered_at,
    this.user_orders_count,
    this.delivery_code,
    this.delivery_proof_image,
    this.refund_request,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: json['id'],
      user: json['user'] != null ?  UserData.fromJson(json['user']) : null,
      drop_lat: json['drop_lat'],
      drop_long: json['drop_long'],
      address: json['address'],
      comment: json['comment'],
      gratuity: json['gratuity'],
      options: json['options'],
      total_price: json['total_price'],
      // branch: json['branch'] != null ?  LightBranchData.fromJson(json['branch']): null,
      // branches: json['branches'] != null ? (json['branches'] as List).map((i) => BranchesData.fromJson(i)).toList() : null,
      // branch: json['branch'] != null ? (json['branch'] as List).map((i) => BranchesData.fromJson(i)).toList() : null,
      branch: json['branch'] != null ?  LightBranchData.fromJson(json['branch']): null,
      status: json['status'],
      payment: json['payment'].toString(),
      tax_price: json['tax_price'],
      shipping_price: json['shipping_price'],
      cashier: json['cashier'] != null ?  UserData.fromJson(json['cashier']): null,
      delivery:  json['delivery'] != null ? UserData.fromJson(json['delivery']): null,
      content: json['content'] != null && json['content'] is List ?  (json['content'] as List).map((i) => ContentData.fromJson(i)).toList() : null ,
      Rate:  json['Rate'] != null && json['Rate'] is List ?  (json['Rate'] as List).map((i) => RateData.fromJson(i)).toList() : null ,
      Delivery_time: json['Delivery_time'] != null ? int.tryParse(json['Delivery_time'].toString()) : null,
      Delivery_Price: json['Delivery_Price'],
      ordar_at: json['ordar_at'],
      created_at: json['created_at'],
      accepted_at: json['accepted_at'],
      shipped_at: json['shipped_at'],
      delivering_at: json['delivering_at'],
      delivered_at: json['delivered_at'],
      user_orders_count: json['user_orders_count'] != null ? int.tryParse(json['user_orders_count'].toString()) : null,
      delivery_code: json['delivery_code'],
      delivery_proof_image: json['delivery_proof_image'],
      refund_request: json['refund_request'] != null && json['refund_request'] is Map
          ? Map<String, dynamic>.from(json['refund_request'])
          : null,
    );
  }
}
