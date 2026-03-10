
class LightBranchData {
  final int? id;
  final String?name;
  final String?status;
  final String?lat;
  final String?long;
  final String?hotline;
  final bool?has_delivery;
  final int?provider_id;
  final String?created_at;
  final String?address;

  LightBranchData({
    this.id,
    this.name,
    this.status,
    this.lat,
    this.long,
    this.hotline,
    this.has_delivery,
    this.provider_id,
    this.created_at,
    this.address,

  });

  factory LightBranchData.fromJson(Map<String, dynamic> json) {
    return LightBranchData(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      has_delivery: json['has_delivery'],
      lat: json['lat'],
      long: json['long'],
      hotline: json['hotline'],
      provider_id: json['provider_id'],
      created_at: json['created_at'],
      address: json['address'],
    );
  }
}
