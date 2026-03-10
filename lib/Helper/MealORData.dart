
import 'package:eboro/Helper/ProductData.dart';

class MealORData {
  final int? id;
  final ProductData? Product;
  final String?Ammount;
  final String?created_at;


  MealORData({
    this.id,
    this.Product,
    this.Ammount,
    this.created_at,
  });

  factory MealORData.fromJson(Map<String, dynamic> json) {
    return MealORData(
      id: json['id'],
      Product: json['Product'] != null ? ProductData.fromJson(json['Product']) : null,
      Ammount: json['Ammount'],
      created_at: json['created_at'],
    );
  }
}
