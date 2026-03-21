import 'package:eboro/Helper/ProviderData.dart';

class FavoriteData {
  final int? id;
  final ProviderData? provider;
  final String? created_at;

  FavoriteData({
    this.id,
    this.provider,
    this.created_at,
  });

  factory FavoriteData.fromJson(Map<String, dynamic> json) {
    return FavoriteData(
      id: json['id'],
      provider: json['provider'] != null
          ? ProviderData.fromJson(json['provider'])
          : null,
      created_at: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider?.rawJson,
      'created_at': created_at,
    };
  }
}
