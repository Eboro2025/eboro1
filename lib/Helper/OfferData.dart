import 'package:eboro/API/Auth.dart';

class OfferData {
  final int? id;
  final int? branch_id;
  final int? product_id;
  final int? gift_product_id;
  final String? offer_type;
  final String? offer_price;
  final String? offer_value;
  final String? code;
  final String? phone;
  final double? min_order_amount;
  final double? min_spend;
  final double? fixed_discount_value;
  final bool? is_for_new_customers;
  final String? start_at;
  final String? end_at;
  final String? delivery_api_token;
  final String? created_at;
  final String? updated_at;

  // Gift product details for 2x1 offers
  final String? giftProductName;
  final String? giftProductNameIt;
  final String? giftProductNameEn;
  final String? giftProductImage;
  final double? giftProductPrice;

  OfferData({
    this.id,
    this.branch_id,
    this.product_id,
    this.gift_product_id,
    this.offer_type,
    this.offer_price,
    this.offer_value,
    this.code,
    this.phone,
    this.min_order_amount,
    this.min_spend,
    this.fixed_discount_value,
    this.is_for_new_customers,
    this.start_at,
    this.end_at,
    this.delivery_api_token,
    this.created_at,
    this.updated_at,
    this.giftProductName,
    this.giftProductNameIt,
    this.giftProductNameEn,
    this.giftProductImage,
    this.giftProductPrice,
  });

  factory OfferData.fromJson(Map<String, dynamic> json) {
    // Parse gift product data if available
    final giftProduct = json['gift_product'];

    return OfferData(
      id: json['id'],
      branch_id: json['branch_id'],
      product_id: json['product_id'],
      gift_product_id: json['gift_product_id'],
      offer_type: json['offer_type'],
      offer_price: json['offer_price']?.toString(),
      // API returns 'value', Flutter expects 'offer_value'
      offer_value: json['offer_value']?.toString() ?? json['value']?.toString(),
      code: json['code'],
      phone: json['phone'],
      min_order_amount: json['min_order_amount'] != null
          ? double.tryParse(json['min_order_amount'].toString())
          : null,
      min_spend: json['min_spend'] != null
          ? double.tryParse(json['min_spend'].toString())
          : null,
      fixed_discount_value: json['fixed_discount_value'] != null
          ? double.tryParse(json['fixed_discount_value'].toString())
          : null,
      is_for_new_customers: json['is_for_new_customers'] == 1 ||
          json['is_for_new_customers'] == true,
      start_at: json['start_at'],
      end_at: json['end_at'],
      delivery_api_token: json['delivery_api_token'],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
      // Gift product details
      giftProductName: giftProduct != null ? giftProduct['name'] : null,
      giftProductNameIt: giftProduct != null ? giftProduct['name_it'] : null,
      giftProductNameEn: giftProduct != null ? giftProduct['name_en'] : null,
      giftProductImage: giftProduct != null ? giftProduct['image'] : null,
      giftProductPrice: giftProduct != null && giftProduct['price'] != null
          ? double.tryParse(giftProduct['price'].toString())
          : null,
    );
  }

  /// تحقق إذا كان العرض نشط حالياً
  bool get isActive {
    if (start_at == null || end_at == null) return false;

    try {
      DateTime now = DateTime.now();
      DateTime start = safeDateParse(start_at!);
      DateTime end = safeDateParse(end_at!);

      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  /// تحقق إذا كان العرض توصيل مجاني
  bool get isFreeDelivery {
    return offer_type == 'free_delivery' ||
        offer_type == 'two_for_one_free_delivery';
  }

  /// تحقق إذا كان العرض 2x1 أو 1+1
  bool get isTwoForOne {
    return offer_type == 'two_for_one' ||
        offer_type == 'one_plus_one' ||
        offer_type == 'two_for_one_free_delivery';
  }

  /// تحقق إذا كان العرض خصم
  bool get isDiscount {
    return offer_type == 'discount' || offer_type == 'fixed_discount';
  }

  /// Check if offer has gift product
  bool get hasGiftProduct {
    return gift_product_id != null && giftProductName != null;
  }

  /// Get gift product name based on language
  String getGiftProductName(String lang) {
    if (lang == 'en' && giftProductNameEn != null) {
      return giftProductNameEn!;
    }
    return giftProductNameIt ?? giftProductName ?? '';
  }

  /// Get gift product image URL
  String? getGiftProductImageUrl(String baseUrl) {
    if (giftProductImage == null || giftProductImage!.isEmpty) {
      return null;
    }
    // Check if it's already a full URL
    if (giftProductImage!.startsWith('http')) {
      return giftProductImage;
    }
    return '$baseUrl/uploads/Product/$giftProductImage';
  }
}
