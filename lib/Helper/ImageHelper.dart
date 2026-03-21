import 'package:eboro/main.dart';

/// Helper لتحويل روابط الصور للسيرفر
String fixImageUrl(String? url) {
  if (url == null || url.isEmpty || url.trim().isEmpty) {
    return '';
  }

  var fixed = url.trim();

  // لو الرابط من localhost أو 127.0.0.1 -> نحوله للسيرفر الحالي
  final localPatterns = [
    RegExp(r'https?://localhost(:\d+)?'),
    RegExp(r'https?://127\.0\.0\.1(:\d+)?'),
  ];
  for (final pattern in localPatterns) {
    if (pattern.hasMatch(fixed)) {
      fixed = fixed.replaceAll(pattern, globalUrl);
    }
  }

  // لو الرابط مش كامل (مجرد path)، نضيف base URL
  if (!fixed.startsWith('http://') && !fixed.startsWith('https://')) {
    if (fixed.startsWith('/')) {
      fixed = fixed.substring(1);
    }
    fixed = '$globalUrl/$fixed';
  }

  if (fixed.isEmpty || !fixed.startsWith('http')) {
    return '';
  }

  return fixed;
}
