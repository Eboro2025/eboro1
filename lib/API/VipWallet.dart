import 'dart:convert';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;

class VipWalletApi {
  static Map<String, String> get _headers => {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': '${MyApp2.token}',
      };

  /// Get wallet info: balance, referral_code, commission, referral_count, total_earned, recent_transactions
  static Future<Map<String, dynamic>?> getWallet() async {
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/vip/wallet'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // getWallet error
    }
    return null;
  }

  /// Get paginated transactions
  static Future<Map<String, dynamic>?> getTransactions({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/vip/transactions?page=$page'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // getTransactions error
    }
    return null;
  }

  /// Get referrals list
  static Future<List<dynamic>?> getReferrals() async {
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/vip/referrals'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return body['data'] as List<dynamic>?;
      }
    } catch (e) {
      // getReferrals error
    }
    return null;
  }

  /// Get QR code URL
  static Future<Map<String, dynamic>?> getQrcodeUrl() async {
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/vip/qrcode-url'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // getQrcodeUrl error
    }
    return null;
  }
}
