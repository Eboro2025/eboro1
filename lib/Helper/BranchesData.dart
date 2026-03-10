import 'package:eboro/Helper/LightBranchData.dart';
import 'package:eboro/Helper/UserData.dart';

class BranchesData {
  final int? id;
  final LightBranchData? branch;
  final UserData? cashier;
  final UserData? delivery;
  final String?total_price;
  final String?tax_price;
  final String?shipping_price;
  final String?refuse_reason;
  final String?status;
  final String?created_at;
  final String?updated_at;


  BranchesData({
    this.id,
    this.status,
    this.branch,// For Multiple provider
    this.cashier,
    this.delivery,
    this.total_price,
    this.tax_price,
    this.shipping_price,
    this.refuse_reason,
    this.created_at,
    this.updated_at,
  });

  factory BranchesData.fromJson(Map<String, dynamic> json) {
    return BranchesData(
      id: json['id'],
      status: json['status'],
      branch:  json['branch'] != null ? LightBranchData.fromJson(json['branch']) : null, // For Multiple provider
      cashier:  json['cashier']!= null ? UserData.fromJson(json['cashier'])  : null,
      delivery: json['delivery']  != null ? UserData.fromJson(json['delivery']) : null,
      total_price: json['total_price'] != null ? json['total_price'] : null,
      tax_price: json['tax_price'] != null ? json['tax_price'] : null,
      shipping_price: json['shipping_price'] != null ? json['shipping_price'] : null,
      refuse_reason: json['refuse_reason'],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
    );
  }
}

// not important