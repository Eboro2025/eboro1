import 'package:eboro/Helper/ProviderData.dart';

class FilterData {
  final ProviderData? providers;

  FilterData({
    this.providers,
  });

  factory FilterData.fromJson(Map<String, dynamic> json) {
    return FilterData(
      providers: ProviderData.fromJson(json),
    );
  }
}