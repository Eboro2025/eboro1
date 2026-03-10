import 'package:eboro/Helper/TypeData.dart';

class TypesData {
  final int? id;
  final TypeData? type;


  TypesData({
    this.id,
    this.type,
  });

  factory TypesData.fromJson(Map<String, dynamic> json) {
    return TypesData(
      id: json['id'],
      type: json['type'] != null ? TypeData.fromJson(json['type']) : null,
    );
  }
}
