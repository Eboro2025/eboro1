import 'package:eboro/Helper/CartItemData.dart';

class CartData {
  final int? id;
  final double? total_price;
  final List<CartItemData>? cart_items;

  CartData({
    this.id,
    this.total_price,
    this.cart_items,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    return CartData(
      id: json['id'],
      total_price: double.parse(json['total_price'].toString()),
      cart_items: json['cart_items'] != null && json['cart_items'] is List ? (json['cart_items'] as List).map((i) => CartItemData.fromJson(i)).toList() : [],
    );
  }
}
