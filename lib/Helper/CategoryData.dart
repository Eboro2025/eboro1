
class CategoryData {
  final int? id;
  final String?name;
  final String?image;
  final String?created_at;


  CategoryData({
    this.id,
    this.name,
    this.image,
    this.created_at,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      created_at: json['created_at'],
    );
  }
}
