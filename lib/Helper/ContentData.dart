import 'package:eboro/Helper/CartItemData.dart';
import 'package:eboro/Helper/ProductData.dart';

class ContentData {
  final int? id;
  final ProductData? product;
  final ProductData? sauce;
  final List<CartSauceData>? sauces;
  final String? price;
  final String? comment;
  final int? qty;
  final List<CartExtraData>? extras;

  ContentData({
    this.id,
    this.product,
    this.price,
    this.sauce,
    this.sauces,
    this.comment,
    this.qty,
    this.extras,
  });

  factory ContentData.fromJson(Map<String, dynamic> json) {
    List<CartSauceData>? saucesList;
    if (json['sauces'] != null) {
      saucesList = List<CartSauceData>.from(
          json['sauces'].map((x) => CartSauceData.fromJson(x)));
    }
    List<CartExtraData>? extrasList;
    if (json['extras'] != null && json['extras'] is List) {
      extrasList = List<CartExtraData>.from(
          json['extras'].map((x) => CartExtraData.fromJson(x)));
    }
    return ContentData(
      id: json['id'],
      product: json['product'] != null
          ? ProductData.fromJson(json['product'])
          : null,
      sauce: json['sauce'] != null ? ProductData.fromJson(json['sauce']) : null,
      price: json['price'].toString(),
      comment: json['comment'],
      sauces: saucesList,
      qty: json['qty'],
      extras: extrasList,
    );
  }
}
