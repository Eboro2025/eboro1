import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eboro/main.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({Key? key}) : super(key: key);

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _loading = true;
  bool _error = false;
  String _content = '';

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    try {
      final response = await http.get(
        Uri.parse('$globalUrl/api/privacy'),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['data']?['content'] ?? '';
        if (mounted) setState(() { _content = content; _loading = false; });
      } else {
        if (mounted) setState(() { _loading = false; _error = true; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  // Simple HTML to widgets parser
  List<Widget> _parseHtml(String html) {
    List<Widget> widgets = [];

    // Remove style/script tags
    html = html.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
    html = html.replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '');

    // Split by block-level tags
    final blocks = html.split(RegExp(r'<(?:br\s*/?>|/?\s*(?:p|div|h[1-6]|li|ul|ol|tr|table|thead|tbody))[^>]*>', caseSensitive: false));

    for (var block in blocks) {
      String text = _stripTags(block).trim();
      if (text.isEmpty) continue;

      // Detect if it was a heading
      bool isHeading = RegExp(r'<h[1-3]', caseSensitive: false).hasMatch(block);
      bool isBold = block.contains('<strong') || block.contains('<b>') || isHeading;

      widgets.add(Padding(
        padding: EdgeInsets.only(
          bottom: isHeading ? 12 : 6,
          top: isHeading ? 16 : 2,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isHeading ? 18 : 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: isHeading ? const Color(0xFF222222) : const Color(0xFF333333),
            height: 1.6,
          ),
        ),
      ));
    }

    return widgets;
  }

  String _stripTags(String html) {
    // Decode HTML entities
    String text = html
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&euro;', '€')
        .replaceAll('&agrave;', 'à')
        .replaceAll('&egrave;', 'è')
        .replaceAll('&igrave;', 'ì')
        .replaceAll('&ograve;', 'ò')
        .replaceAll('&ugrave;', 'ù');
    // Strip remaining tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // Collapse whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: myColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: myColor),
            )
          : _error
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Impossibile caricare la privacy policy',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { _loading = true; _error = false; });
                          _loadPrivacy();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: myColor),
                        child: const Text('Riprova', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _parseHtml(_content),
                  ),
                ),
    );
  }
}
