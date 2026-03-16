import 'package:eboro/main.dart';

/// Helper لتحويل روابط الصور للسيرفر
String fixImageUrl(String? url) {
  if (url == null || url.isEmpty || url.trim().isEmpty) {
    return '';
  }

  var fixed = url.trim();

  // لو الـ URL جاي من الـ backend بـ localhost -> نحوله للسيرفر الحالي
  if (fixed.contains('http://localhost/') && !fixed.contains(':')) {
    fixed = fixed.replaceAll('http://localhost/', '$globalUrl/');
  } else if (fixed.contains('http://localhost:8000')) {
    fixed = fixed.replaceAll('http://localhost:8000', globalUrl);
  } else if (fixed.contains('http://127.0.0.1')) {
    fixed = fixed.replaceAll('http://127.0.0.1:8000', globalUrl);
    fixed = fixed.replaceAll('http://127.0.0.1/', '$globalUrl/');
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
