import 'dart:convert';
import 'package:eboro/Helper/FaqData.dart';
import 'package:eboro/Helper/RefundData.dart';
import 'package:eboro/Helper/ContactsData.dart';
import 'package:eboro/main.dart';
import 'package:http/http.dart' as http;

class AssistenzaAPI {

  /// Fetch FAQs grouped by category
  Future<Map<String, List<FaqData>>> getFaqs() async {
    Map<String, List<FaqData>> grouped = {};
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/faqs'),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'] as Map<String, dynamic>? ?? {};
        data.forEach((category, items) {
          grouped[category] = (items as List)
              .map((e) => FaqData.fromJson(e))
              .toList();
        });
      }
    } catch (e) {
      // silently fail
    }
    return grouped;
  }

  /// Fetch app settings (phones, email, social)
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/setting-details'),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // silently fail
    }
    return {};
  }

  /// Fetch user's refund requests
  Future<List<RefundData>> getUserRefundRequests() async {
    List<RefundData> refunds = [];
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/user/refund-requests'),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token.toString(),
        },
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'] as List? ?? [];
        refunds = data.map((e) => RefundData.fromJson(e)).toList();
      }
    } catch (e) {
      // silently fail
    }
    return refunds;
  }

  /// Fetch user's support tickets (contacts)
  Future<List<ContactsData>> getUserTickets() async {
    List<ContactsData> tickets = [];
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/user/contact'),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': MyApp2.token.toString(),
        },
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'] as List? ?? [];
        tickets = data.map((e) => ContactsData.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // silently fail
    }
    return tickets;
  }
}
