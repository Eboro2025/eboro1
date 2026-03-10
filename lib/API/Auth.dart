import 'dart:async';
import 'dart:convert';

import 'package:eboro/API/Categories.dart';
import 'package:eboro/API/Favorite.dart';
import 'package:eboro/API/Rates.dart';
import 'package:eboro/Auth/EmailVerification.dart';
import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/Client/Addresses.dart';

import 'package:eboro/MainScreen.dart' as screens;
import 'package:eboro/Client/Location.dart';

import 'package:eboro/Helper/UserData.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:eboro/Helper/HttpInterceptor.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Auth extends StatefulWidget {
  @override
  Auth2 createState() => Auth2();
}

class Auth2 extends State<Auth> {
  static UserData? user;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

  State<StatefulWidget>? createState() {
    return null;
  }

  // -------------------- LOGIN --------------------
  static Future<void> login(
    String email,
    String password,
    BuildContext context, {
    Function? onChange,
  }) async {
    Progress.progressDialogue(context);
    final String myUrl = "$globalUrl/api/login";
    print('DEBUG LOGIN: calling $myUrl');
    try {
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {
          "email": email,
          "password": password,
        },
      );

      print('DEBUG LOGIN: status=${response.statusCode}');
      print('DEBUG LOGIN: body=${response.body}');

      Map A;
      try {
        A = json.decode(response.body);
      } catch (e) {
        print('DEBUG LOGIN: JSON decode error: $e');
        show("Si è verificato un errore durante l'accesso");
        return;
      }

      if (A['errors'] != null) {
        print('DEBUG LOGIN: errors=${A['errors']}');
        show(A['errors'].toString());
        return;
      }

      if (A['data'] != null) {
        MyApp2.prefs.setString('firstTime', "firstTime");
        MyApp2.token = "Bearer ${A["data"]["token"]}";

        // حفظ refresh token لو موجود
        if (A["data"]["refresh_token"] != null) {
          MyApp2.prefs.setString(
            'refresh_token',
            A["data"]["refresh_token"],
          );
        }

        await getUserDetails(context);
        await checkType(MyApp2.token!, context);

        if (onChange != null) {
          await onChange.call();
        }
      }

      if (A['message'] != null) {
        show(A['message'].toString());
      }
    } catch (e) {
      print('DEBUG LOGIN: EXCEPTION: $e');
      show("Si è verificato un errore durante l'accesso");
    } finally {
      Progress.dimesDialog(context);
    }
  }

  // -------------------- SOCIAL LOGIN --------------------
  static Future<void> googlefacebooklogin(
    String email,
    String? name,
    String? image,
    String socialid,
    String flag,
    BuildContext context,
  ) async {
    Progress.progressDialogue(context);
    final String myUrl = "$globalUrl/api/login/social";

    try {
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {'Accept': 'application/json'},
        body: {
          "email": email,
          "name": name ?? '',
          "image": image ?? '',
          "socialid": socialid,
          "flag": flag,
        },
      );

      Map A = json.decode(response.body);
      // print(response.body);

      if (A['errors'] != null) {
        show(A['errors'].toString());
      } else if (A['data'] != null) {
        MyApp2.prefs.setString('firstTime', "firstTime");
        MyApp2.prefs.setBool('gof', true);
        MyApp2.token = "Bearer ${A["data"]["token"]}";

        // حفظ refresh token لو موجود
        if (A["data"]["refresh_token"] != null) {
          MyApp2.prefs.setString(
            'refresh_token',
            A["data"]["refresh_token"],
          );
        }

        await getUserDetails(context);
       await checkType(MyApp2.token!, context);

      }

      if (A['message'] != null) {
        show(A['message'].toString());
      }
    } catch (e) {
      // print("Error in googlefacebooklogin: $e");
      String errorMessage =
          "Something went wrong. Please try again.\nError: $e";
      show(errorMessage);
    }
  }

  // -------------------- TOAST --------------------
  static show(String message) async {
    FToast fToast = FToast();
    fToast.init(navigatorKey.currentContext!);
    fToast.showToast(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: Colors.black87,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
      toastDuration: const Duration(seconds: 2),
      gravity: ToastGravity.CENTER,
    );
  }

  // -------------------- CHECK TYPE (بدون كاشير/دليفري) --------------------
  static Future<UserData?> checkType(
    String token,
    BuildContext context,
  ) async {
    UserData? users;
    try {
      final String myUrl = "$globalUrl/api/user-details";
      final response = await HttpInterceptor.get(
        myUrl,
        context: context,
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': token,
        },
      );

      Map<String, dynamic> B;
      try {
        B = json.decode(response.body);
      } catch (e) {
        show("Si è verificato un errore durante l'accesso");
        return null;
      }
      // print(B.toString());

      if (B['code'].toString().contains('406') ||
          response.statusCode == 406) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmailVerification()),
        );
        return null;
      }

      if (response.statusCode != 200) {
        if (B['message'] != null) {
          show(B['message'].toString());
        } else {
          show("Si è verificato un errore durante l'accesso");
        }
        return null;
      }

      if (B['data'] == null) {
        if (B['message'] != null) {
          show(B['message'].toString());
        } else {
          show("Si è verificato un errore durante l'accesso");
        }
        return null;
      }

      if (response.statusCode == 200) {
        Map<String, dynamic> A = B['data'];
        users = UserData.fromJson(A);
        user = users;

        MyApp2.prefs.setString('token', token);

        // 1 = Admin, 0 = User عادي
        if (user?.type == 'Admin') {
          MyApp2.prefs.setString('type', '1');
        } else {
          MyApp2.prefs.setString('type', '0');
        }

        // تشغيل جميع الـ API calls بالتوازي بدلاً من التتابع
        final cart =
            Provider.of<CartTextProvider>(context, listen: false);
        final providerController =
            Provider.of<ProviderController>(context, listen: false);
        await Future.wait<dynamic>([
          Categories2.getCategories(),
          Categories2.getAbouts(),
          cart.updateCart(),
          Favorite2.getFavorite(),
          Rates2.getRates(),
          providerController.updateProvider(null),
        ]);

        if (user != null && user?.lat != null && user?.long != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const screens.MainScreen(initialIndex: 0)),
            (Route<dynamic> route) => false,
          );
        } else {
          SetLocation(rout: "home");
        }
      }
    } catch (e) {
      // print(e);
      show("Si è verificato un errore durante l'accesso");
    }
    return users;
  }

  // -------------------- SIGN UP --------------------
  static signUp(
    String name,
    String email,
    String mobile,
    String password,
    String confirmation,
    String address,
    String? base64Image,
    String? fileNames,
    String? lat,
    String? long,
    BuildContext context,
  ) async {
    Progress.progressDialogue(context);
    final String myUrl = '$globalUrl/api/register';

    http
        .post(
      Uri.parse(myUrl),
      headers: {
        'apiLang': MyApp2.apiLang.toString(),
      },
      body: {
        'name': name,
        'email': email,
        'mobile': mobile,
        'password': password,
        'password_confirmation': confirmation,
        'address': address,
        "base64Image": base64Image ?? "",
        "fileNames": fileNames ?? "",
        'type': '0',
        "flag": "json",
        'lat': lat,
        'long': long,
      },
    )
        .then((response) async {
      Map? B = json.decode(response.body);
      if (response.statusCode == 200) {
        Progress.dimesDialog(context);
        // Auto-login dopo la registrazione
        await login(email, password, context);
      } else {
        Progress.dimesDialog(context);
        show(B!['errors'].toString());
      }
    });
  }

  // -------------------- USER DETAILS + REFRESH TOKEN --------------------
  static Future<UserData?> getUserDetails(
      BuildContext context) async {
    UserData? users;
    try {
      String myUrl = "$globalUrl/api/user-details";
      final response = await HttpInterceptor.get(
        myUrl,
        context: context,
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': "${MyApp2.token}",
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> A =
            json.decode(response.body)['data'];
        users = UserData.fromJson(A);
        user = users;

        if (A["message"] != null &&
            A["message"].toString().contains("Unauthenticated")) {
          deleteToken(context);
        } else if (users.lat == null && users.long == null) {
          SetLocation(rout: "home");
          await Categories2.getCategories();
        }
      } else if (response.statusCode == 401) {
        // Token منتهي - HttpInterceptor حاول يعمل refresh تلقائي
        // print("Token still expired after refresh attempt");
        RemoveToken(context);
      } else {
        RemoveToken(context);
      }
    } catch (e) {
      // print(e);
    }
    return users;
  }

  // -------------------- REFRESH TOKEN --------------------
  static Future<bool> refreshToken(BuildContext context) async {
    try {
      String? refreshToken =
          MyApp2.prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final String myUrl = "$globalUrl/api/refresh-token";
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        Map A = json.decode(response.body);
        if (A['data'] != null && A['data']['token'] != null) {
          MyApp2.token = "Bearer ${A["data"]["token"]}";
          MyApp2.prefs.setString('token', MyApp2.token!);

          if (A["data"]["refresh_token"] != null) {
            MyApp2.prefs.setString(
              'refresh_token',
              A["data"]["refresh_token"],
            );
          }

          // print("Token refreshed successfully");
          return true;
        }
      }
    } catch (e) {
      // print("Error refreshing token: $e");
    }
    return false;
  }

  // -------------------- REMOVE TOKEN (بسيط) --------------------
  static void RemoveToken(BuildContext context) async {
    SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.remove('token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // -------------------- LOGOUT كامل --------------------
  static deleteToken(BuildContext context) async {
    bool? isgof = MyApp2.prefs.getBool('gof');
    if (isgof == true) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    MyApp2.prefs.remove('token');
    MyApp2.prefs.remove('refresh_token');
    MyApp2.prefs.remove('type');
    MyApp2.prefs.remove('gof');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // -------------------- VERIFY EMAIL --------------------
  static verifyEmail(String v, BuildContext context) async {
    Progress.progressDialogue(context);
    final String myUrl = '$globalUrl/api/verifyEmail';

    final response = await HttpInterceptor.post(
      myUrl,
      context: context,
      headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },
      body: {
        'verify_code': v,
      },
    );
    Map B = json.decode(response.body);
    if (B['status'].toString().contains('success')) {
      checkType("Bearer ${B["data"]["token"]}", context);
    } else {
      show(B['message'].toString());
    }
    Progress.dimesDialog(context);
  }

  // -------------------- EDIT LOCATION --------------------
  static Future<bool> editUserlocations(
    String? address,
    String lat,
    String long,
    BuildContext context, {
    bool navigate = true,
    bool showProgress = true,
  }) async {
    if (showProgress) Progress.progressDialogue(context);
    try {
      String myUrl = "$globalUrl/api/edit-profile";
      final response = await HttpInterceptor.post(
        myUrl,
        context: context,
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': "${MyApp2.token}",
        },
        body: {
          'lat': lat,
          'long': long,
          'address': address,
        },
      );

      if (response.statusCode == 200) {
        Map A = json.decode(response.body)['data'];
        user = UserData.fromJson(A['user']);
        // تأكد إن الإحداثيات اللي أرسلناها هي اللي تبقى (مش اللي رجعت من السيرفر)
        user?.lat = lat;
        user?.long = long;
        if (address != null && address.isNotEmpty) {
          user?.address = address;
        }
        if (navigate) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AddAddress()),
          );
        }
        return true;
      }
    } catch (e) {
      // print(e);
    }
    return false;
  }

  // Update only lat/long on server (for distance/shipping calculation)
  // Does NOT update the profile address
  static Future<void> updateDeliveryCoordinates(
    String lat,
    String long,
    BuildContext context,
  ) async {
    try {
      String myUrl = "$globalUrl/api/edit-profile";
      final response = await HttpInterceptor.post(
        myUrl,
        context: context,
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': "${MyApp2.token}",
        },
        body: {
          'lat': lat,
          'long': long,
        },
      );

      if (response.statusCode == 200) {
        Map A = json.decode(response.body)['data'];
        // Save delivery fields before re-parsing user
        final savedDeliveryAddress = user?.deliveryAddress;
        final savedDeliveryLat = user?.deliveryLat;
        final savedDeliveryLong = user?.deliveryLong;
        user = UserData.fromJson(A['user']);
        // Restore delivery address (not in server response)
        user?.deliveryAddress = savedDeliveryAddress;
        user?.deliveryLat = savedDeliveryLat;
        user?.deliveryLong = savedDeliveryLong;
      }
    } catch (e) {
      print('DEBUG updateDeliveryCoordinates error: $e');
    }
  }

  static Future<void> editUserlocationsHints(
    String mobile,
    String house,
    String intercom,
    BuildContext context, {
    String cap = '',
    String whatsapp = '',
    bool navigate = true,
    bool showProgress = true,
    bool popOnDone = true,
  }) async {
    if (showProgress) Progress.progressDialogue(context);
    try {
      String myUrl = "$globalUrl/api/edit-location";
      final response = await HttpInterceptor.post(
        myUrl,
        context: context,
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': "${MyApp2.token}",
        },
        body: {
          'mobile': mobile,
          'house': house,
          'intercom': intercom,
          'cap': cap,
          'whatsapp': whatsapp,
        },
      );

      if (response.statusCode == 200) {
        Map A = json.decode(response.body)['data'];
        // حفظ العنوان والإحداثيات الحالية قبل ما السيرفر يكتب فوقها
        final savedAddress = user?.address;
        final savedLat = user?.lat;
        final savedLong = user?.long;
        user = UserData.fromJson(A['user']);
        // استعادة العنوان والإحداثيات لو السيرفر رجع قيم مختلفة
        if (savedAddress != null && savedAddress.isNotEmpty) {
          user?.address = savedAddress;
        }
        if (savedLat != null && savedLat.isNotEmpty) {
          user?.lat = savedLat;
        }
        if (savedLong != null && savedLong.isNotEmpty) {
          user?.long = savedLong;
        }
        if (navigate) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const screens.MainScreen(initialIndex: 0)),
          );
        } else {
          if (showProgress) Progress.dimesDialog(context);
          if (popOnDone) Navigator.pop(context);
        }
      } else {
        // print("editUserlocationsHints() no data");
      }
    } catch (e) {
      // print(e);
    }
  }

  // -------------------- CHANGE PASSWORD --------------------
  static changePassword(
    String oldPassword,
    String newPassword,
    String confirmNewPassword,
    BuildContext context,
  ) async {
    Progress.progressDialogue(context);
    final String myUrl = "$globalUrl/api/changePassword";

    final response = await HttpInterceptor.post(
      myUrl,
      context: context,
      headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },
      body: {
        'password': newPassword,
        'old_password': oldPassword,
        'password_confirmation': confirmNewPassword,
      },
    );
    Map B = json.decode(response.body);
    if (B["status"] == 'success') {
      show(B['message'].toString());
    } else {
      if (B['errors'] != null) {
        show(B['errors']['password'].toString());
      }
      if (B['message'] != null) {
        show(B['message'].toString());
      }
    }
    Progress.dimesDialog(context);
  }

  // -------------------- EDIT USER DETAILS --------------------
  static editUserDetails(
    String? name,
    String? email,
    String? mobile,
    String? address,
    String? base64Image,
    String? fileNames,
    String? lat,
    String? long,
    String? online, // تقدر تشيله لو خلاص مش محتاجه
    BuildContext context,
  ) async {
    Progress.progressDialogue(context);
    final String myUrl = "$globalUrl/api/edit-profile";

    final response = await HttpInterceptor.post(
      myUrl,
      context: context,
      headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },
      body: {
        if (name != null) 'name': name,
        if (mobile != null) 'mobile': mobile,
        if (address != null) 'address': address,
        if (email != null) 'email': email,
        if (base64Image != null) "base64Image": base64Image,
        if (base64Image != null) "fileNames": fileNames,
        if (base64Image != null) "flag": "json",
        if (lat != null) 'lat': lat,
        if (long != null) 'long': long,
        if (online != null) 'online': online,
      },
    );
    Map C = json.decode(response.body);
    // print(response.body);

    if (C["code"] == 200) {
      Progress.dimesDialog(context);
      // حفظ العنوان والإحداثيات قبل ما getUserDetails يكتب فوقها
      final savedAddress = address;
      final savedLat = lat;
      final savedLong = long;
      await getUserDetails(context);
      // استعادة القيم اللي المستخدم أدخلها لو getUserDetails رجعت قيم مختلفة
      if (savedAddress != null && savedAddress.isNotEmpty) {
        user?.address = savedAddress;
      }
      if (savedLat != null && savedLat.isNotEmpty) {
        user?.lat = savedLat;
      }
      if (savedLong != null && savedLong.isNotEmpty) {
        user?.long = savedLong;
      }

      if (lat != null && long != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const screens.MainScreen(initialIndex: 0)),
        );
      }
    } else {
      Progress.dimesDialog(context);
    }
  }

  // -------------------- RESEND VERIFY EMAIL --------------------
  static resendVerifyEmail(BuildContext context) async {
    final String myUrl = '$globalUrl/api/send_verifyEmail';

    final response = await HttpInterceptor.get(
      myUrl,
      context: context,
      headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      },
    );
    Map B = json.decode(response.body);
    // print(response.body);
    show(B['message'].toString());
  }

  // -------------------- FORGOT PASSWORD (SEND CODE) --------------------
  static Future<void> sendResetCode(
    String email,
    BuildContext context,
  ) async {
    Progress.progressDialogue(context);
    final String myUrl = "$globalUrl/api/sendResetCode";

    try {
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {
          "email": email,
        },
      );

      Map A = json.decode(response.body);
      // print(response.body);

      Progress.dimesDialog(context);

      if (A['status'] == 'success') {
        show(A['message'].toString());
        // يمكنك توجيه المستخدم لصفحة إدخال الكود هنا
      } else if (A['errors'] != null) {
        show(A['errors'].toString());
      } else if (A['message'] != null) {
        show(A['message'].toString());
      }
    } catch (e) {
      Progress.dimesDialog(context);
      // print("Error in sendResetCode: $e");
      show("Something went wrong. Please try again.");
    }
  }

  // -------------------- RESET PASSWORD --------------------
  static Future<void> resetPassword(
    String email,
    String verifyCode,
    String newPassword,
    String confirmPassword,
    BuildContext context,
  ) async {
    Progress.progressDialogue(context);
    final String myUrl = "$globalUrl/api/resetPassword";

    try {
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {
          "email": email,
          "verify_code": verifyCode,
          "password": newPassword,
          "password_confirmation": confirmPassword,
        },
      );

      Map A = json.decode(response.body);
      // print(response.body);

      Progress.dimesDialog(context);

      if (A['status'] == 'success') {
        show(A['message'].toString());
        // بعد نجاح إعادة تعيين كلمة المرور، توجيه للـ Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else if (A['errors'] != null) {
        show(A['errors'].toString());
      } else if (A['message'] != null) {
        show(A['message'].toString());
      }
    } catch (e) {
      Progress.dimesDialog(context);
      // print("Error in resetPassword: $e");
      show("Something went wrong. Please try again.");
    }
  }

  // -------------------- SEND OTP (Phone Login) --------------------
  static Future<void> sendOTP(
    String mobile,
    BuildContext context,
  ) async {
    Progress.progressDialogue(context);
    final String myUrl = "$globalUrl/api/sendOTP";

    try {
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {
          "mobile": mobile,
        },
      );

      Progress.dimesDialog(context);

      Map A = json.decode(response.body);

      if (A['status'] == 'success') {
        show(A['message'].toString());
      } else if (A['errors'] != null) {
        show(A['errors'].toString());
      } else if (A['message'] != null) {
        show(A['message'].toString());
      }
    } catch (e) {
      Progress.dimesDialog(context);
      show("Something went wrong. Please try again.");
    }
  }

  // -------------------- VERIFY OTP (Phone Login) --------------------
  static Future<void> verifyOTP(
    String mobile,
    String otp,
    BuildContext context,
  ) async {
    Progress.progressDialogue(context);
    final String myUrl = "$globalUrl/api/verifyOTP";

    try {
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {
          "mobile": mobile,
          "otp": otp,
        },
      );

      Progress.dimesDialog(context);

      Map A = json.decode(response.body);

      if (A['status'] == 'success' && A['data'] != null) {
        MyApp2.prefs.setString('firstTime', "firstTime");
        MyApp2.token = "Bearer ${A["data"]["token"]}";

        if (A["data"]["refresh_token"] != null) {
          MyApp2.prefs.setString('refresh_token', A["data"]["refresh_token"]);
        }

        await getUserDetails(context);
        await checkType(MyApp2.token!, context);
      } else if (A['errors'] != null) {
        show(A['errors'].toString());
      } else if (A['message'] != null) {
        show(A['message'].toString());
      }
    } catch (e) {
      Progress.dimesDialog(context);
      show("Something went wrong. Please try again.");
    }
  }
}

// -------------------- SAFE DATE PARSE --------------------
DateTime safeDateParse(String dateStr) {
  // Fix malformed dates like "2026-02-19T22:41:18000000Z"
  // where the dot before fractional seconds is missing.
  final fixed = dateStr.replaceFirstMapped(
    RegExp(r'(\d{2}:\d{2}:\d{2})(\d{3,6})(Z?)$'),
    (m) => '${m[1]}.${m[2]}${m[3]}',
  );
  return DateTime.parse(fixed);
}

// -------------------- TIMEZONE EXTENSION --------------------
extension TimeZoneExtension on Object {
  DateTime _convertTimeDateTime() {
    return safeDateParse(toString());
  }

  DateTime getLocalTimeZone() {
    return _convertTimeDateTime().toLocal();
  }

  DateTime getUtcTimeZone() {
    return _convertTimeDateTime().toUtc();
  }

  int getTimeZoneOffSet() {
    int timeZoneOffset =
        _convertTimeDateTime().toLocal().timeZoneOffset.inHours;
    return timeZoneOffset;
  }

  DateTime get dateTimeAfterOffset =>
      _convertTimeDateTime().add(
        Duration(
          hours: int.parse(getTimeZoneOffSet().toString()),
        ),
      );
}
