
import 'package:eboro/Helper/ProviderData.dart';

class ProviderRateData {
  final int? id;
  final ProviderData? provider;
  final String?value;
  final String?created_at;

  // of provider

  ProviderRateData({
    this.id,
    this.provider,
    this.value,
    this.created_at,
  });

  factory ProviderRateData.fromJson(Map<String, dynamic> json) {
    return ProviderRateData(
      id: json['id'],
      provider: json['provider'] != null ? ProviderData.fromJson(json['provider']) : null,
      value: json['value'],
      created_at: json['created_at'],
    );
  }
}
