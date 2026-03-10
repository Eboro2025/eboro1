import 'package:eboro/Helper/BranchData.dart';
import 'package:eboro/Helper/OfferData.dart';
import 'package:eboro/Helper/SaucesData.dart';
import 'package:eboro/Helper/TypeData.dart';

class ProductData {
  final int? id;
  final String? name;
  final String? description;
  final TypeData? type;
  final int? has_alcohol;
  final int? has_outofstock;
  final String? start_outofstock;
  final String? end_outofstock;
  final int? has_pig;
  final String? price; // price
  final String? product_type; //  all required if equal {Food}
  final OfferData? offer;
  final String? image;
  final BranchData? branch;
  final String? additions; // Optional if product_type not food
  final String? calories; // Optional if product_type not food
  final String? size; // Optional if product_type not food
  final List<SaucesData>? sauces; // Optional if product_type not food
  final Map<String, dynamic>? extra1; // {name: 'اسم المجموعة', items: [...]}
  final Map<String, dynamic>? extra2;
  final Map<String, dynamic>? extra3;
  final Map<String, dynamic>? extra4;
  final String? created_at;

  ProductData({
    this.id,
    this.name,
    this.description,
    this.price,
    this.offer,
    this.type,
    this.image,
    this.has_alcohol,
    this.has_outofstock,
    this.start_outofstock,
    this.end_outofstock,
    this.has_pig,
    this.additions,
    this.calories,
    this.size,
    this.product_type,
    this.sauces,
    this.extra1,
    this.extra2,
    this.extra3,
    this.extra4,
    this.branch,
    this.created_at,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    try {
      int parseInt(dynamic value, [int defaultValue = 0]) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is String && value.trim().isNotEmpty) {
          return int.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      double parseDouble(dynamic value, [double defaultValue = 0.0]) {
        if (value == null) return defaultValue;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String && value.trim().isNotEmpty) {
          return double.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      return ProductData(
        id: parseInt(json['id']),
        name: json['name'],
        description: json['description'],
        price: json['price']?.toString() ?? '0',
        offer: json['offer'] != null && json['offer'] is Map
            ? OfferData.fromJson(json['offer'])
            : null,
        type: json['type'] != null && json['type'] is Map
            ? TypeData.fromJson(json['type'])
            : null,
        image: json['image']?.toString(),
        has_alcohol: parseInt(json['has_alcohol']),
        has_outofstock: parseInt(json['has_outofstock']),
        start_outofstock: json['start_outofstock'],
        end_outofstock: json['end_outofstock'],
        has_pig: parseInt(json['has_pig']),
        product_type: json['product_type'],
        additions: json['additions']?.toString(),
        calories: json['calories']?.toString(),
        size: json['size']?.toString(),
        sauces: json['sauces'] != null && json['sauces'] is List
            ? (json['sauces'] as List)
                .where((i) => i != null && i is Map)
                .map((i) => SaucesData.fromJson(i))
                .toList()
            : null,
        extra1: json['extra1'] != null && json['extra1'] is Map
            ? json['extra1'] as Map<String, dynamic>
            : null,
        extra2: json['extra2'] != null && json['extra2'] is Map
            ? json['extra2'] as Map<String, dynamic>
            : null,
        extra3: json['extra3'] != null && json['extra3'] is Map
            ? json['extra3'] as Map<String, dynamic>
            : null,
        extra4: json['extra4'] != null && json['extra4'] is Map
            ? json['extra4'] as Map<String, dynamic>
            : null,
        branch: json['branch'] != null && json['branch'] is Map
            ? BranchData.fromJson(json['branch'])
            : null,
        created_at: json['created_at'],
      );
    } catch (_) {
      rethrow;
    }
  }
}
