
class SaucesData {
  final int? id;
  final int? sauce_id;
  final String?name;
  final String?description;
  final String?price;
  final String?product_type;
  final String?image;
  final String?created_at;


  SaucesData({
    this.id,
    this.sauce_id,
    this.name,
    this.description,
    this.price,
    this.product_type,
    this.image,
    this.created_at,
  });

  factory SaucesData.fromJson(Map<String, dynamic> json) {
    return SaucesData(
      id: json['id'],
      sauce_id: json['sauce_id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      product_type: json['product_type'],
      image: json['image'],
      created_at: json['created_at'],
    );
  }
}
