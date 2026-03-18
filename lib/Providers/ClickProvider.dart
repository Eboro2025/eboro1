import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:eboro/API/Favorite.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../API/Auth.dart';
import '../RealTime/Provider/CartTextProvider.dart';
import '../RealTime/Provider/ProductCacheProvider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/API/DailySpecialApi.dart';
import 'package:eboro/Helper/DailySpecialData.dart';
import 'package:eboro/Widget/ProductDetails.dart';
import 'package:eboro/Client/Home.dart' as client_home;

class ClickProvider extends StatefulWidget {
  final int? providerID;
  final String? name;
  final String? catID;
  final String? catName;

  const ClickProvider({
    Key? key,
    required this.providerID,
    required this.name,
    this.catID,
    this.catName,
  }) : super(key: key);

  @override
  ClickProvider2 createState() => ClickProvider2();
}

class ClickProvider2 extends State<ClickProvider>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Tab> tabs;

  late ScrollController _scrollController;
  late List<GlobalKey> _sectionKeys;
  bool _isProgrammaticScroll = false;

  late Map<String, List> _productsByType;

  bool _isShowingDetails = false;
  bool _isCollapsed = false;

  double? _duration;
  double? _shipping;

  bool _showCartBar = false;
  String _lastProductName = '';

  late Timer timer;
  int selectedFilter = -1;

  void _startTimer([int sec = 60]) {
    timer = Timer.periodic(
      Duration(seconds: sec),
      (Timer t) => checkInternetState(),
    );
  }

  /// Helper method to build offer badge text
  /// Shows: -X% for discount, fs for free delivery, 2×1 for two-for-one, etc.
  String _buildOfferText(dynamic offer) {
    if (offer == null) return 'Offerta';

    final offerType = offer.offer_type;
    final List<String> parts = [];

    // Check if it's a discount offer
    if (offerType == 'discount' || offerType == 'fixed_discount') {
      parts.add('-${offer.offer_value ?? 25}%');
    }

    // Check if it's a 2×1 or 1+1 offer
    if (offerType == 'two_for_one' ||
        offerType == 'one_plus_one' ||
        offerType == 'two_for_one_free_delivery') {
      if (offerType == 'one_plus_one') {
        parts.add('1+1');
      } else {
        parts.add('2×1');
      }
    }

    // Check if free delivery is included
    if (offerType == 'free_delivery' ||
        offerType == 'two_for_one_free_delivery') {
      parts.add('fs');
    }

    if (parts.isEmpty) {
      return 'Offerta';
    }

    return parts.join(' ');
  }

  @override
  void initState() {
    super.initState();

    _startTimer(60);

    final providerItem = Provider2.provider!
        .firstWhere((element) => element.id == widget.providerID);

    // Tabs from product types
    tabs = providerItem.typeInner
            ?.map((g) => Tab(text: g.type!.type.toString()))
            .toList() ??
        [];

    // If no types at all
    if (tabs.isEmpty) {
      tabs = const [Tab(text: 'Menu')];
    }

    // Select initial tab if coming from catName
    int initialTabIndex = 0;
    if (widget.catName != null && tabs.isNotEmpty) {
      final idx = tabs.indexWhere(
        (t) =>
            t.text?.toLowerCase().trim() ==
            widget.catName!.toLowerCase().trim(),
      );
      if (idx != -1) initialTabIndex = idx;
    }

    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: initialTabIndex,
    );

    _scrollController = ScrollController()..addListener(_handleScroll);
    _sectionKeys = List.generate(tabs.length, (_) => GlobalKey());

    _productsByType = <String, List>{};

    // Load products smoothly without blocking
    _loadProductsSmooth(providerItem);

    _duration =
        double.tryParse(providerItem.Delivery?.Duration?.toString() ?? '');
    _shipping =
        double.tryParse(providerItem.Delivery?.shipping?.toString() ?? '');
  }

  /// Load products smoothly - show cache immediately and update in background
  void _loadProductsSmooth(dynamic providerItem) {
    final productCache =
        Provider.of<ProductCacheProvider>(context, listen: false);
    final providerId = widget.providerID!;

    // 1. First: show products from cache immediately (if available)
    final cachedProducts = productCache.getProducts(providerId);
    if (cachedProducts.isNotEmpty) {
      _updateProductsByType(cachedProducts);
    }
    // Do not use Provider2.product as it may belong to a different restaurant

    // 2. Always add listener to update UI when products load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      productCache.addListener(_onCacheUpdated);
      // 3. Load products in background if cache is invalid
      if (!productCache.isCacheValid(providerId)) {
        productCache.loadProductsInBackground(providerId);
      }
    });
  }

  /// Called when the cache is updated
  void _onCacheUpdated() {
    if (!mounted) return;

    final productCache =
        Provider.of<ProductCacheProvider>(context, listen: false);
    final products = productCache.getProducts(widget.providerID!);

    if (products.isNotEmpty) {
      setState(() {
        _updateProductsByType(products);
      });
    }
  }

  /// Split products by type
  void _updateProductsByType(List products) {
    _productsByType.clear();
    for (var p in products) {
      final key = p.type?.type?.toString() ?? '';
      _productsByType.putIfAbsent(key, () => []).add(p);
    }

    // Also update Provider2.product so the rest of the code works
    if (products.isNotEmpty) {
      Provider2.product = products.cast();
    }
  }

  @override
  void dispose() {
    // Remove listener from cache
    try {
      final productCache =
          Provider.of<ProductCacheProvider>(context, listen: false);
      productCache.removeListener(_onCacheUpdated);
    } catch (_) {}

    _tabController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    timer.cancel();
    super.dispose();
  }

  Future<void> checkInternetState() async {
    final provider = Provider.of<ProviderController>(context, listen: false);
    await provider.updateProvider(provider.categoryId);
  }

  // ====================== Header ======================
  Widget _buildHeader(BuildContext context) {
    final providerItem = Provider2.provider!
        .firstWhere((element) => element.id == widget.providerID);

    final String imageUrl = (providerItem.logo ?? "").toString();
    final String rateValue = providerItem.rateRatio?.toString() ?? '0';
    final String rateUser = providerItem.rate_user?.toString() ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cover image with overlay info
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: fixImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: myColor.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: myColor,
                        child: const Icon(
                          Icons.store_mall_directory,
                          color: Colors.white70,
                          size: 40,
                        ),
                      ),
                    ),
                    // Bottom gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Info chips on cover image
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Row(
                        children: [
                          _buildCoverChip(
                            icon: Icons.star_rounded,
                            label: '$rateValue ($rateUser)',
                            iconColor: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          if (_duration != null)
                            _buildCoverChip(
                              icon: Icons.access_time,
                              label: '${_duration!.toStringAsFixed(0)} min',
                            ),
                          const SizedBox(width: 8),
                          if (_shipping != null)
                            _buildCoverChip(
                              icon: Icons.delivery_dining,
                              label: '${_shipping!.toStringAsFixed(2)} €',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Circular logo
            Positioned(
              bottom: -40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: fixImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: myColor,
                        child: const Icon(Icons.store, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Action buttons row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeaderButton(
                icon: Icons.restaurant_menu,
                label: "Menu",
                color: myColor,
                onTap: () => _showDishOfTheDay(),
              ),
              // Spacer for logo
              const SizedBox(width: 90),
              _buildHeaderButton(
                icon: Icons.share,
                label: AppLocalizations.of(context)!.translate("share") ?? "Condividi",
                color: myColor,
                onTap: () => _shareStore(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Info button centered
        Center(
          child: _buildHeaderButton(
            icon: Icons.info_outline,
            label: "Info",
            color: Colors.blue.shade600,
            onTap: () => _showStoreInfo(),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCoverChip({
    required IconData icon,
    required String label,
    Color iconColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.black.withOpacity(0.5)
              : Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
          border: onTap != null
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Call restaurant
  void _callRestaurant() {
    final providerItem = Provider2.provider!
        .firstWhere((element) => element.id == widget.providerID);
    final phone = providerItem.user?.mobile?.toString();
    if (phone == null || phone.isEmpty || phone == '--') {
      Auth2.show('Numero di telefono non disponibile');
      return;
    }
    launchUrl(Uri(scheme: 'tel', path: phone));
  }

  // Store info - comprehensive bottom sheet
  void _showStoreInfo() {
    final providerItem = Provider2.provider!
        .firstWhere((element) => element.id == widget.providerID);

    // Location data
    final branch = providerItem.branch?.isNotEmpty == true
        ? providerItem.branch!.first
        : null;
    final storeAddress = branch?.address ??
        providerItem.user?.address?.toString() ??
        '--';
    final storeLat = branch?.lat ?? providerItem.user?.lat;
    final storeLong = branch?.long ?? providerItem.user?.long;
    final phone = providerItem.user?.mobile?.toString() ?? '--';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Restaurant header with name and status
              Row(
                children: [
                  // Logo
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      image: providerItem.logo != null
                          ? DecorationImage(
                              image: NetworkImage(providerItem.logo!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: providerItem.logo == null
                        ? Icon(Icons.storefront, color: Colors.grey[400], size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerItem.name ?? 'Ristorante',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: providerItem.state == 'open'
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: providerItem.state == 'open'
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE53935),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                providerItem.state == 'open' ? 'Aperto' : 'Chiuso',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: providerItem.state == 'open'
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info chips row
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[50]!, Colors.grey[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.access_time_rounded,
                        _duration != null ? '${_duration!.toStringAsFixed(0)} min' : '--',
                        'Tempo',
                        const Color(0xFFFF9800),
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.grey[300]),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.delivery_dining_rounded,
                        _shipping != null ? '${_shipping!.toStringAsFixed(2)} €' : '--',
                        'Consegna',
                        myColor,
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.grey[300]),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.star_rounded,
                        providerItem.rate ?? '--',
                        'Voto',
                        const Color(0xFFFFC107),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contatti
              Row(
                children: [
                  Icon(Icons.contact_phone_rounded, size: 18, color: myColor),
                  const SizedBox(width: 8),
                  const Text('Contatti', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                ],
              ),
              const SizedBox(height: 10),
              if (phone != '--' && phone.isNotEmpty)
                _buildContactRow(Icons.phone_rounded, phone, 'Telefono', () {
                  Navigator.pop(context);
                  launchUrl(Uri(scheme: 'tel', path: phone));
                }),
              if (providerItem.user?.email != null && providerItem.user!.email!.isNotEmpty)
                _buildContactRow(Icons.email_outlined, providerItem.user!.email!, 'Email', null),
              const SizedBox(height: 16),

              // Posizione
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 18, color: myColor),
                  const SizedBox(width: 8),
                  const Text('Posizione', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                ],
              ),
              const SizedBox(height: 10),
              if (storeAddress.isNotEmpty && storeAddress != '--')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(storeAddress, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      ),
                    ],
                  ),
                ),
              if (storeLat != null && storeLong != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$storeLat,$storeLong');
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: myColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 18, color: myColor),
                        const SizedBox(width: 8),
                        Text('Apri su Google Maps', style: TextStyle(fontSize: 13, color: myColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDishOfTheDay();
                      },
                      icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                      label: const Text('Piatto del giorno', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: myColor,
                        side: BorderSide(color: myColor.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (phone != '--' && phone.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          launchUrl(Uri(scheme: 'tel', path: phone));
                        },
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: Text(AppLocalizations.of(context)!.translate("call") ?? "Chiama", style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: myColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: myColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  const SizedBox(height: 1),
                  Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // Opening hours
  void _showOpeningHours() {
    final providerItem = Provider2.provider!
        .firstWhere((element) => element.id == widget.providerID);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: myColor),
                const SizedBox(width: 8),
                const Text(
                  'Orari di apertura',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.schedule, 'Stato',
                providerItem.state == 'open' ? 'Aperto' : 'Chiuso'),
            _buildInfoRow(Icons.today, 'Lunedì - Venerdì', '09:00 - 22:00'),
            _buildInfoRow(Icons.today, 'Sabato - Domenica', '10:00 - 23:00'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Delivery info
  void _showDeliveryInfo() {
    final providerItem = Provider2.provider!
        .firstWhere((element) => element.id == widget.providerID);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delivery_dining, color: myColor),
                const SizedBox(width: 8),
                const Text(
                  'Informazioni consegna',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
                Icons.timer,
                'Tempo di consegna',
                _duration != null
                    ? '${_duration!.toStringAsFixed(0)} minuti'
                    : '--'),
            _buildInfoRow(
                Icons.euro,
                'Costo consegna',
                _shipping != null
                    ? '${_shipping!.toStringAsFixed(2)} €'
                    : '--'),
            _buildInfoRow(Icons.schedule, 'Orari di consegna', '09:00 - 22:00'),
            _buildInfoRow(
                Icons.location_on, 'Area consegna', 'Città e dintorni'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consegna gratuita per ordini superiori a 20€',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Dish of the day - fetches today's specials from DailySpecialApi for this store
  void _showDishOfTheDay() async {
    Progress.progressDialogue(context);
    final allSpecials = await DailySpecialApi.getTodaySpecials();
    if (!mounted) return;
    Progress.dimesDialog(context);

    // Filter today's specials belonging to this store only
    final providerSpecials = allSpecials
        .where((s) => s.providerId == widget.providerID)
        .toList();

    final lang = MyApp2.apiLang ?? 'it';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, color: myColor),
                const SizedBox(width: 8),
                const Text(
                  'Piatti del giorno',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            if (providerSpecials.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Nessuna offerta speciale oggi'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: providerSpecials.length,
                  itemBuilder: (context, index) {
                    final s = providerSpecials[index];
                    return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: s.productImage != null
                            ? Image.network(
                                fixImageUrl(s.productImage!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.red.shade50,
                                  child: const Icon(Icons.restaurant_menu,
                                      color: Colors.red),
                                ),
                              )
                            : Container(
                                color: Colors.red.shade50,
                                child: const Icon(Icons.restaurant_menu,
                                    color: Colors.red),
                              ),
                      ),
                    ),
                    title: Text(s.getProductName(lang)),
                    subtitle: Row(
                      children: [
                        if (s.hasDiscount && s.originalPrice != null)
                          Text(
                            '€${s.originalPrice!.toStringAsFixed(2)} ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text('€${s.displayPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: myColor)),
                      ],
                    ),
                    trailing: s.hasDiscount
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '-${s.discountPercentage}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        : null,
                  );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Location
  void _showStoreLocation() {
    final providerItem = Provider2.provider!
        .firstWhere((element) => element.id == widget.providerID);

    // Store address from branch or user
    final branch = providerItem.branch?.isNotEmpty == true
        ? providerItem.branch!.first
        : null;
    final storeAddress = branch?.address ??
        providerItem.user?.address?.toString() ??
        '--';

    // Extract city from address (usually after postal code)
    String city = '--';
    try {
      final parts = storeAddress.split(',');
      if (parts.length >= 3) {
        // Address is usually: "Via X, 96, 20162 Milano MI, Italia"
        // City is in the third or fourth part
        final cityPart = parts.length >= 4 ? parts[2].trim() : parts[parts.length - 2].trim();
        // Remove postal code if present
        city = cityPart.replaceAll(RegExp(r'^\d{5}\s*'), '').trim();
        if (city.isEmpty) city = cityPart.trim();
      }
    } catch (_) {}

    // Store coordinates for map
    final storeLat = branch?.lat ?? providerItem.user?.lat;
    final storeLong = branch?.long ?? providerItem.user?.long;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: myColor),
                const SizedBox(width: 8),
                const Text(
                  'Posizione',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_city, 'Indirizzo', storeAddress),
            _buildInfoRow(Icons.map, 'Città', city),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (storeLat != null && storeLong != null) {
                    final url = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$storeLat,$storeLong');
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('Apri su mappa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Share store
  void _shareStore() {
    final providerItem = Provider2.provider!
        .firstWhere((element) => element.id == widget.providerID);

    final String storeName = providerItem.name?.toString() ?? '';
    final String storeAddress = providerItem.user?.address?.toString() ?? '';
    final String storePhone = providerItem.user?.mobile?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: myColor),
                const SizedBox(width: 8),
                const Text(
                  'Condividi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (storeAddress.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            storeAddress,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (storePhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          storePhone,
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    final text =
                        'Scopri $storeName su Eboro!\n📍 $storeAddress\n📞 $storePhone';
                    Navigator.pop(context);
                    Auth2.show('Apertura WhatsApp...\n$text');
                  },
                ),
                _buildShareOption(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(context);
                    Auth2.show('Condivisione su Facebook...');
                  },
                ),
                _buildShareOption(
                  icon: Icons.link,
                  label: 'Copia link',
                  color: Colors.grey[700]!,
                  onTap: () {
                    final baseUrl = globalUrl.endsWith('/')
                        ? globalUrl.substring(0, globalUrl.length - 1)
                        : globalUrl;
                    final link = '$baseUrl/store/${providerItem.id}';
                    Navigator.pop(context);
                    Auth2.show('Link copiato: $link');
                  },
                ),
                _buildShareOption(
                  icon: Icons.more_horiz,
                  label: 'Altro',
                  color: myColor,
                  onTap: () {
                    final text =
                        'Scopri $storeName su Eboro!\n📍 $storeAddress';
                    Navigator.pop(context);
                    Auth2.show('Condivisione:\n$text');
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================== Sections (one per tab) ======================
  List<Widget> _buildSections() {
    final List<Widget> sections = [];
    final productCache =
        Provider.of<ProductCacheProvider>(context, listen: false);
    final isLoading = productCache.isLoading(widget.providerID!);

    for (int i = 0; i < tabs.length; i++) {
      final String typeName = tabs[i].text ?? '';

      List sectionProducts;
      if (tabs.length == 1 && typeName == 'Menu') {
        // Use cache instead of Provider2.product to avoid initial load issue
        final cached = productCache.getProducts(widget.providerID!);
        sectionProducts = cached.isNotEmpty ? cached : (Provider2.product ?? []);
      } else {
        sectionProducts = _productsByType[typeName] ?? [];
      }

      sections.add(
        Container(
          key: _sectionKeys[i],
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                typeName,
                style: TextStyle(
                  fontSize: MyApp2.fontSize18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (sectionProducts.isEmpty && isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (sectionProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!
                            .translate("no_products_in_this_category") ??
                        "Nessun prodotto in questa categoria",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sectionProducts.length,
                  itemBuilder: (context, idx) =>
                      _buildList(X: sectionProducts[idx]),
                ),
            ],
          ),
        ),
      );
    }

    sections.add(const SizedBox(height: 40));
    return sections;
  }

  // ====================== Sync tab with scroll ======================
  void _handleScroll() {
    // Update collapsed state
    final bool collapsed = _scrollController.hasClients && _scrollController.offset > 200;
    if (collapsed != _isCollapsed) {
      setState(() { _isCollapsed = collapsed; });
    }

    if (_isProgrammaticScroll) return;
    if (_sectionKeys.isEmpty) return;

    final double statusBar = MediaQuery.of(context).padding.top;
    const double tabBarHeight = 46;
    final double referenceY = statusBar + kToolbarHeight + tabBarHeight + 8;

    int currentIndex = _tabController.index;
    int newIndex = currentIndex;
    double minDelta = double.infinity;

    for (int i = 0; i < _sectionKeys.length; i++) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final pos = box.localToGlobal(Offset.zero).dy;
      final delta = (pos - referenceY).abs();

      if (delta < minDelta) {
        minDelta = delta;
        newIndex = i;
      }
    }

    if (newIndex != currentIndex && newIndex < _tabController.length) {
      _tabController.animateTo(newIndex);
    }
  }

  // ====================== Scroll on tab press ======================
  void _scrollToSection(int index) {
    if (index < 0 || index >= _sectionKeys.length) return;

    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;

    final double statusBar = MediaQuery.of(context).padding.top;
    const double tabBarHeight = 46.0;
    final double desiredTop = statusBar + kToolbarHeight + tabBarHeight + 8;

    final double sectionY = box.localToGlobal(Offset.zero).dy;
    final double delta = sectionY - desiredTop;
    final double targetOffset = _scrollController.offset + delta;

    _isProgrammaticScroll = true;

    _scrollController
        .animateTo(
          targetOffset.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .whenComplete(() => _isProgrammaticScroll = false);
  }

  // ====================== Cart bar at bottom ======================
  Widget _buildCartBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Aggiunto $_lastProductName al carrello',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Vedi carrello',
                style: TextStyle(
                  color: Colors.blue[200],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== Open product details ======================
  Future<void> _openProductDetails(int productID, String productName,
      {dynamic product}) async {
    if (_isShowingDetails) return;
    _isShowingDetails = true;

    // Ensure product exists in Provider2.product before opening details
    if (product != null) {
      if (Provider2.product == null) {
        Provider2.product = [product];
      } else if (!Provider2.product!.any((p) => p.id == productID)) {
        Provider2.product!.add(product);
      }
    }

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ProductDetails(
              productID: productID,
              scrollController: scrollController,
            ),
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        setState(() {
          _lastProductName = productName;
          _showCartBar = true;
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showCartBar = false);
        });
      }
    } finally {
      _isShowingDetails = false;
    }
  }

  // ====================== BUILD ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: client_home.CartButton(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _isCollapsed ? Colors.black : Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: _isCollapsed
                ? Text(
                    widget.name.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            actions: _isCollapsed
                ? [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.black),
                      onPressed: () => _shareStore(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.black),
                      onPressed: () => _showStoreInfo(),
                    ),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: tabs,
                  labelColor: myColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: myColor,
                  indicatorWeight: 3,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: (index) {
                    _scrollToSection(index);
                  },
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ..._buildSections(),
            ]),
          ),
        ],
      ),
    );
  }

  // ====================== Single product card ======================
  Widget _buildList({required dynamic X}) {
    if (X == null || X.product_type == 'Sauce') {
      return const SizedBox.shrink();
    }

    // Check if there is an offer - any type of offer
    final bool hasOffer = X.offer != null &&
        X.offer.offer_type != null &&
        X.offer.offer_type.toString().trim().isNotEmpty;

    final double price = double.tryParse(X.price.toString()) ?? 0;
    final double offerPrice = hasOffer
        ? (double.tryParse(X.offer?.offer_price?.toString() ?? '0') ?? 0)
        : 0;
    final double finalPrice = hasOffer && X.offer?.offer_type == 'discount'
        ? (price - offerPrice)
        : price;

    return GestureDetector(
      onTap: () {
        if (X.has_outofstock == 0) {
          _openProductDetails(X.id, X.name.toString(), product: X);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product image - square with cover fit
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: fixImageUrl(X.image.toString()),
                  errorWidget: (context, url, error) => Icon(
                    Icons.fastfood,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    X.name.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    X.type == null ? "" : X.type.type.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (X.has_outofstock == 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        AppLocalizations.of(context)!
                                .translate("out_Of_stock") ??
                            "Out of stock",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Price section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasOffer && X.offer?.offer_type == 'discount')
                  Text(
                    '${price.toStringAsFixed(2)} \u20ac',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.red.shade300,
                      decorationThickness: 1.5,
                    ),
                  ),
                if (hasOffer && X.offer?.offer_type == 'discount')
                  const SizedBox(height: 2),
                Text(
                  '${finalPrice.toStringAsFixed(2)} \u20ac',
                  style: TextStyle(
                    color: hasOffer && X.offer?.offer_type == 'discount'
                        ? Colors.red.shade700
                        : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasOffer &&
                    X.offer?.offer_type != 'discount')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: X.offer?.offer_type == 'free_delivery'
                            ? Colors.blue.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _buildOfferText(X.offer),
                        style: TextStyle(
                          color: X.offer?.offer_type == 'free_delivery'
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Add button - on the right side
            if (X.has_outofstock == 0)
              GestureDetector(
                onTap: () {
                  _openProductDetails(X.id, X.name.toString(),
                      product: X);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
