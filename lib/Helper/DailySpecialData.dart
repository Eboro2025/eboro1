import 'package:eboro/Helper/ShippingData.dart';

class DailySpecialData {
  final int? id;
  final int? productId;
  final int? branchId;
  final int? providerId;
  final String? providerName;
  final String? providerLogo;
  final String? productName;
  final String? productNameIt;
  final String? productNameEn;
  final String? productImage;
  final String? productDescription;
  final double? originalPrice;
  final double? specialPrice;
  final double? effectivePrice;
  final int? discountPercentage;
  final String? titleIt;
  final String? titleEn;
  final String? descriptionIt;
  final String? descriptionEn;
  final String? specialDate;

  /// بيانات التوصيل من المحل الأصلي (المسافة، السعر، الوقت، الحد الأدنى)
  ShippingData? delivery;
  /// هل المحل خارج نطاق التوصيل
  bool outOfDeliveryRange = false;

  DailySpecialData({
    this.id,
    this.productId,
    this.branchId,
    this.providerId,
    this.providerName,
    this.providerLogo,
    this.productName,
    this.productNameIt,
    this.productNameEn,
    this.productImage,
    this.productDescription,
    this.originalPrice,
    this.specialPrice,
    this.effectivePrice,
    this.discountPercentage,
    this.titleIt,
    this.titleEn,
    this.descriptionIt,
    this.descriptionEn,
    this.specialDate,
    this.delivery,
  });

  factory DailySpecialData.fromJson(Map<String, dynamic> json) {
    return DailySpecialData(
      id: json['id'],
      productId: json['product_id'],
      branchId: json['branch_id'],
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      providerLogo: json['provider_logo'],
      productName: json['product_name'],
      productNameIt: json['product_name_it'],
      productNameEn: json['product_name_en'],
      productImage: json['product_image'],
      productDescription: json['product_description'],
      originalPrice: json['original_price'] != null
          ? double.tryParse(json['original_price'].toString())
          : null,
      specialPrice: json['special_price'] != null
          ? double.tryParse(json['special_price'].toString())
          : null,
      effectivePrice: json['effective_price'] != null
          ? double.tryParse(json['effective_price'].toString())
          : null,
      discountPercentage: json['discount_percentage'],
      titleIt: json['title_it'],
      titleEn: json['title_en'],
      descriptionIt: json['description_it'],
      descriptionEn: json['description_en'],
      specialDate: json['special_date'],
    );
  }

  /// Get title based on language
  String getTitle(String lang) {
    if (lang == 'en') {
      return titleEn ?? titleIt ?? 'Dish of the Day';
    }
    return titleIt ?? 'Piatto del Giorno';
  }

  /// Get product name based on language
  String getProductName(String lang) {
    if (lang == 'en') {
      return productNameEn ?? productNameIt ?? productName ?? '';
    }
    return productNameIt ?? productName ?? '';
  }

  /// Get description based on language
  String? getDescription(String lang) {
    if (lang == 'en') {
      return descriptionEn ?? descriptionIt;
    }
    return descriptionIt;
  }

  /// Check if there's a discount
  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;

  /// Get the price to display
  double get displayPrice => effectivePrice ?? specialPrice ?? originalPrice ?? 0;
}
