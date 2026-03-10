/// Helper لتحويل روابط الصور للسيرفر المحلي
String fixImageUrl(String? url) {
  // Return empty string for null or empty URLs
  if (url == null || url.isEmpty || url.trim().isEmpty) {
    return '';
  }

  var fixed = url.trim();

  // لو الـ URL جاي من الـ backend بـ localhost بدون port -> نحوله لـ partnerseboro.it
  if (fixed.contains('http://localhost/') && !fixed.contains(':')) {
    fixed = fixed.replaceAll('http://localhost/', 'https://partnerseboro.it/');
  }
  // لو جاي بـ localhost:8000 -> نحوله لـ partnerseboro.it
  else if (fixed.contains('http://localhost:8000')) {
    fixed = fixed.replaceAll('http://localhost:8000', 'https://partnerseboro.it');
  }
  // لو جاي بـ 127.0.0.1 -> نحوله لـ partnerseboro.it
  else if (fixed.contains('http://127.0.0.1')) {
    fixed = fixed.replaceAll('http://127.0.0.1:8000', 'https://partnerseboro.it');
    fixed = fixed.replaceAll('http://127.0.0.1/', 'https://partnerseboro.it/');
  }

  // لو الرابط مش كامل (مجرد path)، نضيف base URL
  if (!fixed.startsWith('http://') && !fixed.startsWith('https://')) {
    if (fixed.startsWith('/')) {
      fixed = fixed.substring(1);
    }
    // نستخدم نفس الـ globalUrl من main.dart
    fixed = 'https://partnerseboro.it/$fixed';
  }

  // Final validation - ensure we have a valid URL
  if (fixed.isEmpty || !fixed.startsWith('http')) {
    return '';
  }

  return fixed;
}
