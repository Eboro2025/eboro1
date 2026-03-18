import 'package:eboro/API/Auth.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Interceptor HTTP para manejar automáticamente la renovación de tokens expirados
class HttpInterceptor {

  /// الحصول على context صالح - يستخدم المعطى أو navigatorKey كبديل
  static BuildContext _getContext(BuildContext? context) {
    if (context != null) return context;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) throw StateError('No valid context available');
    return ctx;
  }

  /// POST that preserves the method on redirects (avoids POST→GET conversion)
  static Future<http.Response> _postNoRedirect(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final request = http.Request('POST', Uri.parse(url));
    if (headers != null) request.headers.addAll(headers);
    if (body is Map<String, String>) {
      request.bodyFields = body;
    } else if (body != null) {
      request.body = body.toString();
    }
    request.followRedirects = false;

    final streamed = await request.send();

    if (streamed.statusCode == 301 ||
        streamed.statusCode == 302 ||
        streamed.statusCode == 307 ||
        streamed.statusCode == 308) {
      final location = streamed.headers['location'];
      if (location != null) {
        final redirectUrl = Uri.parse(url).resolve(location).toString();
        final r2 = http.Request('POST', Uri.parse(redirectUrl));
        if (headers != null) r2.headers.addAll(headers);
        if (body is Map<String, String>) {
          r2.bodyFields = body;
        } else if (body != null) {
          r2.body = body.toString();
        }
        r2.followRedirects = false;
        final streamed2 = await r2.send();
        return http.Response.fromStream(streamed2);
      }
    }
    return http.Response.fromStream(streamed);
  }

  /// Realiza una petición GET con manejo automático de token expirado
  static Future<http.Response> get(
    String url, {
    BuildContext? context,
    Map<String, String>? headers,
    int retryCount = 0,
  }) async {
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    // Si el token expiró (401), intentar refrescarlo (skip for guest)
    if (response.statusCode == 401 && retryCount == 0 && MyApp2.token != null && MyApp2.token!.isNotEmpty) {
      bool refreshed = await Auth2.refreshToken(_getContext(context));

      if (refreshed) {
        if (headers != null && headers.containsKey('Authorization')) {
          headers['Authorization'] = MyApp2.token!;
        }
        return await get(url, context: context, headers: headers, retryCount: 1);
      }
    }

    return response;
  }

  /// Realiza una petición POST con manejo automático de token expirado
  static Future<http.Response> post(
    String url, {
    BuildContext? context,
    Map<String, String>? headers,
    dynamic body,
    int retryCount = 0,
  }) async {
    final response = await _postNoRedirect(url, headers: headers, body: body);

    // Si el token expiró (401), intentar refrescarlo (skip for guest)
    if (response.statusCode == 401 && retryCount == 0 && MyApp2.token != null && MyApp2.token!.isNotEmpty) {
      bool refreshed = await Auth2.refreshToken(_getContext(context));

      if (refreshed) {
        if (headers != null && headers.containsKey('Authorization')) {
          headers['Authorization'] = MyApp2.token!;
        }
        return await post(url, context: context, headers: headers, body: body, retryCount: 1);
      }
    }

    return response;
  }

  /// Realiza una petición PUT con manejo automático de token expirado
  static Future<http.Response> put(
    String url, {
    BuildContext? context,
    Map<String, String>? headers,
    dynamic body,
    int retryCount = 0,
  }) async {
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 401 && retryCount == 0) {
      bool refreshed = await Auth2.refreshToken(_getContext(context));

      if (refreshed) {
        if (headers != null && headers.containsKey('Authorization')) {
          headers['Authorization'] = MyApp2.token!;
        }
        return await put(url, context: context, headers: headers, body: body, retryCount: 1);
      }
    }

    return response;
  }

  /// Realiza una petición DELETE con manejo automático de token expirado
  static Future<http.Response> delete(
    String url, {
    BuildContext? context,
    Map<String, String>? headers,
    int retryCount = 0,
  }) async {
    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 401 && retryCount == 0) {
      bool refreshed = await Auth2.refreshToken(_getContext(context));

      if (refreshed) {
        if (headers != null && headers.containsKey('Authorization')) {
          headers['Authorization'] = MyApp2.token!;
        }
        return await delete(url, context: context, headers: headers, retryCount: 1);
      }
    }

    return response;
  }
}
