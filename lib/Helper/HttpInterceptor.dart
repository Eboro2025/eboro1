import 'package:eboro/API/Auth.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Interceptor HTTP para manejar automáticamente la renovación de tokens expirados
class HttpInterceptor {

  /// الحصول على context صالح - يستخدم المعطى أو navigatorKey كبديل
  static BuildContext _getContext(BuildContext? context) {
    return context ?? navigatorKey.currentContext!;
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

    // Si el token expiró (401), intentar refrescarlo
    if (response.statusCode == 401 && retryCount == 0) {
      // print("Token expirado en GET $url - Intentando refrescar...");
      bool refreshed = await Auth2.refreshToken(_getContext(context));

      if (refreshed) {
        // Actualizar header con nuevo token
        if (headers != null && headers.containsKey('Authorization')) {
          headers['Authorization'] = MyApp2.token!;
        }

        // Reintentar la petición con el nuevo token
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
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    // Si el token expiró (401), intentar refrescarlo
    if (response.statusCode == 401 && retryCount == 0) {
      // print("Token expirado en POST $url - Intentando refrescar...");
      bool refreshed = await Auth2.refreshToken(_getContext(context));

      if (refreshed) {
        // Actualizar header con nuevo token
        if (headers != null && headers.containsKey('Authorization')) {
          headers['Authorization'] = MyApp2.token!;
        }

        // Reintentar la petición con el nuevo token
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

    // Si el token expiró (401), intentar refrescarlo
    if (response.statusCode == 401 && retryCount == 0) {
      // print("Token expirado en PUT $url - Intentando refrescar...");
      bool refreshed = await Auth2.refreshToken(_getContext(context));

      if (refreshed) {
        // Actualizar header con nuevo token
        if (headers != null && headers.containsKey('Authorization')) {
          headers['Authorization'] = MyApp2.token!;
        }

        // Reintentar la petición con el nuevo token
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

    // Si el token expiró (401), intentar refrescarlo
    if (response.statusCode == 401 && retryCount == 0) {
      // print("Token expirado en DELETE $url - Intentando refrescar...");
      bool refreshed = await Auth2.refreshToken(_getContext(context));

      if (refreshed) {
        // Actualizar header con nuevo token
        if (headers != null && headers.containsKey('Authorization')) {
          headers['Authorization'] = MyApp2.token!;
        }

        // Reintentar la petición con el nuevo token
        return await delete(url, context: context, headers: headers, retryCount: 1);
      }
    }

    return response;
  }
}
