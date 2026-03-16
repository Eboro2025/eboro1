import 'dart:convert';
import 'package:eboro/Helper/HttpInterceptor.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;

class PromoVideo {
  final int id;
  final int providerId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  int viewsCount;
  int likesCount;
  bool isLiked;
  final String? providerName;
  final String? providerLogo;
  final double avgRating;
  final int ratesCount;

  PromoVideo({
    required this.id,
    required this.providerId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.isLiked = false,
    this.providerName,
    this.providerLogo,
    this.avgRating = 0,
    this.ratesCount = 0,
  });

  factory PromoVideo.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] as Map<String, dynamic>?;
    return PromoVideo(
      id: json['id'],
      providerId: json['provider_id'],
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      title: json['title'],
      description: json['description'],
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      providerName: provider?['name'],
      providerLogo: provider?['logo'],
      avgRating: (provider?['avg_rating'] ?? 0).toDouble(),
      ratesCount: provider?['rates_count'] ?? 0,
    );
  }
}

class VideoApi {
  static Future<List<PromoVideo>> getPromoVideos({String order = 'manual'}) async {
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/promo-videos?order=$order'),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? '',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List data = jsonData['data'] ?? [];
        return data.map((v) => PromoVideo.fromJson(v)).toList();
      }
    } catch (e) {
      // print('DEBUG VIDEO API ERROR: $e');
    }
    return [];
  }

  static Future<void> incrementView(int videoId) async {
    try {
      await HttpInterceptor.post(
        '$globalUrl/api/videos/$videoId/view',
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? '',
        },
      );
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> toggleLike(int videoId) async {
    try {
      final response = await HttpInterceptor.post(
        '$globalUrl/api/videos/$videoId/like',
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? '',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }
}
