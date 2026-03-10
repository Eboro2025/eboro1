/// Helper لإصلاح JSON الفاسد من الـ Backend
String fixBrokenJson(String jsonString) {
  if (jsonString.isEmpty) return jsonString;

  String fixed = jsonString;

  // === إصلاحات مهمة أولاً ===

  // إصلاح: 00:00:"00" → 00:00:00 (علامة اقتباس إضافية في الوقت)
  fixed =
      fixed.replaceAllMapped(RegExp(r'(\d{2}:\d{2}):"(\d{2})"'), (Match match) {
    return '${match.group(1)}:${match.group(2)}';
  });

  // إصلاح: "payment":"0""content" → "payment":"0","content"
  fixed = fixed.replaceAllMapped(RegExp(r':"([^"]*?)""([a-zA-Z_]+)":'),
      (Match match) {
    return ':"${match.group(1)}","${match.group(2)}":';
  });

  // إصلاح: "required":, أو "min_selection":, أو "max_selection":, → null
  fixed = fixed.replaceAllMapped(
      RegExp(r'"(required|min_selection|max_selection)"\s*:\s*,',
          caseSensitive: false), (Match match) {
    return '"${match.group(1)}":null,';
  });
  fixed = fixed.replaceAllMapped(
      RegExp(r'"(required|min_selection|max_selection)"\s*:\s*}',
          caseSensitive: false), (Match match) {
    return '"${match.group(1)}":null}';
  });

  // إصلاح: "required":n / "max_selection":n → null
  fixed = fixed.replaceAllMapped(
      RegExp(r'"(required|min_selection|max_selection)"\s*:\s*n[^,}]*',
          caseSensitive: false), (Match match) {
    return '"${match.group(1)}":null';
  });

  // إصلاح: "long":9.123 → "long":"9.123" (رقم بدون علامات اقتباس)
  fixed = fixed.replaceAllMapped(RegExp(r'"(lat|long)":(-?\d+\.?\d*)([,}])'),
      (Match match) {
    return '"${match.group(1)}":"${match.group(2)}"${match.group(3)}';
  });

  // إصلاح: :0"Delivery → :0,"Delivery (ينقص فاصلة بعد رقم)
  fixed = fixed.replaceAllMapped(RegExp(r':(\d+)"([A-Z])'), (Match match) {
    return ':${match.group(1)},"${match.group(2)}';
  });

  // === إصلاحات موجودة ===

  // إصلاح: "content"[ → "content":[
  fixed = fixed.replaceAll('"content"[', '"content":[');

  // إصلاح: "status: → "status":
  fixed = fixed.replaceAll('"status:', '"status":');

  // إصلاح: "tax_price: → "tax_price":
  fixed = fixed.replaceAll('"tax_price:', '"tax_price":');

  // إصلاح: "description: → "description":
  fixed = fixed.replaceAll('"description:', '"description":');

  // إصلاح: "name: → "name":
  fixed = fixed.replaceAll('"name:', '"name":');

  // إصلاح: "refuse_reason":The → "refuse_reason":"The
  fixed = fixed.replaceAllMapped(RegExp(r'"refuse_reason":([A-Z][^",}]+)'),
      (Match match) {
    return '"refuse_reason":"${match.group(1)}"';
  });

  // إصلاح: "has_delivery"true → "has_delivery":true
  fixed = fixed.replaceAll('"has_delivery"true', '"has_delivery":true');
  fixed = fixed.replaceAll('"has_delivery"false', '"has_delivery":false');

  // إصلاح: 56"created → 56,"created (missing comma after number)
  fixed = fixed.replaceAllMapped(RegExp(r'(\d+)"(\w+)'), (Match match) {
    return '${match.group(1)},"${match.group(2)}';
  });

  // إصلاح: "lat""45 → "lat":"45 و "long""9 → "long":"9
  fixed = fixed.replaceAllMapped(RegExp(r'"(lat|long)""'), (Match match) {
    return '"${match.group(1)}":"';
  });

  // إصلاح: "close""lat" → "close","lat" (missing comma between string values)
  fixed = fixed.replaceAllMapped(RegExp(r'"([^"]+)""([a-zA-Z_]+)":'),
      (Match match) {
    return '"${match.group(1)}","${match.group(2)}":';
  });

  // إصلاح: "branch":"id":... → "branch":{"id":...
  fixed = fixed.replaceAllMapped(RegExp(r'"branch"\s*:\s*"id"\s*:'),
      (Match match) {
    return '"branch":{"id":';
  });

  // إغلاق branch قبل comment إذا لم يتم إغلاقه
  fixed = fixed.replaceAllMapped(
      RegExp(r'"branch"\s*:\s*\{([^}]*)"comment"\s*:', dotAll: true),
      (Match match) {
    return '"branch":{${match.group(1)}}"comment":';
  });

  // إصلاح: "https":\/\/ → "https:\/\/ (extra quote after protocol)
  fixed = fixed.replaceAll('"https":', '"https:');
  fixed = fixed.replaceAll('"http":', '"http:');

  // إصلاح: }"created → },"created
  fixed = fixed.replaceAll('}"created', '},"created');
  fixed = fixed.replaceAll('}"updated', '},"updated');

  // إصلاح: "created_at""2024 → "created_at":"2024 (missing colon)
  fixed = fixed.replaceAllMapped(RegExp(r'"(created_at|updated_at)""'),
      (Match match) {
    return '"${match.group(1)}":"';
  });

  // إصلاح: "created_at":2025 → "created_at":"2025 (missing quotes around date)
  fixed = fixed.replaceAllMapped(
      RegExp(r'"(created_at|updated_at)":(\d{4}-\d{2}-\d{2})'), (Match match) {
    return '"${match.group(1)}":"${match.group(2)}';
  });

  // إصلاح: }"id": → },"id":
  fixed = fixed.replaceAll('}"id":', '},"id":');
  fixed = fixed.replaceAll('}"name":', '},"name":');

  // إصلاح: }],"Rate":[] → }],"Rate":[]  (ensure proper array formatting)
  fixed = fixed.replaceAll('}]"Rate"', '}],"Rate"');
  fixed = fixed.replaceAll('}]"Delivery_time"', '}],"Delivery_time"');

  // إصلاح: أي حقل بدون : قبل القيمة (pattern عام)
  fixed = fixed.replaceAllMapped(RegExp(r'"\w+"(true|false|null|\d+)'),
      (Match match) {
    final field =
        match.group(0)!.replaceFirst(RegExp(r'(true|false|null|\d+)$'), '');
    final value = match.group(1);
    return '$field:$value';
  });

  // إصلاح: "lat":"45.4981961,"long" → "lat":"45.4981961","long"
  // (missing closing quote after number, before comma)
  fixed = fixed.replaceAllMapped(RegExp(r':"([\d.]+),"'), (Match match) {
    return ':"${match.group(1)}","';
  });

  // إصلاح أيضاً: :"NUMBER, (حيث NUMBER بدون علامة اقتباس في النهاية)
  fixed = fixed.replaceAllMapped(RegExp(r':"([\d.-]+),'), (Match match) {
    return ':"${match.group(1)}",';
  });

  // إصلاح: "options":"," → "options":""
  fixed = fixed.replaceAll('"options":","', '"options":"",');

  // إصلاح: "comment":"," → "comment":""
  fixed = fixed.replaceAll('"comment":","', '"comment":"",');

  // إصلاح: "sauces":[],branch" → "sauces":[],"branch" (missing comma after array)
  fixed = fixed.replaceAll('[]"', '[],"');
  fixed = fixed.replaceAll('}]"', '}],"');

  // إصلاح: "created_at""2022 → "created_at":"2022 (missing colon after key)
  fixed = fixed.replaceAllMapped(RegExp(r'"([\w_]+)""([^"]+)"'), (Match match) {
    return '"${match.group(1)}":"${match.group(2)}"';
  });

  // إصلاح: "description":nul → "description":null (incomplete null)
  fixed = fixed.replaceAll(':nul,', ':null,');
  fixed = fixed.replaceAll(':nul}', ':null}');

  // إصلاح: "house:"22" → "house":"22" (missing quote after field name)
  fixed = fixed.replaceAllMapped(RegExp(r'"([a-zA-Z_][a-zA-Z0-9_]*):"([^"]+)"'),
      (Match match) {
    return '"${match.group(1)}":"${match.group(2)}"';
  });

  return fixed;
}
