import 'dart:io';

import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Instagram has no URL scheme for sharing text, so we share the image
/// through the system sheet (where the user picks Instagram / Stories)
/// and copy the caption to the clipboard so it can be pasted.
Future<void> shareToInstagram(
  BuildContext context, {
  required String text,
  String? imageUrl,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : const Rect.fromLTWH(0, 0, 100, 100);

  try {
    await Clipboard.setData(ClipboardData(text: text));
    Auth2.show('Testo copiato: incollalo su Instagram');

    final url = fixImageUrl(imageUrl);
    if (!kIsWeb && url.isNotEmpty) {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/eboro_instagram.jpg');
        await file.writeAsBytes(res.bodyBytes);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/jpeg')],
          text: text,
          sharePositionOrigin: origin,
        );
        return;
      }
    }

    await Share.share(text, sharePositionOrigin: origin);
  } catch (e) {
    Auth2.show('Errore apertura Instagram');
  }
}
