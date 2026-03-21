import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eboro/main.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Provider.dart';

import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/Helper/UserData.dart';
import 'package:eboro/Widget/Providers.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/Client/Addresses.dart';
import 'package:eboro/Client/MyCart.dart';
import 'package:eboro/Client/MyOrders.dart';

// Location
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:eboro/package/lib/google_map_location_picker_flutter.dart';
import 'package:eboro/Widget/Progress.dart';

// Audio Player for notifications
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';

class AllProviders extends StatefulWidget {
  final String? catID;
  final String? name;

  const AllProviders({
    Key? key,
    required this.catID,
    required this.name,
  }) : super(key: key);

  @override
  AllProvidersState createState() => AllProvidersState();
}

class AllProvidersState extends State<AllProviders> {
  String? _selectedCategoryName;
  String? _selectedCategoryIdStr;


  // Filters
  double _maxDistance = 50.0; // km
  RangeValues _priceRange = RangeValues(0, 100); // euro
  double _maxDeliveryFee = 10.0; // euro
  String _sortBy = 'distance'; // distance, price, rating

  // GPS cached state (pre-fetched in initState)
  String _gpsAddress = "";
  Position? _cachedGpsPosition;

  // Audio player for notifications
  final AudioPlayer _notificationPlayer = AudioPlayer();

  // Pulsing animation removed — was causing 60 rebuilds/sec across all pages

  @override
  void initState() {
    super.initState();

    // Show location picker only if no delivery address is saved
    final addr = UserData.deliveryAddress;
    if (addr == null || addr.isEmpty) {
      // Pre-fetch GPS position for bottom sheet + auto-detect location
      _prefetchGpsPosition();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _autoDetectAndConfirmLocation();
        }
      });
    }

    Future.microtask(() async {
      if (!mounted) return;

      try {
        final provider =
            Provider.of<ProviderController>(context, listen: false);

        if (widget.catID != null) {
          final catIdStr = widget.catID!.toString();
          final catNameStr = widget.name?.toString() ?? "";

          _selectedCategoryIdStr = catIdStr;
          _selectedCategoryName = catNameStr;

          // Load cache first for instant display
          await provider.loadFromCache();
          if (mounted) provider.precacheProviderImages(context);

          // Update from API in background
          await Future.wait<void>([
            Provider2.showFilter(catIdStr, catNameStr, context).then((_) {}),
            provider.Providers(catIdStr, context).then((_) {}),
          ]);
        } else {
          // catID == null: guest mode or already loaded in go()
          // Always fetch live from API for a real experience
          Provider2.clearProvidersCache();
          await provider.updateProvider(null, force: true);
        }
        // Pre-cache images
        if (mounted) provider.precacheProviderImages(context);
      } catch (e) {
      }
    });
  }

  @override
  void dispose() {
    _notificationPlayer.dispose(); // Clean up audio player
    super.dispose();
  }

  String extractStreetOnly(String fullAddress) {
    try {
      final parts = fullAddress.split(',');
      if (parts.length >= 2) {
        final street = parts[0].trim();
        final number = parts[1].trim();
        return "$street $number";
      }
      return fullAddress;
    } catch (_) {
      return fullAddress;
    }
  }

  String _composeAddressFromPlacemark(Placemark p) {
    final street = (p.street ?? '').trim();
    final houseNumber = (p.subThoroughfare ?? '').trim();
    final cap = (p.postalCode ?? '').trim();
    final city = (p.locality ?? '').trim();

    // Avoid duplicating house number if street already ends with it
    String streetWithNumber = street;
    if (houseNumber.isNotEmpty && !street.endsWith(houseNumber)) {
      streetWithNumber = '$street $houseNumber';
    }

    return [streetWithNumber, cap, city]
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  Future<LatLng> _getCurrentLocation() async {
    Position? pos = await Geolocator.getLastKnownPosition();
    if (pos != null && pos.latitude != 0.0 && pos.longitude != 0.0) {
      return LatLng(pos.latitude, pos.longitude);
    }
    pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 8),
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  /// Pre-fetch GPS position in initState so it's ready for bottom sheet only
  /// Never changes the user's address - the user must choose themselves
  void _prefetchGpsPosition() async {
    try {
      // Verify GPS permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() {});
        return;
      }

      // First: get last known position instantly
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && _cachedGpsPosition == null) {
        _cachedGpsPosition = lastPos;
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            lastPos.latitude, lastPos.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            _gpsAddress = _composeAddressFromPlacemark(p);
          }
        } catch (_) {}
      }

      // Stop loading immediately so the UI doesn't show the spinner
      if (mounted) setState(() {});

      // Second: get accurate position in background (non-blocking)
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        );
        _cachedGpsPosition = pos;
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            pos.latitude, pos.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            _gpsAddress = _composeAddressFromPlacemark(p);
            if (mounted) setState(() {});
          }
        } catch (_) {}
      } catch (_) {}
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  // ===================== ADDRESS HISTORY =====================
  static const int _maxHistoryItems = 4;

  /// Key per user account
  String get _addressHistoryKey {
    final userId = Auth2.user?.id?.toString() ?? 'guest';
    return 'address_history_$userId';
  }

  /// Load saved address history from SharedPreferences
  List<Map<String, String>> _loadAddressHistory() {
    final jsonStr = MyApp2.prefs.getString(_addressHistoryKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final history = list.cast<Map<String, dynamic>>().map((e) =>
        e.map((k, v) => MapEntry(k, v.toString()))
      ).toList();

      final cleanedHistory = history.map((item) {
        // Fix duplicated house numbers (e.g. "Via X 4 4 20159" → "Via X 4, 20159")
        var addr = item['address'] ?? '';
        addr = addr.replaceAllMapped(
          RegExp(r'(\d+)\s+\1(?=\s|,|$)'),
          (m) => m.group(1)!,
        );
        // Fix duplicated "N XX" patterns (e.g. "4 N 04 4 N 04" → "4 N 04")
        addr = addr.replaceAllMapped(
          RegExp(r'(.+?N\s*\d+)\s+\1'),
          (m) => m.group(1)!,
        );
        return {...item, 'address': addr};
      }).where((item) {
        final address = (item['address'] ?? '').trim().toLowerCase();
        if (address.isEmpty) return false;
        if (address.contains('via lario')) return false;
        if (address == 'posizione corrente') return false;
        if (address == 'la tua posizione') return false;
        if (address == 'current location') return false;
        return true;
      }).toList();

      if (cleanedHistory.length != history.length) {
        MyApp2.prefs.setString(_addressHistoryKey, jsonEncode(cleanedHistory));
      }

      return cleanedHistory;
    } catch (_) {
      return [];
    }
  }

  /// Save an address to history (most recent first, max 4)
  void _saveToAddressHistory(String address, String lat, String lng) {
    if (address.isEmpty) return;
    final history = _loadAddressHistory();
    // Remove duplicate (same address text)
    history.removeWhere((h) => h['address'] == address);
    // Insert at top
    history.insert(0, {'address': address, 'lat': lat, 'lng': lng});
    // Keep max items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    MyApp2.prefs.setString(_addressHistoryKey, jsonEncode(history));
  }

  /// Select a saved address from history
  Future<void> _selectSavedAddress(Map<String, String> addr) async {
    Progress.progressDialogue(context);
    try {
      UserData.deliveryAddress = addr['address'];
      UserData.deliveryLat = addr['lat'];
      UserData.deliveryLong = addr['lng'];
      UserData.saveDeliveryAddress();

      // Update coordinates on server for distance/shipping calculation
      await Auth2.updateDeliveryCoordinates(addr['lat']!, addr['lng']!, context);
      if (!mounted) return;
      Progress.dimesDialog(context);

      // Clear house/intercom
      Auth2.user?.house = "";
      Auth2.user?.intercom = "";
      final mobile = Auth2.user?.mobile ?? "";
      Auth2.editUserlocationsHints(mobile, "", "", context,
          whatsapp: Auth2.user?.whatsapp ?? "", navigate: false,
          showProgress: false, popOnDone: false);

      // Clear cart (fire and forget - don't block UI)
      final cart = Provider.of<CartTextProvider>(context, listen: false);
      cart.clearCartSilent();

      Provider2.clearProvidersCache();
      final provider = Provider.of<ProviderController>(context, listen: false);
      await provider.clearDeliveryCache();
      await provider.updateProvider(_selectedCategoryIdStr, force: true);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) Progress.dimesDialog(context);
    }
  }

  Future<void> _openLocationPicker() async {
    if (!mounted) return;
    try {
      // Try to get permission but don't block if denied
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      } catch (_) {}

      if (!mounted) return;

      // Get position with fallback - always open the map even without GPS
      LatLng myPosition;
      try {
        myPosition = await _getCurrentLocation();
      } catch (_) {
        // Fallback: use saved user location or default to Milan
        myPosition = LatLng(
          double.tryParse(Auth2.user?.activeLat ?? Auth2.user?.lat ?? '') ?? 45.4642,
          double.tryParse(Auth2.user?.activeLong ?? Auth2.user?.long ?? '') ?? 9.1900,
        );
      }

      if (!mounted) return;

      final result = await showGoogleMapLocationPicker(
        pinWidget: Icon(Icons.location_pin, color: myColor, size: 50),
        pinColor: myColor,
        context: context,
        addressPlaceHolder: "Seleziona qui",
        addressTitle: "Indirizzo : ",
        apiKey: "AIzaSyAB9JpHw1iVlBH3izJJfsuPGKOqxLsXSpk",
        appBarTitle: "Indirizzo di consegna",
        confirmButtonColor: myColor,
        confirmButtonText: "Salva",
        confirmButtonTextColor: Colors.white,
        country: "it",
        language: MyApp2.apiLang.toString(),
        searchHint: "Cerca",
        initialLocation: myPosition,
        myLocation: myPosition,
      );

      if (result == null || !mounted) return;

      // Check if address actually changed
      final oldAddress = UserData.deliveryAddress ?? '';
      final addressChanged = oldAddress != result.address;

      setState(() {
        UserData.deliveryAddress = result.address;
        UserData.deliveryLat = result.latlng.latitude.toString();
        UserData.deliveryLong = result.latlng.longitude.toString();
      });
      UserData.saveDeliveryAddress();

      // Save to address history
      _saveToAddressHistory(
        result.address,
        result.latlng.latitude.toString(),
        result.latlng.longitude.toString(),
      );

      // Only clear house/intercom and cart when address actually changed
      if (addressChanged) {
        Auth2.user?.house = "";
        Auth2.user?.intercom = "";
        final mobile = Auth2.user?.mobile ?? "";
        Auth2.editUserlocationsHints(mobile, "", "", context,
            whatsapp: Auth2.user?.whatsapp ?? "", navigate: false,
            showProgress: false, popOnDone: false);

        final cartProvider = Provider.of<CartTextProvider>(context, listen: false);
        cartProvider.clearCartSilent();
      }

      // Update server coordinates and reload providers in parallel
      Provider2.clearProvidersCache();
      final provider = Provider.of<ProviderController>(context, listen: false);
      await provider.clearDeliveryCache();
      await Future.wait<dynamic>([
        Auth2.updateDeliveryCoordinates(
          result.latlng.latitude.toString(),
          result.latlng.longitude.toString(),
          context,
        ),
        provider.updateProvider(_selectedCategoryIdStr, force: true),
      ]);

      if (!mounted) return;

      // Show AddAddress only on first time or when address changed
      if (addressChanged && Auth2.user?.email != "info@eboro.com") {
        final houseEmpty =
            Auth2.user?.house == null || (Auth2.user?.house?.isEmpty ?? true);
        final mobileEmpty =
            Auth2.user?.mobile == null || (Auth2.user?.mobile?.isEmpty ?? true);

        if (houseEmpty || mobileEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddAddress()),
          );
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      // Prevent crash - silently handle
    }
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Filtri",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _maxDistance = 50.0;
                                _priceRange = RangeValues(0, 100);
                                _maxDeliveryFee = 10.0;
                                _sortBy = 'distance';
                              });
                              // Reset all restaurants
                              final provider = Provider.of<ProviderController>(context, listen: false);
                              provider.filteredProviders = List.from(provider.providers ?? []);
                              setState(() {});
                            },
                            child: Text(
                              "Ripristina",
                              style: TextStyle(color: myColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Distanza massima
                            Text(
                              "Distanza massima",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _maxDistance,
                                    min: 1,
                                    max: 50,
                                    divisions: 49,
                                    activeColor: myColor,
                                    label: '${_maxDistance.round()} km',
                                    onChanged: (value) {
                                      setModalState(() {
                                        _maxDistance = value;
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: myColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_maxDistance.round()} km',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: myColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Fascia di prezzo
                            Text(
                              "Fascia di prezzo",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RangeSlider(
                              values: _priceRange,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: myColor,
                              labels: RangeLabels(
                                '€${_priceRange.start.round()}',
                                '€${_priceRange.end.round()}',
                              ),
                              onChanged: (values) {
                                setModalState(() {
                                  _priceRange = values;
                                });
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('€${_priceRange.start.round()}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                  Text('€${_priceRange.end.round()}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Costo di consegna massimo
                            Text(
                              "Costo di consegna massimo",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _maxDeliveryFee,
                                    min: 0,
                                    max: 10,
                                    divisions: 20,
                                    activeColor: myColor,
                                    label:
                                        '€${_maxDeliveryFee.toStringAsFixed(1)}',
                                    onChanged: (value) {
                                      setModalState(() {
                                        _maxDeliveryFee = value;
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: myColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '€${_maxDeliveryFee.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: myColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Ordina per
                            Text(
                              "Ordina per",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildSortChip(
                                  'Distanza',
                                  'distance',
                                  Icons.near_me,
                                  setModalState,
                                ),
                                _buildSortChip(
                                  'Prezzo',
                                  'price',
                                  Icons.euro,
                                  setModalState,
                                ),
                                _buildSortChip(
                                  'Valutazione',
                                  'rating',
                                  Icons.star,
                                  setModalState,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Annulla",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _applyBottomSheetFilters();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: myColor,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "Applica",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(
      String label, String value, IconData icon, StateSetter setModalState) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600),
          SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _sortBy = value;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: myColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  void _applyBottomSheetFilters() {
    final provider = Provider.of<ProviderController>(context, listen: false);
    final allProviders = provider.providers ?? [];

    List<ProviderData> filtered = allProviders.where((p) {
      // Distance filter
      final distance = double.tryParse(p.Delivery?.Distance ?? '') ?? 0.0;
      if (distance > 0 && distance > _maxDistance) return false;

      // Delivery fee filter
      final deliveryFee = double.tryParse(p.Delivery?.shipping ?? '') ?? 0.0;
      if (deliveryFee > _maxDeliveryFee) return false;

      return true;
    }).toList();

    // Sort by selected option — closed stores always at the end
    filtered.sort((a, b) {
      final aOpen = a.state == '1' ? 0 : 1;
      final bOpen = b.state == '1' ? 0 : 1;
      if (aOpen != bOpen) return aOpen.compareTo(bOpen);

      switch (_sortBy) {
        case 'distance':
          final dA = double.tryParse(a.Delivery?.Distance ?? '') ?? 999;
          final dB = double.tryParse(b.Delivery?.Distance ?? '') ?? 999;
          return dA.compareTo(dB);
        case 'price':
          final pA = double.tryParse(a.Delivery?.shipping ?? '') ?? 999;
          final pB = double.tryParse(b.Delivery?.shipping ?? '') ?? 999;
          return pA.compareTo(pB);
        case 'rating':
          final rA = double.tryParse(a.rateRatio ?? '0') ?? 0;
          final rB = double.tryParse(b.rateRatio ?? '0') ?? 0;
          return rB.compareTo(rA);
        default:
          return 0;
      }
    });

    provider.filteredProviders = filtered;
    setState(() {});
  }

  Future<void> _autoDetectAndConfirmLocation() async {
    try {
      // Try GPS, fallback to default Milan location
      Position? position;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        try {
          final lastPos = await Geolocator.getLastKnownPosition();
          if (lastPos != null && lastPos.latitude != 0.0 && lastPos.longitude != 0.0) {
            position = lastPos;
          } else {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 10),
            );
          }
        } catch (_) {}
      }

      // Default to Milan if GPS unavailable
      final double lat = position?.latitude ?? 45.4642;
      final double lng = position?.longitude ?? 9.1900;

      if (!mounted) return;

      // Reverse geocode to get address
      String address = '';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          address = _composeAddressFromPlacemark(placemarks.first);
        }
      } catch (_) {}

      if (address.isEmpty) {
        address = '$lat, $lng';
      }

      if (!mounted) return;

      final latStr = lat.toString();
      final lngStr = lng.toString();

      // Save the auto-detected address
      UserData.deliveryAddress = address;
      UserData.deliveryLat = latStr;
      UserData.deliveryLong = lngStr;
      UserData.saveDeliveryAddress();

      Auth2.user?.lat = latStr;
      Auth2.user?.long = lngStr;
      _gpsAddress = address;

      _saveToAddressHistory(address, latStr, lngStr);

      // Update server coordinates and reload providers with new location
      Auth2.updateDeliveryCoordinates(latStr, lngStr, context);

      if (mounted) {
        setState(() {});
        // Reload providers now that we have a location
        final provider = Provider.of<ProviderController>(context, listen: false);
        provider.updateProvider(_selectedCategoryIdStr, force: true);
      }
    } catch (e) {
      // GPS failed - just refresh UI, user can tap location to change
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showLocationOptions() {
    final addressHistory = _loadAddressHistory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      "Consegna a...",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E3333),
                      ),
                    ),
                  ),

                  // Search option
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _openLocationPicker();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: myColor, size: 24),
                          const SizedBox(width: 16),
                          Text("Cerca",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: myColor)),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),

                  // GPS location option
                  InkWell(
                    onTap: () async {
                            // GPS location tapped
                            Navigator.pop(ctx);
                            // Check GPS permission first
                            try {
                              var permission = await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission = await Geolocator.requestPermission();
                              }
                              if (permission == LocationPermission.deniedForever) {
                                if (!mounted) return;
                                // Show dialog to open settings
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Permesso posizione'),
                                    content: const Text('Per usare la tua posizione, abilita il permesso nelle impostazioni.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
                                      TextButton(
                                        onPressed: () { Navigator.pop(ctx); Geolocator.openAppSettings(); },
                                        child: const Text('Apri Impostazioni'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              if (permission == LocationPermission.denied) return;
                            } catch (_) {}
                            if (!mounted) return;
                            Progress.progressDialogue(context);
                            try {
                              // Always fetch a fresh GPS position when user taps current location
                              Position pos = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.medium,
                              ).timeout(const Duration(seconds: 10));
                              _cachedGpsPosition = pos;

                              Auth2.user?.lat = pos.latitude.toString();
                              Auth2.user?.long = pos.longitude.toString();

                              // Resolve address from current coordinates every time
                              String resolvedAddress = "";
                              try {
                                List<Placemark> placemarks =
                                    await placemarkFromCoordinates(
                                  pos.latitude,
                                  pos.longitude,
                                );
                                if (placemarks.isNotEmpty) {
                                  final p = placemarks.first;
                                  resolvedAddress =
                                      _composeAddressFromPlacemark(p);
                                }
                              } catch (_) {}

                              if (resolvedAddress
                                  .replaceAll(',', '')
                                  .trim()
                                  .isEmpty) {
                                resolvedAddress =
                                    "Lat ${pos.latitude.toStringAsFixed(6)}, Lng ${pos.longitude.toStringAsFixed(6)}";
                              }

                              _gpsAddress = resolvedAddress;
                              UserData.deliveryAddress = resolvedAddress;
                              UserData.deliveryLat = pos.latitude.toString();
                              UserData.deliveryLong = pos.longitude.toString();

                              _saveToAddressHistory(
                                resolvedAddress,
                                pos.latitude.toString(),
                                pos.longitude.toString(),
                              );
                              // Clear house/intercom
                              Auth2.user?.house = "";
                              Auth2.user?.intercom = "";
                              final mobile = Auth2.user?.mobile ?? "";
                              Auth2.editUserlocationsHints(mobile, "", "", context,
                                  whatsapp: Auth2.user?.whatsapp ?? "", navigate: false,
                                  showProgress: false, popOnDone: false);

                              // Update coordinates on server for distance/shipping
                              await Auth2.updateDeliveryCoordinates(
                                pos.latitude.toString(), pos.longitude.toString(), context);
                              if (!mounted) return;
                              Progress.dimesDialog(context);

                              // Clear cart (fire and forget - don't block UI)
                              final cartProv = Provider.of<CartTextProvider>(context, listen: false);
                              cartProv.clearCartSilent();
                              Provider2.clearProvidersCache();
                              final provider = Provider.of<ProviderController>(context, listen: false);
                              await provider.clearDeliveryCache();
                              await provider.updateProvider(_selectedCategoryIdStr, force: true);
                              if (mounted) setState(() {});
                            } catch (_) {
                              if (mounted) Progress.dimesDialog(context);
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_outlined, color: Color(0xFF2E3333), size: 24),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text("La tua posizione",
                              style: TextStyle(fontSize: 16, color: Color(0xFF2E3333))),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent addresses section
                  if (addressHistory.isNotEmpty) ...[
                    Divider(height: 1, color: Colors.grey.shade200),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Text(
                        "Ricerche recenti",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: addressHistory.length,
                        itemBuilder: (context, index) {
                          final addr = addressHistory[index];
                          final fullAddr = addr['address'] ?? '';
                          final shortAddr = extractStreetOnly(fullAddr);
                          // Get city from full address
                          final parts = fullAddr.split(',');
                          final city = parts.length >= 3 ? parts[2].trim() : '';

                          return InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              _selectSavedAddress(addr);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.grey.shade400, size: 20),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shortAddr,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF2E3333),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (city.isNotEmpty)
                                          Text(
                                            city,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================= BUILD ==============================

  bool get _hasDeliveryLocation {
    final addr = UserData.deliveryAddress;
    return addr != null && addr.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final fullAddress = Auth2.user?.activeAddress ?? "Select location";
    final shortAddress = extractStreetOnly(fullAddress);

    // No location → show providers with location picker (no loading spinner)
    if (!_hasDeliveryLocation) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Providers(onSelectLocation: _showLocationOptions),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF5F6FA), // Grigio chiaro invece del bianco scuro

        // Cart button hidden on AllProviders page
        floatingActionButton: null,

        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F6FA),
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.black87),
          toolbarHeight: 48,
          titleSpacing: 16,
          title: GestureDetector(
            onTap: _showLocationOptions,
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: myColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shortAddress,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: MyApp2.fontSize14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
          actions: [
            // Cart indicator - shown when there are items in the cart
            Consumer<CartTextProvider>(
              builder: (context, cart, child) {
                final hasItems = cart.cart?.cart_items != null &&
                    cart.cart!.cart_items!.isNotEmpty;
                final itemCount = cart.cart?.cart_items?.fold<int>(0, (sum, item) => sum + (item.qty ?? 0)) ?? 0;

                if (hasItems) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyCart()),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: myColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: myColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$itemCount',
                              style: TextStyle(
                                color: myColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // If cart is empty, show the notification icon with active orders badge
                return Consumer<UserOrderProvider>(
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

                    return IconButton(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: Colors.black87,
                            size: 26,
                          ),
                          if (activeCount > 0)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC12732),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  activeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () {
                        if (activeCount > 0) {
                          // فيه طلبات نشطة → روح لصفحة الطلبات
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyOrders()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nessuna notifica'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
            SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Cerca ristoranti...",
                        style: TextStyle(
                          fontSize: MyApp2.fontSize14,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // GestureDetector(
                    //   onTap: _showFiltersBottomSheet,
                    //   child: Icon(Icons.tune, size: 20, color: myColor),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lista ristoranti
            Expanded(
              child: Providers(onSelectLocation: _showLocationOptions),
            ),
          ],
        ),
      ),
    );
  }
}
