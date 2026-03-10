import 'package:eboro/Helper/ImageHelper.dart';

class BannerData {
  final int? id;
  final String? title;
  final String? image;
  final String? link;
  final int? providerId;
  final List<int> providerIds; // Multiple providers
  final String? providerName;
  final int? sortOrder;
  final String? offerType;    // linked offer type (free_delivery, two_for_one, etc.)
  final String? offerLabel;   // label from server (e.g. "Consegna gratuita")
  final bool hasDailySpecial; // linked to a daily special

  BannerData({
    this.id,
    this.title,
    this.image,
    this.link,
    this.providerId,
    this.providerIds = const [],
    this.providerName,
    this.sortOrder,
    this.offerType,
    this.offerLabel,
    this.hasDailySpecial = false,
  });

  factory BannerData.fromJson(Map<String, dynamic> json) {
    // Parse provider_ids array
    List<int> providerIds = [];
    if (json['provider_ids'] != null && json['provider_ids'] is List) {
      providerIds = (json['provider_ids'] as List)
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();
    }

    // Parse linked offer
    final offer = json['offer'];
    String? offerType;
    String? offerLabel;
    if (offer != null) {
      offerType = offer['offer_type'];
      offerLabel = offer['label'] ?? offer['title'];
    }

    // Parse linked daily special
    final dailySpecial = json['daily_special'];

    return BannerData(
      id: json['id'],
      title: json['title'],
      image: json['image']?.toString(),
      link: json['link'],
      providerId: json['provider_id'],
      providerIds: providerIds,
      providerName: json['provider_name'],
      sortOrder: json['sort_order'],
      offerType: offerType,
      offerLabel: offerLabel,
      hasDailySpecial: dailySpecial != null,
    );
  }

  /// Badge text based on linked offer/daily special
  String? get badgeText {
    if (hasDailySpecial) return "Piatto del Giorno";
    if (offerType == null) return null;
    if (offerType == 'free_delivery' || offerType == 'two_for_one_free_delivery') {
      return offerLabel ?? "Consegna Gratuita";
    }
    if (offerType == 'two_for_one' || offerType == 'one_plus_one') {
      return offerLabel ?? "2×1";
    }
    if (offerType == 'discount' || offerType == 'fixed_discount') {
      return offerLabel ?? "Sconto";
    }
    return offerLabel;
  }

  String get imageUrl => fixImageUrl(image);

  /// Check if banner has linked providers
  bool get hasProviders => providerIds.isNotEmpty || providerId != null;

  /// Get all provider IDs (combined from both fields)
  List<int> get allProviderIds {
    if (providerIds.isNotEmpty) return providerIds;
    if (providerId != null) return [providerId!];
    return [];
  }
}
