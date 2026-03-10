import 'package:eboro/Helper/LightBranchData.dart';
import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/Helper/UserData.dart';

class BranchData {
  final int? id;
  final String?name;
  final String?description;
  final String?address;
  final String?lat;
  final String?long;
  final String?open_days;
  final String?open_time;
  final String?close_time;
  final String?status;
  final bool?has_delivery;
  final String?hot_line;
  final ProviderData? provider;
  final String?created_at;

  final LightBranchData? branch;
  final UserData? cashier;
  final UserData? delivery;
  final String?total_price;
  final String?tax_price;
  final String?shipping_price;

  BranchData({
    this.id,
    this.name,
    this.description,
    this.address,
    this.lat,
    this.long,
    this.open_days,
    this.open_time,
    this.close_time,
    this.status,
    this.has_delivery,
    this.hot_line,
    this.provider,
    this.created_at,

    this.branch,// For Multiple provider
    this.cashier,
    this.delivery,
    this.total_price,
    this.tax_price,
    this.shipping_price,
  });

  factory BranchData.fromJson(Map<String, dynamic> json) {
    return BranchData(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      lat: json['lat'].toString(),
      long: json['long'].toString(),
      open_days: json['open_days'],
      open_time: json['open_time'],
      close_time: json['close_time'],
      status: json['status'],
      has_delivery: json['has_delivery'],
      hot_line: json['hot_line'],
      provider: json['provider'] != null ? ProviderData.fromJson(json['provider']) : null,
      branch: json['branch'] != null ? LightBranchData.fromJson(json['branch']) : null,
      created_at: json['created_at'],
      cashier:  json['cashier']!= null ? UserData.fromJson(json['cashier'])  : null,
      delivery: json['delivery']  != null ? UserData.fromJson(json['delivery']) : null,
      total_price: json['total_price'] != null ? json['total_price'] : null,
      tax_price: json['tax_price'] != null ? json['tax_price'] : null,
      shipping_price: json['shipping_price'] != null ? json['shipping_price'] : null,


    );
  }
}
