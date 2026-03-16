import 'dart:async';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/CashierAPI.dart';
import 'package:eboro/Auth/Profile.dart';
import 'package:eboro/Client/MyOrders.dart';
import 'package:eboro/Client/MyVideo.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:eboro/Helper/UserData.dart';
import 'package:eboro/Providers/AllProviders.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eboro/main.dart';

// All app initialization (MyApp, MyHomePage, MyApp2) is in main.dart
// This file only contains MainScreen (bottom navigation tabs)

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
    // Start live GPS tracking immediately
    _startLocationTracking();
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
      if (initialPos == null || (initialPos.latitude == 0.0 && initialPos.longitude == 0.0)) {
        try {
          initialPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          );
        } catch (_) {}
      }
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
        onError: (_) {},
      );
    } catch (_) {}
  }

  /// Update location data from a GPS position
  /// Only sets delivery address if user hasn't manually chosen one
  Future<void> _updateLocation(Position position) async {
    try {
      if (Auth2.user == null) return;

      final lat = position.latitude.toString();
      final lng = position.longitude.toString();

      // Update user coordinates locally (for distance calculations)
      Auth2.user!.lat = lat;
      Auth2.user!.long = lng;
    } catch (_) {}
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

// myColor, myColor2, navigatorKey, globalUrl are all defined in main.dart
