import 'package:eboro/Helper/MealORData.dart';
import 'package:eboro/Helper/ProductData.dart';

class MealData {
  final int? id;
  final ProductData? Product;
  final int? value;
  final List<MealORData>? products;
  // final BranchData branch;
  // final ProviderData provider;
  final String?start_at;
  final String?end_at;
  final String?created_at;


  MealData({
    this.id,
    this.Product,
    this.value,
    this.products,
    // this.branch,
    // this.provider,
    this.start_at,
    this.end_at,
    this.created_at,
  });

  factory MealData.fromJson(Map<String, dynamic> json) {
    return MealData(
      id: json['id'],
      Product: json['Product'] != null ? ProductData.fromJson(json['Product']) : null,
      value: json['value'],
      products: json['products'] != null && json['products'] is List ? (json['products'] as List).map((i) => MealORData.fromJson(i)).toList() : null,
      // branch: BranchData.fromJson(json['branch']),
      // provider: ProviderData.fromJson(json['provider']),
      start_at: json['start_at'],
      end_at: json['end_at'],
      created_at: json['created_at'],
    );
  }
}