class TypeData {
  final int? id;
  final int? category_id;
  final String? type;
  final String? image;
  final String? created_at;

  TypeData({
    this.id,
    this.category_id,
    this.type,
    this.image,
    this.created_at,
  });

  factory TypeData.fromJson(Map<String, dynamic> json) {
    try {
      return TypeData(
        id: json['id'],
        category_id: json['category_id'],
        type: json['type']?.toString(),
        image: json['image']?.toString(),
        created_at: json['created_at']?.toString(),
      );
    } catch (e) {
      return TypeData(); // Return empty TypeData on error
    }
  }
}
