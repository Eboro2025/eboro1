import 'dart:async';
import 'dart:convert';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/CashierAPI.dart';
import 'package:eboro/API/Categories.dart';
import 'package:eboro/API/Favorite.dart';
import 'package:eboro/API/Rates.dart';
import 'package:eboro/All/Status.dart';
import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/Auth/Profile.dart';
import 'package:eboro/Client/MyOrders.dart';
import 'package:eboro/Client/MyVideo.dart';
import 'package:eboro/Helper/UserData.dart';

import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/RealTime/Provider/ChatProvider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// ❌ مش هنحتاج MainScreen كصفحة أساسية
// import 'package:eboro/MainScreen.dart';

// ✅ AllProviders هي صفحة المتجر
import 'package:eboro/Providers/AllProviders.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// String globalUrl = "http://192.168.0.141:8000"; // Local server
// String globalUrl = "https://eboro.it"; // Production server
String globalUrl = "https://partnerseboro.it"; // Test server

void main() {
  runApp(
    MultiProvider(
      providers: providers,
      child: MyApp(),
    ),
  );
}

List<SingleChildWidget> providers = [
  ChangeNotifierProvider<CartTextProvider>(create: (_) => CartTextProvider()),
  ChangeNotifierProvider<UserOrderProvider>(create: (_) => UserOrderProvider()),
  ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
  ChangeNotifierProvider<ProviderController>(
      create: (_) => ProviderController()),
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
    if (index == 'it') {
      _locale = Locale("it");
    } else {
      _locale = Locale("en");
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
        Locale('en', 'US'),
        Locale('it', 'IT'),
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

      Future.microtask(() {
        if (mounted) {
          checkInternetState();
        }
      });
    } catch (e) {
      // print('Error in startTime: $e');
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
          // ⚠️ زي ما هو عندك
          // print("checkState timeout - proceeding anyway");
          if (mounted) checkAuth();
          throw Exception('Timeout');
        },
      );

      if (!mounted) return message;

      if (response.statusCode == 200) {
        Map A = json.decode(response.body);
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
        // print("checkState() no data");
        if (mounted) await checkAuth();
      }
    } catch (e) {
      // print("checkState error: $e");
      if (mounted) await checkAuth();
    }
    return message;
  }

  Future<void> checkAuth() async {
    if (!mounted) return;

    if (token == null) {
      String guestAddress = 'Posizione corrente';
      String guestLat = '45.464664';
      String guestLong = '9.188540';

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          Position? pos = await Geolocator.getLastKnownPosition();
          pos ??= await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          );

          guestLat = pos.latitude.toString();
          guestLong = pos.longitude.toString();

          try {
            final placemarks = await placemarkFromCoordinates(
              pos.latitude,
              pos.longitude,
            );
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              final address = _composeAddressFromPlacemark(p);
              if (address.replaceAll(',', '').trim().isNotEmpty) {
                guestAddress = address;
              }
            }
          } catch (_) {}
        }
      } catch (_) {}

      // إنشاء مستخدم ضيف (guest user) للوصول إلى الصفحة الرئيسية بدون تسجيل دخول
      Auth2.user = UserData(
        id: 0,
        name: 'Guest',
        email: 'guest@eboro.com',
        address: guestAddress,
        lat: guestLat,
        long: guestLong,
        type: '0',
      );

      try {
        // تحميل البيانات الأساسية
        await Categories2.getAbouts();
        await Categories2.getCategories();

        if (!mounted) return;

        // تحميل المطاعم (Providers)
        final providerController =
            Provider.of<ProviderController>(context, listen: false);
        await providerController.updateProvider(null);
        // print('✅ Providers loaded for guest user');
      } catch (e) {
        // print('Error loading data for guest: $e');
      }

      if (!mounted) return;

      // الانتقال إلى MainScreen مع bottom navigation bar (التاب الافتراضي: Negozio)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(initialIndex: 0),
        ),
      );
    } else {
      try {
        final value = await Auth2.getUserDetails(context);
        if (!mounted) return;

        if (value?.name?.isNotEmpty ?? false) {
          await _syncCustomerCurrentLocation();
          await go();
        }
      } catch (e) {
        // print('Error in checkAuth: $e');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      }
    }
  }

  Future<void> _syncCustomerCurrentLocation() async {
    try {
      if (Auth2.user == null) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );

      String resolvedAddress = "";
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          resolvedAddress = _composeAddressFromPlacemark(p);
        }
      } catch (_) {}

      if (resolvedAddress.replaceAll(',', '').trim().isEmpty) {
        resolvedAddress =
            "Lat ${pos.latitude.toStringAsFixed(6)}, Lng ${pos.longitude.toStringAsFixed(6)}";
      }

      Auth2.user!.lat = pos.latitude.toString();
      Auth2.user!.long = pos.longitude.toString();
      Auth2.user!.deliveryLat = pos.latitude.toString();
      Auth2.user!.deliveryLong = pos.longitude.toString();
      Auth2.user!.deliveryAddress = resolvedAddress;

      await Auth2.updateDeliveryCoordinates(
        pos.latitude.toString(),
        pos.longitude.toString(),
        context,
      );
    } catch (_) {}
  }

  String _composeAddressFromPlacemark(Placemark p) {
    final street = (p.street ?? '').trim();
    final houseNumber = (p.subThoroughfare ?? '').trim();
    final cap = (p.postalCode ?? '').trim();
    final city = (p.locality ?? '').trim();
    final country = (p.country ?? '').trim();

    final streetWithNumber = [street, houseNumber]
        .where((value) => value.isNotEmpty)
        .join(' ');

    return [streetWithNumber, cap, city, country]
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  Future<void> go() async {
    try {
      await Categories2.getAbouts();
      await Categories2.getCategories();

      if (!mounted) return;

      final order = Provider.of<UserOrderProvider>(context, listen: false);
      await order.updateOrder();

      if (!mounted) return;

      final providerController =
          Provider.of<ProviderController>(context, listen: false);
      try {
        await providerController.updateProvider(null);
        // print('✅ Providers loaded successfully on app start');
      } catch (e) {
        // print('❌ Error loading providers on startup: $e');
      }

      if (!mounted) return;

      await _handleDefaultType();
    } catch (e) {
      // print('Error in go(): $e');
      if (mounted) {
        _navigateToMain();
      }
    }
  }

  Future<void> _handleDefaultType() async {
    // print(MyApp2.type);

    final cart = Provider.of<CartTextProvider>(context, listen: false);

    try {
      await cart.updateCart();
      await Favorite2.getFavorite();
      await Rates2.getRates();
    } catch (e) {
      // print('Error loading data: $e');
    }

    _navigateToMain();
  }

  // ✅ نفتح MainScreen مع bottom navigation bar، التاب الافتراضي هو Negozio (index 0)
  void _navigateToMain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainScreen(initialIndex: 0),
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _navigateToReplacement(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

// -------- Main Tabs (Negozio / Ordini / Favorite / Account) --------

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late int _currentIndex;

  // Owner branch status
  bool _isOwner = false;
  String _branchStatus = 'close'; // 'open' or 'close'
  String _branchName = '';
  int? _branchId;
  Timer? _ownerStatusTimer;

  // Live GPS tracking
  StreamSubscription<Position>? _positionStream;

  // Lazy page loading: only build pages when first visited
  final Map<int, Widget> _builtPages = {};
  final Set<int> _visitedTabs = {};

  // Video tab visibility notifier
  final ValueNotifier<bool> _videoVisible = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _visitedTabs.add(_currentIndex);
    // Start live GPS tracking (like Uber)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startLocationTracking();
    });
    // Check if owner and load branch status
    _checkOwnerStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ownerStatusTimer?.cancel();
    _positionStream?.cancel();
    _videoVisible.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Resume tracking if stream was cancelled
      if (_positionStream == null) {
        _startLocationTracking();
      }
    } else if (state == AppLifecycleState.paused) {
      // Pause tracking when app is in background to save battery
      _positionStream?.cancel();
      _positionStream = null;
    }
  }

  Future<void> _checkOwnerStatus() async {
    if (MyApp2.type == '2' || MyApp2.type == '5') {
      _isOwner = true;
      await _fetchBranchStatus();
      // Auto refresh every 30 seconds
      _ownerStatusTimer = Timer.periodic(
          const Duration(seconds: 30), (_) => _fetchBranchStatus());
    }
  }

  Future<void> _fetchBranchStatus() async {
    final result = await CashierAPI2().getMyBranches();
    if (result != null && mounted) {
      setState(() {
        _branchStatus = result['status'] ?? 'close';
        _branchName = result['name'] ?? '';
        _branchId = result['id'];
      });
    }
  }

  Future<void> _toggleOwnerBranch() async {
    if (_branchId == null) return;
    final newStatus = _branchStatus == 'open' ? 1 : 0;
    final success =
        await CashierAPI2().toggleBranchStatus(_branchId!, newStatus);
    if (success) {
      await _fetchBranchStatus();
    }
  }

  /// Live GPS tracking like Uber - continuous position updates
  Future<void> _startLocationTracking() async {
    try {
      if (Auth2.user == null) return;

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      // Get initial position immediately
      Position? initialPos = await Geolocator.getLastKnownPosition();
      if (initialPos != null) {
        await _updateLocation(initialPos);
      }

      // Start continuous tracking
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters of movement
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          if (mounted) _updateLocation(position);
        },
        onError: (e) {
          print('Location stream error: $e');
        },
      );
    } catch (e) {
      print('Location tracking error: $e');
    }
  }

  String _composeAddressFromPlacemark(Placemark p) {
    final street = (p.street ?? '').trim();
    final houseNumber = (p.subThoroughfare ?? '').trim();
    final cap = (p.postalCode ?? '').trim();
    final city = (p.locality ?? '').trim();
    final country = (p.country ?? '').trim();

    final streetWithNumber = [street, houseNumber]
        .where((value) => value.isNotEmpty)
        .join(' ');

    return [streetWithNumber, cap, city, country]
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  /// Update location data from a GPS position
  Future<void> _updateLocation(Position position) async {
    try {
      if (Auth2.user == null) return;

      // Reverse geocode to address
      String newAddress = "";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          newAddress = _composeAddressFromPlacemark(p);
        }
      } catch (_) {}

      // Update locally
      Auth2.user!.deliveryLat = position.latitude.toString();
      Auth2.user!.deliveryLong = position.longitude.toString();
      if (newAddress.isNotEmpty) {
        Auth2.user!.deliveryAddress = newAddress;
      }

      if (mounted) {
        // Update coordinates on server
        await Auth2.updateDeliveryCoordinates(
          position.latitude.toString(),
          position.longitude.toString(),
          context,
        );

        // Reload providers with new location
        if (mounted) {
          final providerController =
              Provider.of<ProviderController>(context, listen: false);
          await providerController
              .updateProvider(providerController.categoryId);
          if (mounted) {
            _builtPages.remove(0);
            setState(() {});
          }
        }
      }
    } catch (e) {
      print('Location update error: $e');
    }
  }

  Widget _buildOwnerStatusBanner() {
    final isOpen = _branchStatus == 'open';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
        left: 16,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF4CAF50) : const Color(0xFFC62828),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isOpen ? Icons.storefront_rounded : Icons.lock_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _branchName.isNotEmpty ? _branchName : 'Il tuo negozio',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  isOpen ? 'Aperto' : 'Chiuso',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _toggleOwnerBranch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isOpen ? Colors.red : const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0,
            ),
            child: Text(
              isOpen ? 'Chiudi' : 'Apri',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    if (!_builtPages.containsKey(index)) {
      switch (index) {
        case 0:
          _builtPages[0] = const AllProviders(catID: null, name: null);
          break;
        case 1:
          _builtPages[1] = const MyOrders();
          break;
        case 2:
          _builtPages[2] = MyVideo(isVisible: _videoVisible);
          break;
        case 3:
          _builtPages[3] = MyProfile();
          break;
      }
    }
    return _builtPages[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _videoVisible.value = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Column(
          children: [
            // Owner branch status banner
            if (_isOwner) _buildOwnerStatusBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: List.generate(4, (i) {
                  // Only build pages that have been visited
                  if (_visitedTabs.contains(i)) {
                    return _getPage(i);
                  }
                  return const SizedBox.shrink();
                }),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Consumer<UserOrderProvider>(
          builder: (context, orderProvider, _) {
            final activeCount = orderProvider.order?.where((o) {
                  final s = (o.status ?? '').toLowerCase();
                  return s == 'pending' ||
                      s == 'in progress' ||
                      s == 'to delivering' ||
                      s == 'on way' ||
                      s == 'on delivering';
                }).length ??
                0;

            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              selectedItemColor: myColor,
              unselectedItemColor: Colors.black54,
              onTap: (index) => setState(() {
                _visitedTabs.add(index);
                _currentIndex = index;
                _videoVisible.value = (index == 2);
              }),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.storefront),
                  label: AppLocalizations.of(context)?.translate("store") ??
                      "Negozio",
                ),
                BottomNavigationBarItem(
                  icon: activeCount > 0
                      ? badges.Badge(
                          position: BadgePosition.topEnd(top: -5, end: -10),
                          badgeContent: Text(
                            activeCount.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                          badgeStyle: const badges.BadgeStyle(
                            badgeColor: Color(0xFFC12732),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: AppLocalizations.of(context)?.translate("myorders") ??
                      "Ordini",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.videocam_outlined),
                  label: "Video",
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  label: AppLocalizations.of(context)?.translate("myprofile") ??
                      "Account",
                ),
              ],
            );
          },
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
