import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/UserData.dart';
import 'package:eboro/API/Categories.dart';
import 'package:eboro/API/Favorite.dart';
import 'package:eboro/API/Rates.dart';
import 'package:eboro/All/Status.dart';
import 'package:eboro/Auth/Signin.dart';

import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/RealTime/Provider/ChatProvider.dart';
import 'package:eboro/RealTime/Provider/ProductCacheProvider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/MainScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:eboro/All/NotificationService.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String globalUrl = "https://eboro.it";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase only works on Android/iOS/Web
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      kIsWeb) {
    final firebaseReady = await _safeInitFirebase();
    if (firebaseReady) {
      try {
        await NotificationService.initialize();
      } catch (_) {}
    }
  }

  runApp(
    MultiProvider(
      providers: providers,
      child: MyApp(),
    ),
  );
}

Future<bool> _safeInitFirebase() async {
  try {
    await Firebase.initializeApp();
    return Firebase.apps.isNotEmpty;
  } on PlatformException catch (e) {
    if (kDebugMode) {
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
    }
    return false;
  }
}

List<SingleChildWidget> providers = [
  ChangeNotifierProvider<CartTextProvider>(create: (_) => CartTextProvider()),
  ChangeNotifierProvider<UserOrderProvider>(create: (_) => UserOrderProvider()),
  ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
  ChangeNotifierProvider<ProviderController>(
      create: (_) => ProviderController()),
  ChangeNotifierProvider<ProductCacheProvider>(
      create: (_) => ProductCacheProvider()),
];

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static void setLocale(BuildContext context, String? index) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(index);
  }

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('it');

  setLocale(String? index) {
    if (index != null &&
        [
          'it',
          'en',
          'ar',
          'fr',
          'de',
          'es',
          'pt',
          'tr',
          'ro',
          'sq',
          'zh',
          'hi',
          'ru'
        ].contains(index)) {
      _locale = Locale(index);
    } else {
      _locale = Locale("it");
    }
    setState(() {});
  }

  String? apiLang;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: myColor,
        primaryColorDark: myColor,
        secondaryHeaderColor: myColor,
        brightness: Brightness.light,
        fontFamily: 'Nunito',
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFFAD232D),
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      title: 'Eboro',
      locale: _locale,
      navigatorKey: navigatorKey,
      supportedLocales: [
        Locale('it', 'IT'),
        Locale('en', 'US'),
        Locale('ar'),
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
        Locale('es', 'ES'),
        Locale('pt', 'PT'),
        Locale('tr', 'TR'),
        Locale('ro', 'RO'),
        Locale('sq'),
        Locale('zh', 'CN'),
        Locale('hi', 'IN'),
        Locale('ru', 'RU'),
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) => Overlay(
        initialEntries: [
          if (child != null) ...[
            OverlayEntry(
              builder: (context) => child,
            ),
          ],
        ],
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  MyApp2 createState() => MyApp2();
}

class MyApp2 extends State<MyHomePage> {
  static double? H,
      W,
      fontSize26,
      fontSize24,
      fontSize22,
      fontSize20,
      fontSize18,
      fontSize16,
      fontSize14,
      fontSize12;
  static String? apiLang, token, firstTime, type;
  static late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    startTime();
  }

  Future<void> getlangValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('apiLang')) {
      prefs.setString('apiLang', 'it');
    }
    String? lang = prefs.getString("apiLang");
    if (mounted) {
      MyApp.setLocale(context, lang);
    }
  }

  startTime() async {
    try {

      prefs = await SharedPreferences.getInstance();
      apiLang = prefs.getString('apiLang');
      token = prefs.getString('token');
      firstTime = prefs.getString('firstTime');
      type = prefs.getString('type');


      await getlangValues();

      // استخدام Future.microtask بدلاً من Timer لتحسين الأداء
      Future.microtask(() {
        if (mounted) {

          checkInternetState();
        }
      });
    } catch (e) {
      if (mounted) {
        checkInternetState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    H = size.height;
    W = size.width;

    // تحسين الأداء بحساب الخطوط مرة واحدة
    final baseWidth = size.width;
    fontSize26 = baseWidth * .08;
    fontSize24 = baseWidth * .075;
    fontSize22 = baseWidth * .065;
    fontSize20 = baseWidth * .055;
    fontSize18 = baseWidth * .05;
    fontSize16 = baseWidth * .045;
    fontSize14 = baseWidth * .035;
    fontSize12 = baseWidth * .025;

    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      child: Container(
        margin: const EdgeInsets.all(30.0),
        width: W! * .6,
        height: H! * .6,
        child: Image.asset(
          "images/icons/logo.png",
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  checkInternetState() async {
    await checkState();
  }

  Future<String?> checkState() async {
    String? message;
    try {
      String myUrl = "$globalUrl/api/status";
      final response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'apiLang': apiLang.toString(),
          'Accept': 'application/json',
          'Authorization': "${MyApp2.token}",
        },
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (mounted) checkAuth();
          throw Exception('Timeout');
        },
      );

      if (!mounted) return message;

      if (response.statusCode == 200) {
        Map A = json.decode(response.body);

        // Force update check
        String? minVersion = A['min_version'];
        if (minVersion != null && minVersion.isNotEmpty) {
          try {
            final packageInfo = await PackageInfo.fromPlatform();
            if (_isVersionOlder(packageInfo.version, minVersion)) {
              if (mounted) _showForceUpdateDialog();
              return message;
            }
          } catch (_) {}
        }

        String? state = A['state'];
        if (state == 'open') {
          await checkAuth();
        } else {
          String? message = A['message'];
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Status(status: message),
              ),
            );
          }
        }
      } else {
        if (mounted) await checkAuth();
      }
    } catch (e) {
      if (mounted) await checkAuth();
    }
    return message;
  }

  Future<void> checkAuth() async {
    if (!mounted) return;

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      try {
        final value = await Auth2.getUserDetails(context).timeout(
          const Duration(seconds: 8),
          onTimeout: () => null,
        );
        if (!mounted) return;

        if (value?.name?.isNotEmpty ?? false) {
          await go();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      } catch (e) {
        // Auth check failed
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      }
    }
  }

  Future<void> go() async {
    try {
      await Auth2.setLocationFromGPS();
      await UserData.loadDeliveryAddress();

      final order = Provider.of<UserOrderProvider>(context, listen: false);
      final providerController =
          Provider.of<ProviderController>(context, listen: false);
      final cart = Provider.of<CartTextProvider>(context, listen: false);

      // البيانات الأساسية بالتوازي (مع timeout عشان ما يعلقش)
      await Future.wait<dynamic>([
        Categories2.getAbouts(),
        Categories2.getCategories(),
        order.updateOrder(),
        providerController.updateProvider(null),
      ]).timeout(
        const Duration(seconds: 8),
        onTimeout: () => [null, null, null, null],
      );

      if (!mounted) return;

      _navigateToMain();

      // البيانات الثانوية تتحمل في الخلفية بعد الانتقال
      cart.updateCart().catchError((_) {});
      Favorite2.getFavorite().catchError((_) => null);
      Rates2.getRates().catchError((_) {});
    } catch (e) {
      if (mounted) {
        _navigateToMain();
      }
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) =>
              const MainScreen(initialIndex: 2)),
      (Route<dynamic> route) => false,
    );
  }

  bool _isVersionOlder(String current, String minimum) {
    final cur = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final min = minimum.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (cur.length < 3) cur.add(0);
    while (min.length < 3) min.add(0);
    for (int i = 0; i < 3; i++) {
      if (cur[i] < min[i]) return true;
      if (cur[i] > min[i]) return false;
    }
    return false;
  }

  void _showForceUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Aggiornamento richiesto'),
          content: const Text(
            'È disponibile una nuova versione dell\'app. Per continuare ad utilizzare Eboro, aggiorna l\'app.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                final url = Platform.isIOS
                    ? 'https://apps.apple.com/app/eboro/id6670428798'
                    : 'https://play.google.com/store/apps/details?id=com.codiano.eboro';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              child: const Text('Aggiorna ora', style: TextStyle(color: Color(0xFFC12732))),
            ),
          ],
        ),
      ),
    );
  }
}

MaterialColor myColor = MaterialColor(0xFFC12732, color);
Map<int, Color> color = {
  50: Color.fromRGBO(4, 131, 184, .1),
  100: Color.fromRGBO(4, 131, 184, .2),
  200: Color.fromRGBO(4, 131, 184, .3),
  300: Color.fromRGBO(4, 131, 184, .4),
  400: Color.fromRGBO(4, 131, 184, .5),
  500: Color.fromRGBO(4, 131, 184, .6),
  600: Color.fromRGBO(4, 131, 184, .7),
  700: Color.fromRGBO(4, 131, 184, .8),
  800: Color.fromRGBO(4, 131, 184, .9),
  900: Color.fromRGBO(4, 131, 184, 1),
};

MaterialColor myColor2 = MaterialColor(0xFF515C6F, color2);
Map<int, Color> color2 = {
  50: Color.fromRGBO(4, 131, 184, .1),
  100: Color.fromRGBO(4, 131, 184, .2),
  200: Color.fromRGBO(4, 131, 184, .3),
  300: Color.fromRGBO(4, 131, 184, .4),
  400: Color.fromRGBO(4, 131, 184, .5),
  500: Color.fromRGBO(4, 131, 184, .6),
  600: Color.fromRGBO(4, 131, 184, .7),
  700: Color.fromRGBO(4, 131, 184, .8),
  800: Color.fromRGBO(4, 131, 184, .9),
  900: Color.fromRGBO(4, 131, 184, 1),
};
