class CartItemData {
  final int? id;
  final int? qty;
  final int? product_id;
  final int? provider_id;
  final String? product_name;
  final String? product_image;
  final double? product_price;
  final List<CartSauceData>? sauces;
  final List<CartExtraData>? extras;

  CartItemData({
    this.id,
    this.qty,
    this.product_id,
    this.provider_id,
    this.product_name,
    this.product_image,
    this.product_price,
    this.sauces,
    this.extras,
  });

  factory CartItemData.fromJson(Map<String, dynamic> json) {
    List<CartSauceData>? saucesList;
    if (json['sauces'] != null) {
      saucesList = List<CartSauceData>.from(
          json['sauces'].map((x) => CartSauceData.fromJson(x)));
    }

    List<CartExtraData>? extrasList;
    // جرب أكثر من مفتاح محتمل
    final extrasData = json['extras'] ?? json['cart_item_extras'] ?? json['extra_items'];
    if (extrasData != null && extrasData is List) {
      extrasList = List<CartExtraData>.from(
          extrasData.map((x) => CartExtraData.fromJson(x)));
    }

    return CartItemData(
      id: json['id'],
      qty: json['qty'],
      provider_id: json['provider_id'],
      product_id: json['product_id'],
      product_name: json['product_name'],
      product_image: json['product_image'],
      product_price: double.parse(json['product_price'].toString()),
      sauces: saucesList,
      extras: extrasList,
    );
  }
}

class CartExtraData {
  final int? id;
  final String? name;
  final double? price;

  CartExtraData({this.id, this.name, this.price});

  factory CartExtraData.fromJson(Map<String, dynamic> json) {
    return CartExtraData(
      id: json['id'] ?? json['extra_id'] ?? json['sauce_id'],
      name: json['name'] ?? json['extra_name'] ?? json['sauce_name'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : (json['extra_price'] != null
              ? double.tryParse(json['extra_price'].toString())
              : null),
    );
  }
}

class CartSauceData {
  final int? id;
  final String? name;
  final String? image;
  final double? price;

  CartSauceData({
    this.id,
    this.name,
    this.image,
    this.price,
  });

  factory CartSauceData.fromJson(Map<String, dynamic> json) {
    return CartSauceData(
      id: json['id'] != null ? json['id'] : null,
      name: json['name'] != null ? json['name'] : null,
      image: json['image'] != null ? json['image'] : null,
      price:
          json['price'] != null ? double.parse(json['price'].toString()) : null,
    );
  }
}
