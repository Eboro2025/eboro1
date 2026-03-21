import 'package:eboro/API/Auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart'  as MapToolkit;

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:convert';

import 'address_result.dart';
class MapScreen extends StatefulWidget {
  final Widget pinWidget;
  final String apiKey;
  final LatLng? initialLocation;
  final LatLng? myLocation;
  final String appBarTitle;
  final String searchHint;
  final String addressTitle;
  final String confirmButtonText;
  final String language;
  final List<MapToolkit.LatLng>? polygonPoints;
  final String country;
  final String addressPlaceHolder;
  final Color confirmButtonColor;
  final Color pinColor;
  final Color confirmButtonTextColor;
  const MapScreen(
      {Key? key,
        required this.apiKey,
        required this.appBarTitle,
        this.polygonPoints,
        required this.searchHint,
        required this.addressTitle,
        required this.confirmButtonText,
        required this.language,
        this.country="",
        required this.confirmButtonColor,
        required this.pinColor,
        required this.confirmButtonTextColor,
        required this.addressPlaceHolder, required this.pinWidget,
        required this.initialLocation,
        this.myLocation
      })
      : super(key: key);
  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  bool loading = false;
  String _currentAddress ="";
  LatLng? _latLng;
  String _shortName = "";
  CameraPosition? _kGooglePlex;

  // Inline search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _searchResults = [];
  bool _showSearchResults = false;
  Timer? _searchDebounce;
  var _searchSessionToken;
  final _uuid = Uuid();



  CameraPosition cameraPosition(LatLng target) => CameraPosition(
      bearing: 192.8334901395799,
      target: target,
      tilt: 59.440717697143555,
      zoom: 15);

  IsUserInArea(latitude,longitude){
    MapToolkit.LatLng point = MapToolkit.LatLng(latitude, longitude);
    bool geodesic = true;
    bool checkIfUserInArea = MapToolkit.PolygonUtil.containsLocation(point, widget.polygonPoints ?? [], geodesic);
    return checkIfUserInArea;

  }

  getAddress(LatLng? location) async {
    try {
      final endpoint =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location?.latitude},${location?.longitude}'
          '&key=${widget.apiKey}&language=${widget.language}';

      final response = jsonDecode((await http.get(
        Uri.parse(endpoint),
      ))
          .body);
      if (!mounted) return;
      setState(() {
        _currentAddress = response['results'][0]['formatted_address'];

        // البحث عن اسم الشارع والرقم بالنوع بدل index ثابت
        final components = response['results'][0]['address_components'] as List;
        String street = '';
        String number = '';
        for (var comp in components) {
          final types = (comp['types'] as List?) ?? [];
          if (types.contains('route')) {
            street = comp['long_name'] ?? '';
          } else if (types.contains('street_number')) {
            number = comp['long_name'] ?? '';
          }
        }
        _shortName = number.isNotEmpty ? '$street, $number' : street;
      });
    } catch (_) {}

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    _latLng = widget.myLocation;
    if(widget.myLocation != null)
    {
      _kGooglePlex= CameraPosition(
        target:widget.myLocation!,
        zoom: 15,
      );
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchSessionToken == null) {
      _searchSessionToken = _uuid.v4();
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_searchController.text.isNotEmpty) {
        _getSearchSuggestions(_searchController.text);
      } else {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
        });
      }
    });
  }

  void _getSearchSuggestions(String input) async {
    String url = 'https://places.googleapis.com/v1/places:autocomplete';
    Map<String, dynamic> body = {
      'input': input,
      'languageCode': widget.language,
    };
    if (widget.country.isNotEmpty) {
      body['includedRegionCodes'] = [widget.country];
    }
    if (_latLng != null) {
      body['locationBias'] = {
        'circle': {
          'center': {'latitude': _latLng!.latitude, 'longitude': _latLng!.longitude},
          'radius': 800000.0,
        }
      };
    }
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'X-Goog-Api-Key': widget.apiKey},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = (data['suggestions'] as List?)
                ?.where((s) => s['placePrediction'] != null)
                .map((s) => s['placePrediction'])
                .toList() ?? [];
            _showSearchResults = _searchResults.isNotEmpty;
          });
        }
      } else {
        if (mounted) _getSearchSuggestionsFallback(input);
      }
    } catch (e) {
      if (mounted) _getSearchSuggestionsFallback(input);
    }
  }

  void _getSearchSuggestionsFallback(String input) async {
    String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request = '$baseURL?input=$input&key=${widget.apiKey}&sessiontoken=$_searchSessionToken&language=${widget.language}';
    if (widget.country.isNotEmpty) {
      request += '&components=country:${widget.country}';
    }
    if (_latLng != null) {
      request += '&location=${_latLng!.latitude},${_latLng!.longitude}&radius=800000';
    }
    try {
      var response = await http.get(Uri.parse(request));
      if (response.statusCode == 200 && mounted) {
        var data = json.decode(response.body);
        setState(() {
          _searchResults = (data['predictions'] as List?)?.map((p) => {
            'placeId': p['place_id'],
            'text': {'text': p['description']},
            'structuredFormat': {
              'mainText': {'text': p['structured_formatting']?['main_text'] ?? ''},
              'secondaryText': {'text': p['structured_formatting']?['secondary_text'] ?? ''},
            },
          }).toList() ?? [];
          _showSearchResults = _searchResults.isNotEmpty;
        });
      }
    } catch (e) {
    }
  }

  void _onSearchResultTap(String placeId) async {
    _searchFocusNode.unfocus();
    setState(() {
      _showSearchResults = false;
      _searchController.clear();
    });
    try {
      final location = await getPlace(placeId);
      if (!mounted) return;
      CameraPosition cPosition = CameraPosition(
        zoom: 17,
        target: LatLng(
          double.parse(location['lat'].toString()),
          double.parse(location['lng'].toString()),
        ),
      );
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    } catch (e) {
    }
  }
  @override
  Widget build(BuildContext context) {
    final bool canConfirm = (widget.polygonPoints == null || IsUserInArea(_latLng?.latitude, _latLng?.longitude)) && !loading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // الخريطة - بتاخد الشاشة كلها
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex!,
            myLocationButtonEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            myLocationEnabled: true,
            onCameraMoveStarted: () {
              setState(() {
                loading = true;
              });
            },
            onCameraMove: (p) {
              _latLng = LatLng(p.target.latitude, p.target.longitude);
            },
            onCameraIdle: () async {
              getAddress(_latLng);
            },
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // شريط البحث + زر الرجوع في الأعلى
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // زر الرجوع
                if (Auth2.user?.lat != null && Auth2.user?.long != null)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(),
                    ),
                  ),

                // شريط البحث المباشر
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, size: 22, color: Colors.grey.shade500),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? InkWell(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() { _searchResults = []; _showSearchResults = false; });
                                  _searchFocusNode.unfocus();
                                },
                                child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // نتائج البحث
          if (_showSearchResults)
            Positioned(
              top: MediaQuery.of(context).padding.top + 68,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (ctx, i) {
                    final item = _searchResults[i];
                    final mainText = item['structuredFormat']?['mainText']?['text'] ?? '';
                    final secondaryText = item['structuredFormat']?['secondaryText']?['text'] ?? '';
                    final placeId = item['placeId'] ?? item['place_id'] ?? '';
                    return InkWell(
                      onTap: () => _onSearchResultTap(placeId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: Colors.red.shade400),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mainText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if (secondaryText.isNotEmpty)
                                    Text(secondaryText, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            ),

          // زر الموقع الحالي (GPS)
          Positioned(
            right: 16,
            bottom: 230,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.my_location, color: widget.confirmButtonColor, size: 22),
                onPressed: () async {
                  CameraPosition cPosition = CameraPosition(
                    zoom: 15,
                    target: widget.myLocation!,
                  );
                  final GoogleMapController controller = await _controller.future;
                  controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
                },
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              ),
            ),
          ),

          // Pin في النص - يتحرك لفوق لما تسحب الخريطة
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.12,
            child: IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: loading ? -25.0 : 0.0),
                      duration: const Duration(milliseconds: 300),
                      curve: loading ? Curves.easeOut : Curves.bounceOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, value),
                          child: child,
                        );
                      },
                      child: Icon(Icons.location_pin, color: widget.pinColor, size: 55),
                    ),
                    // ظل
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: loading ? 12 : 6,
                      height: loading ? 6 : 3,
                      decoration: BoxDecoration(
                        color: loading ? Colors.black45 : Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // البطاقة السفلية - العنوان + زر التأكيد
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          height: 4,
                          width: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // عنوان + أيقونة
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.confirmButtonColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: widget.confirmButtonColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Loading indicator أو اسم الشارع
                                loading
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: widget.confirmButtonColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ricerca indirizzo...',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _shortName.isNotEmpty ? _shortName : widget.addressPlaceHolder,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentAddress.isEmpty ? widget.addressPlaceHolder : _currentAddress,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // زر التأكيد
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: canConfirm
                            ? () {
                                AddressResult addressResult = AddressResult(latlng: _latLng!, address: _currentAddress);
                                Navigator.pop(context, addressResult);
                              }
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.confirmButtonColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            foregroundColor: widget.confirmButtonTextColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.confirmButtonText,
                                style: TextStyle(
                                  color: widget.confirmButtonTextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  getPlace(placeId) async {

    String baseURL = 'https://maps.googleapis.com/maps/api/place/details/json';
    String request =
        '$baseURL?place_id=$placeId&key=${widget.apiKey}&language=${widget.language}';
    var response = await http.get(Uri.parse(request));

    if (response.statusCode == 200) {
      var res = json.decode(response.body);
      return res['result']['geometry']['location'];
    } else {
      throw Exception('Failed to load predictions');
    }
  }
}

class SearchPage extends StatefulWidget {
  final String language;
  final String apiKey;
  final String searchPlaceHolder;
  final String country;
  final LatLng? location;
  const SearchPage({Key? key, required this.language, required this.apiKey, required this.searchPlaceHolder, this.country = "", this.location}) : super(key: key);
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  var uuid = new Uuid();
  var _sessionToken;
  List<dynamic> _placeList = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _onChanged();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  _onChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    // Debounce: انتظر 400ms بعد آخر حرف قبل ما تبعت API call
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_controller.text.isNotEmpty) {
        getSuggestion(_controller.text);
      }
    });
  }



  void getSuggestion(String input) async {
    // Google Places API (New) - أدق وأحسن من القديم
    String url = 'https://places.googleapis.com/v1/places:autocomplete';

    Map<String, dynamic> body = {
      'input': input,
      'languageCode': widget.language,
    };

    // تحديد البلد
    if (widget.country.isNotEmpty) {
      body['includedRegionCodes'] = [widget.country];
    }

    // تحديد المنطقة القريبة من المستخدم (دائرة 15 كم)
    if (widget.location != null) {
      body['locationBias'] = {
        'circle': {
          'center': {
            'latitude': widget.location!.latitude,
            'longitude': widget.location!.longitude,
          },
          'radius': 15000.0,
        }
      };
    }

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': widget.apiKey,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _placeList = (data['suggestions'] as List?)
              ?.where((s) => s['placePrediction'] != null)
              .map((s) => s['placePrediction'])
              .toList() ?? [];
        });
      } else {
        // لو الـ API الجديد مش مفعل، نرجع للقديم
        _getSuggestionFallback(input);
      }
    } catch (e) {
      _getSuggestionFallback(input);
    }
  }

  /// Fallback للـ API القديم لو الجديد مش شغال
  void _getSuggestionFallback(String input) async {
    String baseURL =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request =
        '$baseURL?input=$input&key=${widget.apiKey}&sessiontoken=$_sessionToken&language=${widget.language}';

    if (widget.country.isNotEmpty) {
      request += '&components=country:${widget.country}';
    }
    if (widget.location != null) {
      request += '&location=${widget.location!.latitude},${widget.location!.longitude}&radius=15000&strictbounds=true';
    }
    request += '&types=geocode';

    var response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      // تحويل النتائج القديمة لنفس شكل الجديد
      setState(() {
        _placeList = (data['predictions'] as List?)?.map((p) => {
          'placeId': p['place_id'],
          'text': {'text': p['description']},
          'structuredFormat': {
            'mainText': {'text': p['structured_formatting']?['main_text'] ?? ''},
            'secondaryText': {'text': p['structured_formatting']?['secondary_text'] ?? ''},
          },
        }).toList() ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.searchPlaceHolder,
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : InkWell(
                      onTap: () {
                        _controller.clear();
                        setState(() { _placeList.clear(); });
                      },
                      child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                    ),
              filled: true,
              fillColor: const Color(0xFFF0F1F3),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      body: _placeList.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    widget.searchPlaceHolder,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _placeList.length,
              itemBuilder: (ctx, i) {
                final item = _placeList[i];
                final mainText = item['structuredFormat']?['mainText']?['text'] ?? '';
                final secondaryText = item['structuredFormat']?['secondaryText']?['text'] ?? '';
                final placeId = item['placeId'] ?? item['place_id'] ?? '';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context, placeId);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on, size: 18, color: Colors.red),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mainText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (secondaryText.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      secondaryText,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.north_west, size: 16, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

showGoogleMapLocationPicker(
    {
      required BuildContext context,
      required Widget pinWidget,
      required String apiKey,
      List<MapToolkit.LatLng>? polygonPoints,
      required String appBarTitle,
      required String searchHint,
      required String addressTitle,
      LatLng? initialLocation,
      LatLng? myLocation,
      required String confirmButtonText,
      required String language,
      required String country,
      required String addressPlaceHolder,
      required Color confirmButtonColor,
      required Color pinColor,
      required Color confirmButtonTextColor
    }) async {

  final pickedLocation = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) =>  MapScreen(apiKey: apiKey,pinWidget: pinWidget, appBarTitle: appBarTitle, searchHint: searchHint,polygonPoints:polygonPoints, addressTitle: addressTitle, confirmButtonText: confirmButtonText, language: language, confirmButtonColor: confirmButtonColor, pinColor: pinColor, confirmButtonTextColor: confirmButtonTextColor, addressPlaceHolder: addressPlaceHolder, initialLocation: initialLocation, myLocation: myLocation)),
  );
  return pickedLocation;

}

