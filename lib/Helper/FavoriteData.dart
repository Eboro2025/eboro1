import 'package:eboro/Helper/ProviderData.dart';

class FavoriteData {
  final int? id;
  final ProviderData? provider;
  final String?created_at;


  FavoriteData({
    this.id,
    this.provider,
    this.created_at,
  });

  factory FavoriteData.fromJson(Map<String, dynamic> json) {
    return FavoriteData(
      id: json['id'],
      provider: ProviderData.fromJson(json['provider']),
      created_at: json['created_at'],
    );
  }
}
