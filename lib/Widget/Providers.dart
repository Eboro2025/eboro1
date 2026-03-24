import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:eboro/Providers/ClickProvider.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/Helper/OfferData.dart';
import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../API/Auth.dart';
import '../RealTime/Provider/CartTextProvider.dart';
import '../RealTime/Provider/ProductCacheProvider.dart';
import '../main.dart' show globalUrl;
import 'package:eboro/Widget/BannerSlider.dart';
import 'package:eboro/Widget/ProviderCard.dart';
import 'package:eboro/Widget/HorizontalProviderCard.dart';
import 'package:eboro/Widget/DailySpecialCard.dart';
import 'package:eboro/Widget/SkeletonLoading.dart';
import 'package:eboro/API/PremiumApi.dart';
import 'package:eboro/API/DailySpecialApi.dart';
import 'package:eboro/API/Offer.dart';
import 'package:eboro/Helper/DailySpecialData.dart';

class Providers extends StatefulWidget {
  final VoidCallback? onSelectLocation;
  Providers({Key? key, this.onSelectLocation}) : super(key: key);

  @override
  Providers2 createState() => Providers2();
}

class Providers2 extends State<Providers> {
  Timer? _timer;
  bool _didTriggerLocationPicker = false;

  int selectedTypeFilter = 0; // Types row: 0=All, 1+=Types
  int selectedFilter = 0; // Offers row: 0=Tutti, 1=Free delivery, etc.
  String _selectedFilterKey = ''; // Track which filter key is active
  bool isLoadingFilter = false;
  bool isLoadingTypeFilter = false;

  bool _updating = false; // prevent overlapping API refresh

  // Premium provider IDs from API
  List<int> _premiumProviderIds = [];

  // Daily special provider IDs from API
  List<int> _dailySpecialProviderIds = [];

  // ScrollController for auto-scroll to banner section
  final ScrollController _scrollController = ScrollController();
  // Key for banner section to get its position
  final GlobalKey _bannerSectionKey = GlobalKey();
  // Track if we already scrolled to banner section
  bool _didScrollToBanner = false;
  int _lastBannerProvidersCount = 0;

  // Cache "Scelti per te" to avoid shuffle on every rebuild
  List<ProviderData>? _cachedChosenForYou;
  int _lastProviderListLength = -1;

  // Cache for filtered lists to avoid recalculation on every rebuild
  List<ProviderData>? _cachedFilteredList;
  List<ProviderData>? _cachedPremiumList;
  List<ProviderData>? _cachedPopularList;
  List<ProviderData>? _cachedDailySpecialList;
  List<ProviderData>? _cachedOffersList;
  int _lastComputedSourceLength = -1;
  int _lastComputedFilterIndex = -1;
  int _lastComputedDeliveryCount = -1;

  // ✅ Simple in-memory cache for offers results (avoid hitting API repeatedly)
  DateTime? _offersCacheTime;
  final Duration _offersCacheTTL = const Duration(minutes: 2);

  // cache key => (providerIds, providerOffers)
  // keys: free_delivery, two_for_one, active
  final Map<String, Set<int>> _cachedProviderIds = {};
  final Map<String, Map<int, OfferData>> _cachedProviderOffers = {};

  // Auto-banner data: Free Delivery, 2x1, Piatti del Giorno
  List<OfferData> _freeDeliveryOffers = [];
  List<OfferData> _twoForOneOffers = [];
  Set<int> _freeDeliveryBranchIds = {};
  Set<int> _twoForOneBranchIds = {};

  // Daily specials data for banner display
  List<DailySpecialData> _dailySpecials = [];

  // Filter order from server API
  List<String> _filterOrder = [];

  /// Does the user have a valid location?
  bool _userHasValidLocation() {
    final latStr = Auth2.user?.activeLat;
    final longStr = Auth2.user?.activeLong;
    if (latStr == null || longStr == null || latStr.isEmpty || longStr.isEmpty)
      return false;
    final latVal = double.tryParse(latStr) ?? 0.0;
    final longVal = double.tryParse(longStr) ?? 0.0;
    return !(latVal == 0.0 && longVal == 0.0);
  }

  /// Helper method to build offer badge text
  /// Shows: -X% for discount, fs for free delivery, 2×1 for two-for-one, etc.
  String _buildOfferText(OfferData offer) {
    final List<String> parts = [];

    // Check if it's a discount offer
    if (offer.isDiscount) {
      final value = offer.offer_value ?? '25';
      parts.add('-$value%');
    }

    // Check if it's a 2×1 or 1+1 offer
    if (offer.isTwoForOne) {
      if (offer.offer_type == 'one_plus_one') {
        parts.add('1+1');
      } else {
        // Show gift product name if available
        if (offer.hasGiftProduct) {
          parts
              .add('2×1 + ${offer.getGiftProductName(MyApp2.apiLang ?? 'it')}');
        } else {
          parts.add('2×1');
        }
      }
    }

    // Check if free delivery is included
    if (offer.isFreeDelivery) {
      // If it's ONLY free delivery (not combined with 2×1)
      if (offer.offer_type == 'free_delivery') {
        parts.add('fs');
      } else {
        // Combined offer (two_for_one_free_delivery)
        parts.add('fs');
      }
    }

    // If no parts, show generic "Offerta"
    if (parts.isEmpty) {
      return 'Offerta';
    }

    return parts.join(' ');
  }

  void _startTimer([int sec = 120]) {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: sec),
      (Timer t) => _checkInternetStateSafe(),
    );
  }

  @override
  void initState() {
    super.initState();

    // Auto-refresh every 10 seconds
    _startTimer(10);

    // ✅ reset filteredProviders once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<ProviderController>(context, listen: false);
      provider.filteredProviders = provider.providers;
      setState(() {
        selectedFilter = 0;
        _selectedFilterKey = '';
      });
    });

    // Load premium provider IDs with delay to avoid blocking UI
    Future.delayed(const Duration(milliseconds: 500), _loadPremiumProviders);

    // Load daily special provider IDs with delay
    Future.delayed(
        const Duration(milliseconds: 1000), _loadDailySpecialProviders);

    // Load offer data for auto-banners with delay
    Future.delayed(const Duration(milliseconds: 1500), _loadOfferBanners);

    // Load filter order from server with delay
    Future.delayed(const Duration(milliseconds: 2000), _loadFilterOrder);

    // Pre-load products for visible providers in background
    Future.delayed(const Duration(seconds: 3), _preloadProductsForProviders);
  }

  /// Preload products for visible providers (non-blocking)
  void _preloadProductsForProviders() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final providerController =
          Provider.of<ProviderController>(context, listen: false);
      final productCache =
          Provider.of<ProductCacheProvider>(context, listen: false);

      final providers = providerController.filteredProviders ?? [];
      if (providers.isEmpty) return;

      // Preload products for the first 10 providers in the background
      final providersToPreload = providers
          .take(10)
          .where((p) => p.id != null)
          .map((p) => p.id as int)
          .toList();

      if (providersToPreload.isNotEmpty) {
        productCache.preloadProviders(providersToPreload);
      }
    });
  }

  Future<void> _loadPremiumProviders() async {
    try {
      final ids = await PremiumApi.getPremiumProviderIds();
      if (mounted) {
        setState(() {
          _premiumProviderIds = ids;
        });
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Link delivery data from original provider to daily specials + filter out of range
  void _linkDeliveryToDailySpecials(List<ProviderData> sourceList) {
    for (final special in _dailySpecials) {
      if (special.providerId == null) {
        special.outOfDeliveryRange = true;
        continue;
      }
      // Search for the original provider in the providers list
      final provider = sourceList.cast<ProviderData?>().firstWhere(
            (p) => p?.id == special.providerId,
            orElse: () => null,
          );
      if (provider == null) {
        // Provider not found in the list = out of range
        special.outOfDeliveryRange = true;
      } else if (provider.outOfDeliveryRange) {
        // Provider found but out of delivery range
        special.outOfDeliveryRange = true;
      } else if (provider.Delivery != null) {
        // Provider found and has delivery data = show it
        special.delivery = provider.Delivery;
        special.outOfDeliveryRange = false;
      } else {
        // Provider found but delivery data not yet available -> show temporarily
        special.outOfDeliveryRange = false;
      }
    }
  }

  Future<void> _loadDailySpecialProviders() async {
    try {
      final results = await Future.wait([
        DailySpecialApi.getProviderIdsWithSpecials(),
        DailySpecialApi.getTodaySpecials(),
      ]);
      if (mounted) {
        setState(() {
          _dailySpecialProviderIds = results[0] as List<int>;
          _dailySpecials = results[1] as List<DailySpecialData>;
        });
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  Future<void> _loadOfferBanners() async {
    try {
      final results = await Future.wait([
        OfferAPI.getFreeDeliveryOffers(),
        OfferAPI.getTwoForOneOffers(),
      ]);
      if (!mounted) return;
      setState(() {
        _freeDeliveryOffers = results[0] ?? [];
        _twoForOneOffers = results[1] ?? [];
        _freeDeliveryBranchIds = _freeDeliveryOffers
            .where((o) => o.branch_id != null)
            .map((o) => o.branch_id!)
            .toSet();
        _twoForOneBranchIds = _twoForOneOffers
            .where((o) => o.branch_id != null)
            .map((o) => o.branch_id!)
            .toSet();
      });
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  Future<void> _loadFilterOrder() async {
    try {
      final response = await http.get(
        Uri.parse("$globalUrl/api/layout-order"),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] != null &&
            jsonData['data']['filter_order'] != null) {
          final List<dynamic> order = jsonData['data']['filter_order'];
          if (mounted && order.isNotEmpty) {
            setState(() {
              _filterOrder = order.map((e) => e.toString()).toList();
            });
          }
        }
      }
    } catch (e) {
      // Use default order
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkInternetStateSafe() async {
    if (!mounted) return;
    if (_updating) return;
    _updating = true;
    try {
      print('[AUTO-REFRESH] Refreshing providers...');
      final provider = Provider.of<ProviderController>(context, listen: false);
      await provider.updateProvider(provider.categoryId, force: true);
      // Clear cached lists so UI rebuilds with new state
      _cachedFilteredList = null;
      _cachedPremiumList = null;
      _cachedPopularList = null;
      _cachedDailySpecialList = null;
      _cachedOffersList = null;
      _cachedChosenForYou = null;
      _lastComputedSourceLength = -1;
      if (mounted) setState(() {});
      final suzzani = provider.providers?.where((p) => p.id == 88).firstOrNull;
      print('[AUTO-REFRESH] Done. Count: ${provider.providers?.length} | suzzani state: ${suzzani?.state} next: ${suzzani?.nextOpeningTime}');
    } catch (e) {
      if (kDebugMode) {
      }
    } finally {
      _updating = false;
    }
  }

  // Scroll to banner section when it appears
  void _scrollToBannerSection() {
    if (!mounted) return;
    final keyContext = _bannerSectionKey.currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartTextProvider>(context, listen: false);

    return Consumer<ProviderController>(
      builder: (context, provider, child) {
        final sourceList =
            provider.filteredProviders ?? provider.providers ?? [];

        // Show skeleton loading during initial load
        if (sourceList.isEmpty && provider.isLoading) {
          return const SkeletonLoading();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.updateProvider(provider.categoryId, force: true);
          },
          child: _buildContent(provider, cart, sourceList),
        );
      },
    );
  }

  /// Cache "Scelti per te" to avoid shuffle on every rebuild
  List<ProviderData> _getChosenForYou(List<ProviderData> providerList) {
    if (providerList.length != _lastProviderListLength ||
        _cachedChosenForYou == null) {
      _lastProviderListLength = providerList.length;
      _cachedChosenForYou =
          (List<ProviderData>.from(providerList)..shuffle()).take(6).toList();
      // Closed stores go to the end
      _cachedChosenForYou!.sort((a, b) {
        final aOpen = a.state == '1' ? 0 : 1;
        final bOpen = b.state == '1' ? 0 : 1;
        return aOpen.compareTo(bOpen);
      });
    }
    return _cachedChosenForYou!;
  }

  Widget _buildContent(ProviderController provider, CartTextProvider cart,
      List<ProviderData> sourceList) {
    // Count in-range providers (to detect when delivery data arrives and shows new stores)
    final inRangeCount = sourceList
        .where((e) => !e.outOfDeliveryRange)
        .length;

    // Recalculate if provider count, filter, or in-range count changed
    if (_cachedFilteredList == null ||
        _lastComputedSourceLength != sourceList.length ||
        _lastComputedFilterIndex != selectedFilter ||
        _lastComputedDeliveryCount != inRangeCount) {
      _lastComputedSourceLength = sourceList.length;
      _lastComputedFilterIndex = selectedFilter;
      _lastComputedDeliveryCount = inRangeCount;

      // If the user has no location set, show all providers without delivery filtering
      final hasValidLocation = _userHasValidLocation();

      // Filter out closed providers (state=2) first
      final activeList = sourceList.where((e) => e.state != '2').toList();

      if (!hasValidLocation) {
        // No location -> show all providers
        _cachedFilteredList = activeList;
      } else {
        // Has location -> show only in-range providers
        _cachedFilteredList = activeList.where((e) => !e.outOfDeliveryRange).toList();
      }

      _cachedFilteredList!.sort((a, b) {
        // Closed stores (state != '1') always go to the end
        final aOpen = a.state == '1' ? 0 : 1;
        final bOpen = b.state == '1' ? 0 : 1;
        if (aOpen != bOpen) return aOpen.compareTo(bOpen);
        final dA = double.tryParse(a.Delivery?.Distance ?? '') ?? 999.0;
        final dB = double.tryParse(b.Delivery?.Distance ?? '') ?? 999.0;
        return dA.compareTo(dB);
      });

      _cachedPremiumList = _cachedFilteredList!
          .where((e) => e.id != null && _premiumProviderIds.contains(e.id))
          .toList();

      _cachedDailySpecialList = _cachedFilteredList!
          .where((e) => e.id != null && _dailySpecialProviderIds.contains(e.id))
          .toList();

      // Link delivery data from original provider to daily specials
      _linkDeliveryToDailySpecials(sourceList);

      _cachedOffersList =
          _cachedFilteredList!.where((e) => e.offer != null).toList();

      _cachedPopularList = List<ProviderData>.from(_cachedFilteredList!);
      _cachedPopularList!.sort((a, b) {
        // Closed stores always go to the end
        final aOpen = a.state == '1' ? 0 : 1;
        final bOpen = b.state == '1' ? 0 : 1;
        if (aOpen != bOpen) return aOpen.compareTo(bOpen);
        final rateA = double.tryParse(a.rateRatio?.toString() ?? '0') ?? 0;
        final rateB = double.tryParse(b.rateRatio?.toString() ?? '0') ?? 0;
        return rateB.compareTo(rateA);
      });
    }

    final providerList = _cachedFilteredList!;
    final premiumProviders = _cachedPremiumList!;
    final dailySpecialProviders = _cachedDailySpecialList!;
    final offersProviders = _cachedOffersList!;
    final popularProviders = _cachedPopularList!;

    final bool showEmptyAfterFilter =
        _selectedFilterKey.isNotEmpty && providerList.isEmpty;

    // Auto-scroll to banner section when it appears (only once per new banner click)
    final currentCount = provider.bannerProviders?.length ?? 0;
    if (currentCount > 0 && currentCount != _lastBannerProvidersCount) {
      _lastBannerProvidersCount = currentCount;
      _didScrollToBanner = false;
    }
    if (currentCount == 0) {
      _lastBannerProvidersCount = 0;
      _didScrollToBanner = false;
    }
    if (provider.bannerProviders != null &&
        provider.bannerProviders!.isNotEmpty &&
        !_didScrollToBanner) {
      _didScrollToBanner = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBannerSection();
      });
    }

    final bool hasActiveFilter = _selectedFilterKey.isNotEmpty;
    final bool hasLocation = _userHasValidLocation();

    // No location set → skip auto-trigger, let user tap to select location

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // 0) Filter rows (always visible)
        _buildFilterRow(provider),

        // When a filter is active, show its specific content
        if (hasActiveFilter) ...[
          // Piatti del Giorno filter → show daily special dishes
          if (_selectedFilterKey == 'piatto_giorno' &&
              _dailySpecials.isNotEmpty)
            _buildDailySpecialBanner(provider, cart),

          // 2x1 filter → show 2x1 providers with red header
          if (_selectedFilterKey == '2x1') ...[
            _buildTwoForOneSection(providerList, provider, cart),
          ],

          // Free delivery filter → show free delivery banner
          if (_selectedFilterKey == 'consegna_gratis') ...[
            _buildFreeDeliverySection(providerList, provider, cart),
          ],

          // Empty message if filter returns nothing
          if (showEmptyAfterFilter)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline,
                      size: 48, color: Colors.orange),
                  const SizedBox(height: 12),
                  const Text(
                    'Nessun ristorante con questa offerta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Show filtered providers as vertical list
          if (providerList.isNotEmpty) ...[
            // Don't repeat title if daily special banner already shows it
            if (_selectedFilterKey != 'piatto_giorno')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  _getFilterTitle(_selectedFilterKey),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ...providerList.map((eProvider) => ProviderCard(
                  eProvider: eProvider,
                  providerController: provider,
                  cart: cart,
                  buildOfferText: _buildOfferText,
                )),
          ],
        ]
        // No filter active → show all sections
        else ...[
          // 1) Banner slider
          const BannerSlider(),

          // 1.5) Auto-banners for offers
          _buildAutoBanners(
              providerList, dailySpecialProviders, provider, cart),

          // 2) Banner filtered providers section (shows when banner is tapped)
          if (provider.bannerProviders != null &&
              provider.bannerProviders!.isNotEmpty)
            Container(
              key: _bannerSectionKey,
              child: _buildBannerProvidersSection(
                title: provider.bannerTitle ?? "Dal Banner",
                providers: _userHasValidLocation()
                    ? provider.bannerProviders!.where((e) => !e.outOfDeliveryRange).toList()
                    : provider.bannerProviders!,
                providerController: provider,
                cart: cart,
              ),
            ),

          // Section 0: Favorites (I tuoi preferiti)
          if (provider.Favorites != null && provider.Favorites!.isNotEmpty)
            _buildHorizontalSection(
              title: "I tuoi preferiti",
              emoji: "\u2764\uFE0F",
              providers: provider.Favorites!
                  .where((f) => f.provider != null)
                  .map((f) => f.provider!)
                  .where((p) => p.state != '2')
                  .toList()
                ..sort((a, b) {
                  final aOpen = a.state == '1' ? 0 : 1;
                  final bOpen = b.state == '1' ? 0 : 1;
                  return aOpen.compareTo(bOpen);
                }),
              providerController: provider,
              cart: cart,
            ),

          // Section 1: Premium (Paid subscription)
          if (premiumProviders.isNotEmpty)
            _buildHorizontalSection(
              title: "Premium",
              emoji: "\uD83D\uDC8E",
              providers: premiumProviders,
              providerController: provider,
              cart: cart,
            ),

          // Section 2: Il migliore del mese (Best rating)
          if (popularProviders.isNotEmpty)
            _buildHorizontalSection(
              title: "Il migliore del mese",
              emoji: "\uD83C\uDFC6",
              providers: popularProviders.take(6).toList(),
              providerController: provider,
              cart: cart,
            ),

          // Section 3: Le offerte di oggi
          if (offersProviders.isNotEmpty)
            _buildHorizontalSection(
              title: "Le offerte di oggi",
              emoji: "\uD83D\uDD25",
              providers: offersProviders,
              providerController: provider,
              cart: cart,
            ),

          // Section 4: I più popolari
          if (providerList.length > 2)
            _buildHorizontalSection(
              title: "I più popolari",
              emoji: "\u2B50",
              providers: providerList.take(8).toList(),
              providerController: provider,
              cart: cart,
            ),

          // Section 5: Scelti per te
          if (providerList.length > 2)
            _buildHorizontalSection(
              title: "Scelti per te",
              emoji: "\u2764\uFE0F",
              providers: _getChosenForYou(providerList),
              providerController: provider,
              cart: cart,
            ),

          // Section: Tutti i ristoranti (All remaining as vertical list)
          if (providerList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                "Tutti i ristoranti",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ...providerList.map((eProvider) => ProviderCard(
                  eProvider: eProvider,
                  providerController: provider,
                  cart: cart,
                  buildOfferText: _buildOfferText,
                )),
          ],

          // No providers message
          if (providerList.isEmpty && !provider.isLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.storefront_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Nessun ristorante nella tua zona',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prova a cambiare la posizione per trovare ristoranti vicini a te.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  // ------------------ BANNER PROVIDERS SECTION ------------------

  Widget _buildBannerProvidersSection({
    required String title,
    required List<ProviderData> providers,
    required ProviderController providerController,
    required CartTextProvider cart,
  }) {
    if (providers.isEmpty) return const SizedBox.shrink();

    // Header widget (used in both cases)
    Widget headerWidget = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.isNotEmpty ? title : "Dal Banner",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            "${providers.length}",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => providerController.clearBannerFilter(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.black54),
            ),
          ),
        ],
      ),
    );

    // Show all providers as large vertical cards (same style as "Tutti i ristoranti")
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerWidget,
        ...providers.map((eProvider) => ProviderCard(
              eProvider: eProvider,
              providerController: providerController,
              cart: cart,
              buildOfferText: _buildOfferText,
            )),
      ],
    );
  }

  // ------------------ HORIZONTAL SECTION ------------------

  Widget _buildHorizontalSection({
    required String title,
    required String emoji,
    required List<ProviderData> providers,
    required ProviderController providerController,
    required CartTextProvider cart,
  }) {
    if (providers.isEmpty) return const SizedBox.shrink();

    // If only 1 provider, show full vertical card instead of horizontal scroll
    if (providers.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              "$title $emoji",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ProviderCard(
            eProvider: providers.first,
            providerController: providerController,
            cart: cart,
            buildOfferText: _buildOfferText,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            "$title $emoji",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        // Horizontal scroll cards
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final eProvider = providers[index];
              return HorizontalProviderCard(
                eProvider: eProvider,
                providerController: providerController,
                cart: cart,
                buildOfferText: _buildOfferText,
              );
            },
          ),
        ),
      ],
    );
  }

  // ------------------ AUTO-BANNERS ------------------

  Widget _buildAutoBanners(
    List<ProviderData> providerList,
    List<ProviderData> dailySpecialProviders,
    ProviderController providerController,
    CartTextProvider cart,
  ) {
    // Filter providers with free delivery offers
    final freeDeliveryProviders = providerList.where((p) {
      if (p.offer != null && p.offer!.isFreeDelivery) return true;
      if (p.id != null && _freeDeliveryBranchIds.contains(p.id)) return true;
      return false;
    }).toList();

    // Filter providers with 2x1 offers
    final twoForOneProviders = providerList.where((p) {
      if (p.offer != null && p.offer!.isTwoForOne) return true;
      if (p.id != null && _twoForOneBranchIds.contains(p.id)) return true;
      return false;
    }).toList();

    final hasFreeDelivery = freeDeliveryProviders.isNotEmpty;
    final hasTwoForOne = twoForOneProviders.isNotEmpty;
    final hasDailySpecial = dailySpecialProviders.isNotEmpty;

    if (!hasFreeDelivery && !hasTwoForOne && !hasDailySpecial) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Free Delivery section
        if (hasFreeDelivery)
          _buildHorizontalSection(
            title: "Consegna Gratuita",
            emoji: "\uD83D\uDE9A",
            providers: freeDeliveryProviders,
            providerController: providerController,
            cart: cart,
          ),
        // Daily Specials - shows actual dishes
        if (hasDailySpecial && _dailySpecials.isNotEmpty)
          _buildDailySpecialBanner(providerController, cart),
      ],
    );
  }

  Widget _buildDailySpecialBanner(
      ProviderController providerController, CartTextProvider cart) {
    final lang = MyApp2.apiLang ?? 'it';

    // Filter daily specials whose provider is out of delivery range
    // If all are out of range, show them all instead of hiding them
    final hasLoc = _userHasValidLocation();
    final filteredSpecials = hasLoc
        ? _dailySpecials.where((s) => !s.outOfDeliveryRange).toList()
        : _dailySpecials.toList();

    if (filteredSpecials.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple text title like other sections
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              const Text("\uD83C\uDF7D\uFE0F", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                "Piatti del Giorno",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filteredSpecials.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final special = filteredSpecials[index];
              return DailySpecialCard(
                  special: special,
                  lang: lang,
                  providerController: providerController,
                  cart: cart);
            },
          ),
        ),
      ],
    );
  }

  String _getFilterTitle(String key) {
    switch (key) {
      case 'consegna_gratis':
        return 'Consegna Gratuita';
      case 'piatto_giorno':
        return 'Piatti del Giorno';
      case '2x1':
        return '2×1 Limited';
      case 'limitata':
        return 'Offerte Limitate';
      case 'offerte':
        return 'Le offerte di oggi';
      default:
        return 'Ristoranti';
    }
  }

  Widget _buildTwoForOneSection(List<ProviderData> providerList,
      ProviderController providerController, CartTextProvider cart) {
    return const SizedBox.shrink();
  }

  Widget _buildFreeDeliverySection(List<ProviderData> providerList,
      ProviderController providerController, CartTextProvider cart) {
    return const SizedBox.shrink();
  }

  Widget _buildAutoBannerCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Horizontal card - Deliveroo style

  // ------------------ FILTER ROWS ------------------

  Widget _buildFilterRow(ProviderController providerController) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Types (All, Ultima offerte, Pizza, etc.)
        _buildTypesRow(providerController),
        const SizedBox(height: 8),
        // Row 2: Offers (Tutti, Free delivery, 2x1, Limited, Offerte)
        _buildOffersRow(providerController),
      ],
    );
  }

  // Row 1: Types from API - Deliveroo style (circular images, no border)
  Widget _buildTypesRow(ProviderController providerController) {
    final types = providerController.Types ?? [];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 1 + types.length, // "All" + types
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final bool isSelected = index == selectedTypeFilter;
          String label;
          String? imageUrl;

          if (index == 0) {
            label = "All";
          } else {
            final typeData = types[index - 1];
            label = typeData.type ?? "";
            imageUrl =
                typeData.image != null ? fixImageUrl(typeData.image!) : null;
          }

          return GestureDetector(
            onTap: isLoadingTypeFilter
                ? null
                : () async {
                    setState(() {
                      selectedTypeFilter = index;
                      isLoadingTypeFilter = true;
                    });

                    await _applyTypeFilter(index, providerController);

                    if (!mounted) return;
                    setState(() {
                      isLoadingTypeFilter = false;
                    });
                  },
            child: SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Center(
                      child: isLoadingTypeFilter && isSelected
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.red),
                              ),
                            )
                          : imageUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 52,
                                      height: 52,
                                      color: const Color(0xFFF5F3EE),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 52,
                                      height: 52,
                                      color: const Color(0xFFF5F3EE),
                                      child: Icon(
                                        Icons.restaurant,
                                        size: 26,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.grid_view_rounded,
                                  size: 28,
                                  color: isSelected
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Label
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.red : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Map server filter keys to display data
  static const Map<String, Map<String, dynamic>> _filterMap = {
    'piatto_giorno': {
      "label": "Piatto del Giorno",
      "icon": Icons.restaurant_menu,
    },
    '2x1': {"label": "2x1", "icon": Icons.celebration},
    'limitata': {"label": "Limited", "icon": Icons.timer},
    'offerte': {"label": "Offerte", "icon": Icons.local_offer},
    'consegna_gratis': {
      "label": "Free delivery",
      "icon": Icons.local_shipping,
    },
  };

  List<Map<String, dynamic>> _getOrderedFilters() {
    if (_filterOrder.isNotEmpty) {
      final ordered = <Map<String, dynamic>>[];
      for (final key in _filterOrder) {
        final data = _filterMap[key];
        if (data != null) {
          ordered.add({
            "label": data["label"],
            "icon": data["icon"],
            "key": key,
          });
        }
      }
      if (ordered.isNotEmpty) return ordered;
    }
    // Default order
    return [
      {
        "label": "Free delivery",
        "icon": Icons.local_shipping,
        "key": "consegna_gratis"
      },
      {
        "label": "Piatto del Giorno",
        "icon": Icons.restaurant_menu,
        "key": "piatto_giorno"
      },
      {"label": "2x1", "icon": Icons.celebration, "key": "2x1"},
      {"label": "Limited", "icon": Icons.timer, "key": "limitata"},
      {"label": "Offerte", "icon": Icons.local_offer, "key": "offerte"},
    ];
  }

  // Row 2: Offers
  Widget _buildOffersRow(ProviderController providerController) {
    final filters = _getOrderedFilters();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final f = filters[index];
          final fKey = f["key"] as String;
          final bool isSelected = _selectedFilterKey == fKey;

          return GestureDetector(
            onTap: isLoadingFilter
                ? null
                : () async {
                    final filterKey = filters[index]["key"] as String;

                    // Toggle: if tapping the same filter, deselect it
                    if (_selectedFilterKey == filterKey) {
                      setState(() {
                        selectedFilter = -1;
                        _selectedFilterKey = '';
                      });
                      // Reset to all providers
                      providerController.filteredProviders =
                          providerController.providers;
                      return;
                    }

                    setState(() {
                      selectedFilter = index;
                      _selectedFilterKey = filterKey;
                      isLoadingFilter = true;
                    });

                    await _applyOfferFilter(index, providerController,
                        filterKey: filterKey);

                    if (!mounted) return;
                    setState(() {
                      isLoadingFilter = false;
                    });
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoadingFilter && isSelected)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      f["icon"] as IconData,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.red,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    f["label"] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Apply type filter
  Future<void> _applyTypeFilter(
      int filterIndex, ProviderController providerController) async {
    // Clear banner filter when applying any filter
    providerController.clearBannerFilter();

    final allProviders = providerController.providers ?? [];
    final types = providerController.Types ?? [];

    if (filterIndex == 0) {
      // "All" - show all providers and reset offer filter
      providerController.filteredProviders = List.from(allProviders);
      setState(() {
        _selectedFilterKey = '';
        selectedFilter = -1;
      });
      return;
    }

    // Filter by type
    if ((filterIndex - 1) < types.length) {
      final selectedType = types[filterIndex - 1];
      final typeId = selectedType.id;

      final filtered = allProviders.where((p) {
        if (p.type == null || p.type!.isEmpty) return false;
        return p.type!.any((t) => t.type?.id == typeId);
      }).toList();

      providerController.filteredProviders = filtered;
      setState(() {});
    }
  }

  // ------------------ OFFERS CACHING HELPERS ------------------

  bool _cacheValid() {
    final t = _offersCacheTime;
    if (t == null) return false;
    return DateTime.now().difference(t) <= _offersCacheTTL;
  }

  Future<void> _fetchOffersProviderMap({
    required String cacheKey, // free_delivery | two_for_one | active
    required String urlPath, // /api/offers/...
  }) async {
    // if cache valid and exists -> skip
    if (_cacheValid() &&
        _cachedProviderIds.containsKey(cacheKey) &&
        _cachedProviderOffers.containsKey(cacheKey)) {
      return;
    }

    final String myUrl = "$globalUrl$urlPath";

    http.Response response;
    try {
      response = await http.get(
        Uri.parse(myUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': MyApp2.token ?? "",
        },
      ).timeout(const Duration(seconds: 12), onTimeout: () {
        throw Exception('Timeout loading data');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Caricamento dati fallito. Controlla la connessione o riprova più tardi.')),
        );
      }
      return;
    }

    final Set<int> providerIds = {};
    final Map<int, OfferData> providerOffers = {};

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['data'] is List) {
        for (final offer in (data['data'] as List)) {
          try {
            if (offer is Map &&
                offer['branch'] != null &&
                offer['branch']['provider_id'] != null) {
              final int providerId =
                  (offer['branch']['provider_id'] as num).toInt();
              providerIds.add(providerId);

              // save first offer for provider
              providerOffers.putIfAbsent(providerId,
                  () => OfferData.fromJson(Map<String, dynamic>.from(offer)));
            }
          } catch (_) {}
        }
      }
    }

    _cachedProviderIds[cacheKey] = providerIds;
    _cachedProviderOffers[cacheKey] = providerOffers;
    _offersCacheTime = DateTime.now();
  }

  // ------------------ APPLY OFFER FILTER ------------------
  Future<void> _applyOfferFilter(
      int filterIndex, ProviderController providerController,
      {String? filterKey}) async {
    // Clear banner filter when applying any filter
    providerController.clearBannerFilter();

    final allProviders = providerController.providers ?? [];

    if (allProviders.isEmpty) {
      providerController.filteredProviders = [];
      providerController.notifyListeners();
      return;
    }

    // Use filterKey if provided, otherwise fall back to index-based lookup
    final key = filterKey ??
        _getOrderedFilters().elementAtOrNull(filterIndex)?["key"] ??
        "";

    List<ProviderData> filtered = [];

    try {
      if (key == 'consegna_gratis') {
        // Free delivery
        await _fetchOffersProviderMap(
          cacheKey: 'free_delivery',
          urlPath: '/api/offers/free-delivery',
        );

        final ids = _cachedProviderIds['free_delivery'] ?? {};
        final offers = _cachedProviderOffers['free_delivery'] ?? {};

        filtered = allProviders.where((p) {
          final pid = p.id;
          if (pid == null) return false;
          final hasOffer = ids.contains(pid);
          if (hasOffer) {
            // keep original offer_value if exists
            final originalValue = p.offer?.offer_value;
            p.offer = offers[pid];
            if (originalValue != null && p.offer != null) {
              p.offer = OfferData(
                id: p.offer!.id,
                branch_id: p.offer!.branch_id,
                product_id: p.offer!.product_id,
                gift_product_id: p.offer!.gift_product_id,
                offer_type: p.offer!.offer_type,
                offer_price: p.offer!.offer_price,
                offer_value: originalValue,
                code: p.offer!.code,
                phone: p.offer!.phone,
                min_order_amount: p.offer!.min_order_amount,
                min_spend: p.offer!.min_spend,
                fixed_discount_value: p.offer!.fixed_discount_value,
                is_for_new_customers: p.offer!.is_for_new_customers,
                start_at: p.offer!.start_at,
                end_at: p.offer!.end_at,
                delivery_api_token: p.offer!.delivery_api_token,
                created_at: p.offer!.created_at,
                updated_at: p.offer!.updated_at,
              );
            }
          }
          return hasOffer;
        }).toList();
      } else if (key == 'piatto_giorno') {
        // Piatto del Giorno
        filtered = allProviders.where((p) {
          return p.id != null && _dailySpecialProviderIds.contains(p.id);
        }).toList();
      } else if (key == '2x1') {
        // 2x1
        await _fetchOffersProviderMap(
          cacheKey: 'two_for_one',
          urlPath: '/api/offers/two-for-one',
        );

        final ids = _cachedProviderIds['two_for_one'] ?? {};
        final offers = _cachedProviderOffers['two_for_one'] ?? {};

        filtered = allProviders.where((p) {
          final pid = p.id;
          if (pid == null) return false;
          final hasOffer = ids.contains(pid);
          if (hasOffer) {
            final originalValue = p.offer?.offer_value;
            p.offer = offers[pid];
            if (originalValue != null && p.offer != null) {
              p.offer = OfferData(
                id: p.offer!.id,
                branch_id: p.offer!.branch_id,
                product_id: p.offer!.product_id,
                gift_product_id: p.offer!.gift_product_id,
                offer_type: p.offer!.offer_type,
                offer_price: p.offer!.offer_price,
                offer_value: originalValue,
                code: p.offer!.code,
                phone: p.offer!.phone,
                min_order_amount: p.offer!.min_order_amount,
                min_spend: p.offer!.min_spend,
                fixed_discount_value: p.offer!.fixed_discount_value,
                is_for_new_customers: p.offer!.is_for_new_customers,
                start_at: p.offer!.start_at,
                end_at: p.offer!.end_at,
                delivery_api_token: p.offer!.delivery_api_token,
                created_at: p.offer!.created_at,
                updated_at: p.offer!.updated_at,
              );
            }
          }
          return hasOffer;
        }).toList();
      } else if (key == 'limitata') {
        // Limited (end within 7 days)
        await _fetchOffersProviderMap(
          cacheKey: 'active',
          urlPath: '/api/offers/active',
        );

        final now = DateTime.now();
        final sevenDaysLater = now.add(const Duration(days: 7));

        final offersMap = _cachedProviderOffers['active'] ?? {};

        // keep only providers whose offer ends soon
        final Set<int> limitedProviderIds = {};
        offersMap.forEach((pid, offer) {
          try {
            if (offer.end_at != null) {
              final endDate = safeDateParse(offer.end_at.toString());
              if (endDate.isAfter(now) && endDate.isBefore(sevenDaysLater)) {
                limitedProviderIds.add(pid);
              }
            }
          } catch (_) {}
        });

        filtered = allProviders.where((p) {
          final pid = p.id;
          if (pid == null) return false;
          final hasOffer = limitedProviderIds.contains(pid);
          if (hasOffer) {
            final originalValue = p.offer?.offer_value;
            p.offer = offersMap[pid];
            if (originalValue != null && p.offer != null) {
              p.offer = OfferData(
                id: p.offer!.id,
                branch_id: p.offer!.branch_id,
                product_id: p.offer!.product_id,
                gift_product_id: p.offer!.gift_product_id,
                offer_type: p.offer!.offer_type,
                offer_price: p.offer!.offer_price,
                offer_value: originalValue,
                code: p.offer!.code,
                phone: p.offer!.phone,
                min_order_amount: p.offer!.min_order_amount,
                min_spend: p.offer!.min_spend,
                fixed_discount_value: p.offer!.fixed_discount_value,
                is_for_new_customers: p.offer!.is_for_new_customers,
                start_at: p.offer!.start_at,
                end_at: p.offer!.end_at,
                delivery_api_token: p.offer!.delivery_api_token,
                created_at: p.offer!.created_at,
                updated_at: p.offer!.updated_at,
              );
            }
          }
          return hasOffer;
        }).toList();
      } else if (key == 'offerte') {
        // Offerte (discount offers only)
        await _fetchOffersProviderMap(
          cacheKey: 'discount',
          urlPath: '/api/offers/discount',
        );

        final ids = _cachedProviderIds['discount'] ?? {};
        final offers = _cachedProviderOffers['discount'] ?? {};

        filtered = allProviders.where((p) {
          final pid = p.id;
          if (pid == null) return false;
          final hasOffer = ids.contains(pid);
          if (hasOffer) {
            final originalValue = p.offer?.offer_value;
            p.offer = offers[pid];
            if (originalValue != null && p.offer != null) {
              p.offer = OfferData(
                id: p.offer!.id,
                branch_id: p.offer!.branch_id,
                product_id: p.offer!.product_id,
                gift_product_id: p.offer!.gift_product_id,
                offer_type: p.offer!.offer_type,
                offer_price: p.offer!.offer_price,
                offer_value: originalValue,
                code: p.offer!.code,
                phone: p.offer!.phone,
                min_order_amount: p.offer!.min_order_amount,
                min_spend: p.offer!.min_spend,
                fixed_discount_value: p.offer!.fixed_discount_value,
                is_for_new_customers: p.offer!.is_for_new_customers,
                start_at: p.offer!.start_at,
                end_at: p.offer!.end_at,
                delivery_api_token: p.offer!.delivery_api_token,
                created_at: p.offer!.created_at,
                updated_at: p.offer!.updated_at,
              );
            }
          }
          return hasOffer;
        }).toList();
      } else {
        filtered = List.from(allProviders);
      }
    } catch (e) {
      if (kDebugMode) {
      }
      filtered = List.from(allProviders);
    }

    providerController.filteredProviders = filtered;
    providerController.notifyListeners();
  }
}
