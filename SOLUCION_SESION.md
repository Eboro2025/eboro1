# 🔐 Solución al Problema de Cierre Automático de Sesión

## 📋 Problema Identificado
La sesión se cierra automáticamente después de 6 días porque el **token JWT del backend expira**.

## ✅ Soluciones Implementadas

### **SOLUCIÓN 1: Sistema de Refresh Token** (Recomendada - Requiere Backend)

He implementado un sistema completo de refresh token que permite renovar automáticamente el token sin que el usuario tenga que hacer login nuevamente.

#### Cambios Realizados:

1. **lib/API/Auth.dart**
   - ✅ Guardar `refresh_token` al hacer login
   - ✅ Nueva función `refreshToken()` para renovar el token
   - ✅ Modificado `getUserDetails()` para auto-renovar en caso de expiración
   - ✅ Limpieza de `refresh_token` al hacer logout

2. **lib/Helper/HttpInterceptor.dart** (NUEVO)
   - ✅ Interceptor HTTP que maneja automáticamente tokens expirados
   - ✅ Reintentar peticiones después de refrescar el token
   - ✅ Métodos: GET, POST, PUT, DELETE

#### 🔧 Cambios Requeridos en el Backend:

El backend debe:

1. **Devolver refresh_token en el login:**
```json
{
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGci...",
    "refresh_token": "dGhpc2lzYXJlZnJlc2h0b2tlbg..."
  }
}
```

2. **Crear endpoint para refrescar el token:**
```
POST /api/refresh-token
Body: {
  "refresh_token": "dGhpc2lzYXJlZnJlc2h0b2tlbg..."
}

Response: {
  "data": {
    "token": "nuevo_access_token",
    "refresh_token": "nuevo_refresh_token" (opcional)
  }
}
```

3. **Configuración recomendada:**
   - Access Token: 15 minutos - 1 hora
   - Refresh Token: 30-90 días (o sin expiración)

---

### **SOLUCIÓN 2: Auto-Login con Credenciales Guardadas** (Sin cambios en Backend)

Si NO puedes modificar el backend, esta es una alternativa:

#### Opción A: Guardar email/password encriptados

**⚠️ ADVERTENCIA:** Guardar contraseñas es un riesgo de seguridad. Solo usar si es absolutamente necesario.

```dart
// En lib/Auth/Signin.dart - Después del login exitoso
final _storage = FlutterSecureStorage();
await _storage.write(key: 'user_email', value: email);
await _storage.write(key: 'user_password', value: password);

// Al detectar token expirado - Auto re-login
static Future<bool> autoReLogin(BuildContext context) async {
  try {
    final _storage = FlutterSecureStorage();
    String? email = await _storage.read(key: 'user_email');
    String? password = await _storage.read(key: 'user_password');
    
    if (email != null && password != null) {
      await login(email, password, context);
      return true;
    }
  } catch (e) {
    print("Error en auto re-login: $e");
  }
  return false;
}
```

#### Opción B: Recordarle al usuario antes de expirar

Agregar un sistema de notificaciones que avise 1 día antes de que expire la sesión.

```dart
// Guardar fecha de último login
MyApp2.prefs.setString('last_login', DateTime.now().toIso8601String());

// Verificar periódicamente
void checkTokenExpiration() {
  String? lastLogin = MyApp2.prefs.getString('last_login');
  if (lastLogin != null) {
    DateTime loginDate = DateTime.parse(lastLogin);
    int daysSinceLogin = DateTime.now().difference(loginDate).inDays;
    
    if (daysSinceLogin >= 5) {
      // Mostrar notificación: "Tu sesión expirará en 1 día"
      showExpirationWarning(context);
    }
  }
}
```

---

## 🚀 Cómo Usar el Sistema de Refresh Token

### Opción 1: Usar HttpInterceptor (Recomendado)

Reemplaza tus llamadas HTTP normales con el interceptor:

**Antes:**
```dart
final response = await http.get(
  Uri.parse(myUrl),
  headers: {
    'Authorization': MyApp2.token,
    'Accept': 'application/json',
  },
);
```

**Después:**
```dart
import 'package:eboro/Helper/HttpInterceptor.dart';

final response = await HttpInterceptor.get(
  myUrl,
  context,
  headers: {
    'Authorization': MyApp2.token,
    'Accept': 'application/json',
  },
);
```

### Opción 2: Llamada Manual

Si ya tienes el código de manejo de errores, solo agrega:

```dart
if (response.statusCode == 401) {
  bool refreshed = await Auth2.refreshToken(context);
  if (refreshed) {
    // Reintentar la petición original
  } else {
    Auth2.deleteToken(context);
  }
}
```

---

## 📱 Testing del Sistema

### 1. Test con Backend Modificado:

```bash
# Simular token expirado
# En el servidor, reducir temporalmente la expiración del access token a 1 minuto
# Abrir la app, hacer login, esperar 2 minutos
# La app debería refrescar automáticamente el token
```

### 2. Test sin Backend (Simulación):

```dart
// En Auth.dart - función refreshToken(), agregar temporalmente:
static Future<bool> refreshToken(BuildContext context) async {
  // SIMULACIÓN - SOLO PARA TESTING
  print("SIMULANDO refresh exitoso");
  await Future.delayed(Duration(seconds: 1));
  return true; // Simula refresh exitoso
  
  // ... resto del código original
}
```

---

## 🔍 Debugging

Ver los logs en la consola:

```
Token expirado - intentando refrescar...
Token refrescado exitosamente
```

O si falla:
```
Error al refrescar token: [error]
No se pudo refrescar el token
```

---

## 📊 Ventajas de Cada Solución

| Aspecto | Refresh Token | Auto Re-Login | Recordatorio |
|---------|---------------|---------------|--------------|
| Seguridad | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| Experiencia de Usuario | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Implementación | Requiere Backend | Solo Frontend | Solo Frontend |
| Sesión Permanente | ✅ Sí | ✅ Sí | ❌ No |

---

## 🎯 Recomendación Final

**Para producción:** Implementar **Refresh Token** (Solución 1)
- Es el estándar de la industria
- Más seguro
- Mejor experiencia de usuario
- El usuario nunca ve la pantalla de login a menos que cierre sesión manualmente

**Para testing rápido:** Auto Re-Login (Solución 2A)
- Funciona inmediatamente
- No requiere cambios en backend
- Permite probar la funcionalidad mientras se implementa el refresh token en el servidor

---

## 📞 Próximos Pasos

1. ✅ **Frontend:** Código ya implementado
2. ⏳ **Backend:** Crear endpoint `/api/refresh-token`
3. ⏳ **Backend:** Modificar respuesta de `/api/login` para incluir `refresh_token`
4. ⏳ **Testing:** Probar flujo completo
5. ⏳ **Opcional:** Reemplazar llamadas HTTP normales con `HttpInterceptor`

---

## 💡 Notas Adicionales

- El `refresh_token` se guarda en `SharedPreferences`
- Al hacer logout, se limpia tanto el `token` como el `refresh_token`
- El sistema reintenta automáticamente 1 vez si el token expira
- Si el refresh falla, redirige al login
