import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Order.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/Client/Home.dart';
import 'package:eboro/Client/Addresses.dart';
import 'package:eboro/Auth/QuickRegister.dart';
import 'package:eboro/Client/Location.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/Widget/CartItem.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pay/pay.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import '../Helper/ProviderData.dart';
import '../Helper/ProductData.dart';
import '../Widget/Progress.dart';
import 'package:eboro/Widget/StripeWebViewPage.dart';
import 'package:eboro/Widget/RecommendedSection.dart';

class MyCart extends StatefulWidget {
  @override
  MyCart2 createState() => MyCart2();
}

class MyCart2 extends State<MyCart> {
  // Payment methods: 0 = Cash, 1 = Credit Card, 2 = PayPal, 3 = Apple Pay, 4 = Google Pay
  // Android: only Google Pay
  String paymentMethod = "1";
  bool inClicked = true;

  // Apple Pay & Google Pay configurations
  late final Pay _payClient;
  bool _isApplePayAvailable = false;

  // Google Pay config as constant for reuse
  // Apple Pay config as constant for reuse
  static const String applePayConfigJson = '''{
    "provider": "apple_pay",
    "data": {
      "merchantIdentifier": "merchant.com.eboro.app",
      "displayName": "Eboro",
      "merchantCapabilities": ["3DS", "debit", "credit"],
      "supportedNetworks": ["amex", "visa", "masterCard"],
      "countryCode": "IT",
      "currencyCode": "EUR"
    }
  }''';

  // Google Pay config as constant for reuse
  static const String googlePayConfigJson = '''{
    "provider": "google_pay",
    "data": {
      "environment": "PRODUCTION",
      "apiVersion": 2,
      "apiVersionMinor": 0,
      "allowedPaymentMethods": [{
        "type": "CARD",
        "parameters": {
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "allowedCardNetworks": ["AMEX", "MASTERCARD", "VISA"]
        },
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "stripe",
            "stripe:version": "2020-08-27",
            "stripe:publishableKey": "pk_live_51JcFBIGPk9GE5RGdagDFQXdY3bXsGPoHAZ6dBl9eRZiG5Q7MMOwbPFqDiNPNNJkga0T8aqHZHIfAOtEF5Fk3P3QP008gs6N9ND"
          }
        }
      }],
      "merchantInfo": {
        "merchantId": "BCR2DN4TU7HJV7BM",
        "merchantName": "Eboro"
      },
      "transactionInfo": {
        "totalPriceStatus": "FINAL",
        "countryCode": "IT",
        "currencyCode": "EUR"
      }
    }
  }''';

  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  DateTime order_at = DateTime.now();
  String selectedTime = 'Now';
  String? selected_options;
  String? selected_gratuity;
  double _promoDiscount = 0.0;
  bool needsPosate = true; // طلب أدوات الطعام (افتراضي: نعم)

  /// snapshot لحالة السلة أول ما تفتح الشاشة (لترشيح المنتجات فقط)
  Map<String, int> _initialCartCounts = {};

  /// Stripe transaction ID after successful payment
  String? _stripeTransactionId;

  /// Cached future for recommended products to avoid re-fetching on every rebuild
  Future<List<ProductData>?>? _recommendedFuture;
  
  /// WebViewController جاهز مسبقاً لتسريع فتح صفحة الدفع
  WebViewController? _preloadedStripeController;
  String? _preloadedStripeUrl;

  @override
  void initState() {
    super.initState();

    // Initialize Pay client (سريع)
    _initializePayment();

    // تأخير العمليات الثقيلة إلى بعد أول render
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cart = Provider.of<CartTextProvider>(context, listen: false);

      // 1. بناء snapshot فوري (بدون تأخير)
      _buildInitialCartSnapshot(cart);

      // 2. تأخير تحميل المنتجات الموصى بها (500ms)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final providerId = cart.cart?.cart_items?.firstOrNull?.provider_id;
          if (providerId != null &&
              (cart.cart?.cart_items?.isNotEmpty ?? false)) {
            _recommendedFuture = Provider2.getProducts(providerId);
          }
        }
      });

      // 3. تأخير تجهيز WebView Stripe (1000ms)
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _preloadStripeWebView(cart);
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // عند الرجوع من PayPal، أعد تعيين الـ futures لتجنب عرض old data
    // Fresh data check on dependencies change
  }

  /// يجهز WebViewController ويحمل صفحة Stripe مسبقاً
  void _preloadStripeWebView(CartTextProvider cart) {
    try {
      final items = cart.cart?.cart_items;
      if (items == null || items.isEmpty) return;

      final provider = Provider.of<ProviderController>(context, listen: false);
      final currentProvider = provider.providers
          ?.where((e) => e.id == items.firstOrNull?.provider_id)
          .firstOrNull;
      final deliveryData = currentProvider?.Delivery;

      final subtotal = _calculateSubtotal(cart);
      final tax = double.tryParse(deliveryData?.Tax ?? '0') ?? 0.0;
      final shipping = double.tryParse(deliveryData?.shipping ?? '0') ?? 0.0;
      final total = (subtotal + tax + shipping).clamp(0, double.infinity);

      if (total <= 0) return;

      final amountInCents = (total * 100).round();
      final url = '$globalUrl/stripe/mobile-payment?amount=$amountInCents&wallets=none';

      _preloadedStripeUrl = url;
      _preloadedStripeController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(url));
    } catch (_) {}
  }

  Future<void> _initializePayment() async {
    try {
      // Initialize payment providers

      // Check Apple Pay availability (iOS only)
      if (Platform.isIOS) {
        try {
          _payClient = Pay({
            PayProvider.apple_pay:
                PaymentConfiguration.fromJsonString(applePayConfigJson),
          });
          final canPay = await _payClient.userCanPay(PayProvider.apple_pay);
          if (mounted) {
            setState(() {
              _isApplePayAvailable = canPay;
            });
          }
        } catch (_) {
          // If check fails, still show Apple Pay on iOS
          if (mounted) setState(() => _isApplePayAvailable = true);
        }
      }

    } catch (_) {
      if (Platform.isIOS && mounted) setState(() => _isApplePayAvailable = true);
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _dateController.dispose();
    _cvvController.dispose();
    _commentController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  /// نبني snapshot لعدد كل منتج في السلة وقت فتح الصفحة
  void _buildInitialCartSnapshot(CartTextProvider cart) {
    final items = cart.cart?.cart_items ?? [];
    final Map<String, int> snapshot = {};

    for (final it in items) {
      try {
        final id = it.product_id?.toString();
        if (id == null) continue;

        final int qty = it.qty ?? 1;

        snapshot[id] = (snapshot[id] ?? 0) + qty;
      } catch (_) {}
    }

    setState(() {
      _initialCartCounts = snapshot;
      // مسح الكاش عند تحديث السلة
      _cachedSubtotal = null;
      _cachedCartKey = null;
    });
  }

  // Cache لتخزين آخر subtotal محسوب
  double? _cachedSubtotal;
  String? _cachedCartKey;

  /// تحسب subtotal من cart_items = (سعر المنتج + الصوصات) * الكمية
  double _calculateSubtotal(CartTextProvider cart) {
    final items = cart.cart?.cart_items ?? [];

    // بناء مفتاح كاش يشمل عدد العناصر والكميات والأسعار
    final cartKey = items.map((it) => '${it.product_id}_${it.qty}_${it.product_price}').join('|');

    // استخدام الكاش إذا لم يتغير محتوى السلة
    if (_cachedSubtotal != null && _cachedCartKey == cartKey) {
      return _cachedSubtotal!;
    }

    double subtotal = 0.0;

    for (final it in items) {
      try {
        // الكمية
        final int qty = it.qty ?? 1;

        // سعر المنتج من الكارت
        double productPrice = it.product_price ?? 0.0;

        // محاولة تطبيق الخصم لو المنتج موجود في القائمة
        // نفس طريقة ProductDetails - نستخدم offer_price مباشرة
        if (Provider2.product != null) {
          try {
            final product = Provider2.product!.firstWhere(
              (p) => p.id == it.product_id,
            );

            final offer = product.offer;
            //التحقق من وجود عرض صحيح وفعلي
            if (offer != null &&
                offer.offer_price != null &&
                offer.offer_price.toString().trim().isNotEmpty &&
                offer.offer_price.toString() != '0' &&
                offer.offer_price.toString() != '0.0') {
              // نستخدم offer_price زي ProductDetails بالضبط
              final double offerValue =
                  double.tryParse(offer.offer_price?.toString() ?? '0') ?? 0.0;

              // تطبيق الخصم فقط لو القيمة أكبر من صفر
              if (offerValue > 0) {
                productPrice = productPrice - offerValue;
              }
            }
          } catch (_) {
            // لو مالقيناش المنتج، نستخدم السعر الأصلي
          }
        }

        // مجموع أسعار الصوصات
        double saucesPrice = 0.0;
        for (final s in it.sauces ?? []) {
          saucesPrice += s.price ?? 0.0;
        }

        // مجموع أسعار الإضافات (extras)
        double extrasPrice = 0.0;
        for (final e in it.extras ?? []) {
          extrasPrice += e.price ?? 0.0;
        }

        // سعر السطر = (سعر المنتج + الصوصات + الإضافات) * الكمية
        final double lineTotal =
            (productPrice + saucesPrice + extrasPrice) * qty;

        subtotal += lineTotal;
      } catch (_) {}
    }

    // حفظ في الكاش
    _cachedSubtotal = subtotal;
    _cachedCartKey = cartKey;

    return subtotal;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartTextProvider>(
      builder: (context, cart, child) {
        final provider =
            Provider.of<ProviderController>(context, listen: false);

        // subtotal الصحيح من price * qty (+ الصوصات)
        final subtotal = _calculateSubtotal(cart);

        final currentProvider = provider.providers
            ?.where(
                (e) => e.id == cart.cart?.cart_items?.firstOrNull?.provider_id)
            .firstOrNull;
        final deliveryData = currentProvider?.Delivery;
        final double tax =
            double.tryParse(deliveryData?.Tax ?? SetLocation2.tax ?? "0") ??
                0.0;
        final double shipping = double.tryParse(
                deliveryData?.shipping ?? SetLocation2.ship ?? "0") ??
            0.0;
        final double gratuity =
            double.tryParse(selected_gratuity ?? "0.0") ?? 0.0;

        final double totalBeforePromo = subtotal + tax + shipping + gratuity;
        final double total = (totalBeforePromo - _promoDiscount)
            .clamp(0, double.infinity)
            .toDouble();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SafeArea(
            child: Column(
              children: [
                _buildModernHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _buildShopAndAddressCard(context, cart, provider),
                        const SizedBox(height: 12),
                        _buildPaymentCard(),
                        const SizedBox(height: 12),
                        _buildDeliveryCard(context),
                        const SizedBox(height: 12),
                        _buildGratuityCard(context),
                        const SizedBox(height: 12),
                        _buildPosateCard(context),
                        const SizedBox(height: 12),
                        _buildPromoCodeCard(context),
                        const SizedBox(height: 12),
                        RecommendedSection(
                          cart: cart,
                          recommendedFuture: _recommendedFuture,
                          initialCartCounts: _initialCartCounts,
                          cardDecoration: _cardDecoration(),
                        ),
                        const SizedBox(height: 12),
                        if (cart.cart?.total_price != null) const CartItem(),
                        const SizedBox(height: 12),
                        _buildCommentCard(context),
                        const SizedBox(height: 12),
                        _buildTotalsCard(
                          context: context,
                          subtotal: subtotal,
                          tax: tax,
                          shipping: shipping,
                          gratuity: gratuity,
                          totalBeforePromo: totalBeforePromo,
                          total: total,
                          deliveryDuration:
                              double.tryParse("${deliveryData?.Duration}") ??
                                  0.0,
                          minOrder:
                              double.tryParse("${deliveryData?.OrderMin}") ??
                                  0.0,
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(context, cart, provider, total,
                    subtotal: subtotal,
                    tax: tax,
                    shipping: shipping,
                    gratuity: gratuity),
              ],
            ),
          ),
        );
      },
    );
  }

  // ======================= HEADER =======================

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new, size: 22),
          ),
          Text(
            AppLocalizations.of(context)!.translate("mycart"),
            style: TextStyle(
              fontSize: MyApp2.fontSize18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.more_vert, size: 22, color: Colors.transparent),
        ],
      ),
    );
  }

  // ======================= CARDS =======================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildShopAndAddressCard(BuildContext context, CartTextProvider cart,
      ProviderController provider) {
    final shop = provider.providers
        ?.firstWhere(
          (e) => e.id == cart.cart?.cart_items?.firstOrNull?.provider_id,
          orElse: () => ProviderData(),
        )
        .name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: myColor),
              const SizedBox(width: 8),
              Text(
                shop ?? "Ristorante",
                style: TextStyle(
                  fontSize: MyApp2.fontSize16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${AppLocalizations.of(context)?.translate("address")} :",
            style: TextStyle(
              fontSize: MyApp2.fontSize14,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${Auth2.user!.activeAddress}",
            style: TextStyle(
              fontSize: MyApp2.fontSize14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPaymentCard() {
    final provider = Provider.of<ProviderController>(context, listen: false);
    final cart = Provider.of<CartTextProvider>(context, listen: false);
    final currentProvider = provider.providers
        ?.where((e) => e.id == cart.cart?.cart_items?.firstOrNull?.provider_id)
        .firstOrNull;
    final bool acceptsCash = currentProvider?.acceptsCash == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.payment, size: 16, color: myColor),
              const SizedBox(width: 6),
              Text(
                'Metodo di pagamento',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Payment options
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildPaymentOption(
                  title: 'Carta',
                  value: '1',
                ),
                if (acceptsCash) ...[
                  const SizedBox(width: 10),
                  _buildPaymentOption(
                    title: 'Contanti',
                    value: '0',
                  ),
                ],
                const SizedBox(width: 10),
                _buildPaymentOption(
                  title: 'PayPal',
                  value: '2',
                ),
                // Google Pay - Android only (uses Stripe Checkout)
                if (Platform.isAndroid) ...[
                  const SizedBox(width: 10),
                  _buildPaymentOption(
                    title: 'Google Pay',
                    value: '4',
                  ),
                ],
                // Apple Pay - iOS only
                if (_isApplePayAvailable) ...[
                  const SizedBox(width: 10),
                  _buildPaymentOption(
                    title: 'Apple',
                    value: '3',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String value,
    String? iconPath,
    Widget? iconWidget,
    bool isAvailable = true,
  }) {
    final bool isSelected = paymentMethod == value;
    final bool canSelect = isAvailable;

    // Custom icon widgets for each payment method
    Widget getPaymentIcon() {
      if (iconWidget != null) return iconWidget;

      switch (value) {
        case '0': // Cash
          return Icon(
            Icons.payments_outlined,
            size: 20,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
          );
        case '1': // Credit Card
          return Icon(
            Icons.credit_card,
            size: 20,
            color: isSelected ? const Color(0xFF1976D2) : Colors.grey,
          );
        case '2': // PayPal
          return Image.asset(
            'images/icons/paypal.png',
            height: 20,
            fit: BoxFit.contain,
          );
        case '3': // Apple Pay
          return Icon(
            Icons.apple,
            size: 22,
            color: isSelected ? Colors.black : Colors.grey,
          );
        case '4': // Google Pay
          return Icon(
            Icons.g_mobiledata,
            size: 24,
            color: isSelected ? const Color(0xFF4285F4) : Colors.grey,
          );
        default:
          return iconPath != null
              ? Image.asset(iconPath, fit: BoxFit.contain, height: 20)
              : const Icon(Icons.payment, size: 20);
      }
    }

    return GestureDetector(
      onTap: canSelect
          ? () {
              setState(() {
                paymentMethod = value;
              });
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: canSelect ? 1.0 : 0.4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? myColor.withAlpha(25) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? myColor : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selection indicator
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? myColor : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: myColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              // Icon
              SizedBox(
                height: 24,
                child: Center(child: getPaymentIcon()),
              ),
              const SizedBox(height: 3),
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? myColor : Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Delivery options:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selected_options ??
                          "${AppLocalizations.of(context)?.translate("Handover")}",
                      items: <String>[
                        "${AppLocalizations.of(context)?.translate("Leave")}",
                        "${AppLocalizations.of(context)?.translate("Handover")}",
                        "${AppLocalizations.of(context)?.translate("Neighbor")}",
                        "${AppLocalizations.of(context)?.translate("Drop_off")}"
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selected_options = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Gratuity كسطر واحد + BottomSheet
  Widget _buildGratuityCard(BuildContext context) {
    final currentTip = double.tryParse(selected_gratuity ?? "0") ?? 0.0;

    return InkWell(
      onTap: () => _showGratuitySheet(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppLocalizations.of(context)?.translate("Gratuity") ?? ""}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  currentTip == 0
                      ? '0.00 €'
                      : '${currentTip.toStringAsFixed(2)} €',
                  style: TextStyle(
                    fontSize: MyApp2.fontSize14,
                    color: myColor2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Posate (أدوات الطعام)
  Widget _buildPosateCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant,
                size: 20,
                color: myColor,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: MyApp2.fontSize14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Includere posate monouso',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: needsPosate,
              onChanged: (value) {
                setState(() {
                  needsPosate = value;
                });
              },
              activeColor: myColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showGratuitySheet(BuildContext context) {
    final List<String> options = ['0', '1', '3', '5', '10', '15', '20'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)?.translate("Gratuity") ??
                    'Gratuity',
                style: TextStyle(
                  fontSize: MyApp2.fontSize16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((value) {
                  final isSelected = selected_gratuity == value;
                  return ChoiceChip(
                    label: Text(
                      '$value €',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: myColor,
                    backgroundColor: const Color(0xFFF1F2F6),
                    onSelected: (_) {
                      setState(() {
                        selected_gratuity = value == '0' ? null : value;
                      });
                      Navigator.of(ctx).pop();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Promo Code
  String? _appliedCode;
  bool _promoLoading = false;

  Widget _buildPromoCodeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.discount_outlined, color: myColor, size: 20),
              const SizedBox(width: 8),
              Text('Codice sconto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          if (_appliedCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_appliedCode  -${_promoDiscount.toStringAsFixed(2)} €',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green[700]),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _appliedCode = null;
                        _promoDiscount = 0;
                        _promoController.clear();
                      });
                    },
                    child: Icon(Icons.close, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(fontSize: 14, letterSpacing: 1),
                    decoration: InputDecoration(
                      hintText: 'Inserisci codice',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _promoLoading ? null : _applyPromoCode,
                    child: _promoLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Applica', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _applyPromoCode() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _promoLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$globalUrl/api/apply-coupon'),
        headers: {
          'Accept': 'application/json',
          'Authorization': '${MyApp2.token}',
        },
        body: {'code': code},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _promoDiscount = double.tryParse(data['data']['discount'].toString()) ?? 0;
          _appliedCode = data['data']['code'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['message']} -${_promoDiscount.toStringAsFixed(2)} €'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Codice non valido'),
            backgroundColor: Colors.red[400],
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore di connessione'), duration: Duration(seconds: 2)),
      );
    }

    setState(() => _promoLoading = false);
  }

  // Comment card + sheet
  Widget _buildCommentCard(BuildContext context) {
    final hasComment = _commentController.text.trim().isNotEmpty;

    return InkWell(
      onTap: () => _showCommentSheet(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Commento",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: MyApp2.fontSize14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasComment
                        ? _commentController.text.trim()
                        : "Aggiungi un commento…",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasComment ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Commento",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Scrivi un commento…",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: myColor),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Salva",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalsCard({
    required BuildContext context,
    required double subtotal,
    required double tax,
    required double shipping,
    required double gratuity,
    required double totalBeforePromo,
    required double total,
    required double deliveryDuration,
    required double minOrder,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Totale',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                '${total.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: myColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _totalRow(
            AppLocalizations.of(context)!.translate("subtotal"),
            '${subtotal.toStringAsFixed(2)} €',
          ),
          _totalRow(
            "Importo minimo dell'ordine",
            '${minOrder.toStringAsFixed(2)} €',
          ),
          _totalRow(
            AppLocalizations.of(context)!.translate("shipping"),
            '${shipping.toStringAsFixed(2)} €',
          ),
          _totalRow(
            AppLocalizations.of(context)!.translate("tax"),
            '${tax.toStringAsFixed(2)} €',
          ),
          if (gratuity > 0)
            _totalRow(
              AppLocalizations.of(context)!.translate("Gratuity"),
              '${gratuity.toStringAsFixed(2)} €',
            ),
          if (_promoDiscount > 0)
            _totalRow(
              'Sconto codice',
              '-${_promoDiscount.toStringAsFixed(2)} €',
            ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ======================= BOTTOM BAR & ORDER =======================

  Widget _buildBottomBar(BuildContext context, CartTextProvider cart,
      ProviderController provider, double total,
      {required double subtotal,
      required double tax,
      required double shipping,
      required double gratuity}) {
    // Prevent order if cash is selected but not accepted
    final providerController =
        Provider.of<ProviderController>(context, listen: false);
    final currentProvider = providerController.providers
        ?.where((e) => e.id == cart.cart?.cart_items?.firstOrNull?.provider_id)
        .firstOrNull;
    final bool acceptsCash = currentProvider?.acceptsCash == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Totale: ${total.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: MyApp2.fontSize18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Builder(builder: (_) {
            final addressMissing = false;

            final minOrder = double.tryParse(provider.providers
                        ?.firstWhere(
                          (e) =>
                              e.id ==
                              cart.cart?.cart_items?.firstOrNull?.provider_id,
                          orElse: () => ProviderData(),
                        )
                        .Delivery
                        ?.OrderMin ??
                    "0") ??
                0;

            // Guest check: no token = not registered
            final isGuest = MyApp2.token == null || MyApp2.token!.isEmpty;

            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isGuest ? Colors.orange : (addressMissing ? Colors.orange : myColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: isGuest
                  ? () async {
                      final registered = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const QuickRegister()),
                      );
                      if (registered == true && mounted) {
                        setState(() {});
                      }
                    }
                  : addressMissing
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AddAddress(popAfterSave: true)),
                      );
                      await Auth2.getUserDetails(context);
                      if (!mounted) return;
                      setState(() {});
                    }
                  : () async {

                if (paymentMethod == '0' && !acceptsCash) {
                  Auth2.show(
                      'Il pagamento in contanti non è disponibile per questo negozio. Rivolgiti al cassiere o al responsabile.');
                  return;
                }

                if (minOrder > subtotal) {
                  Auth2.show(
                      "L'importo dell'ordine è inferiore all'importo minimo. Aggiungi altri articoli per procedere.");
                  return;
                }

                if (MyApp2.token == null || MyApp2.token!.isEmpty) {
                  final registered = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const QuickRegister()),
                  );
                  if (registered == true && mounted) setState(() {});
                  return;
                }

                // Apple Pay → Stripe WebView (Apple Pay only)
                if (paymentMethod == "3" && Platform.isIOS) {
                  final providerId = (cart.cart?.cart_items != null &&
                          cart.cart!.cart_items!.isNotEmpty)
                      ? cart.cart!.cart_items!.first.provider_id
                      : null;
                  final transactionId = await _payWithStripe(
                      total: total, providerId: providerId, applePayOnly: true);
                  if (transactionId == null) return;
                  _applePayTransactionId = transactionId;
                  Progress.progressDialogue(context);
                  await OrderPlaceButton(cart, context);
                  return;
                }

                // Google Pay → Chrome Custom Tab with GPay page
                if (paymentMethod == "4" && Platform.isAndroid) {
                  final amountInCents = (total * 100).round();
                  final gpayUrl = Uri.parse('$globalUrl/stripe/gpay?amount=$amountInCents');

                  final completer = Completer<String?>();
                  final appLinks = AppLinks();
                  StreamSubscription? linkSub;

                  linkSub = appLinks.uriLinkStream.listen((Uri uri) async {
                    if (uri.scheme == 'eboro' && uri.host == 'payment') {
                      final sessionId = uri.queryParameters['session_id'];
                      final pi = uri.queryParameters['pi'];
                      if (pi != null && !completer.isCompleted) {
                        completer.complete(pi);
                      } else if (sessionId != null && !completer.isCompleted) {
                        try {
                          final resp = await http.get(Uri.parse(
                              '$globalUrl/stripe/mobile-payment-success?session_id=$sessionId'));
                          if (resp.statusCode == 200) {
                            final data = json.decode(resp.body);
                            completer.complete(data['payment_intent']);
                          } else {
                            completer.complete(null);
                          }
                        } catch (_) {
                          completer.complete(null);
                        }
                      } else if (!completer.isCompleted) {
                        completer.complete(null);
                      }
                      linkSub?.cancel();
                    }
                  });

                  await launchUrl(gpayUrl, mode: LaunchMode.externalApplication);

                  final transactionId = await completer.future
                      .timeout(const Duration(minutes: 5), onTimeout: () => null);
                  linkSub.cancel();

                  if (transactionId == null || !mounted) return;
                  _googlePayTransactionId = transactionId;
                  Progress.progressDialogue(context);
                  await OrderPlaceButton(cart, context);
                  return;
                }

                // Carta → Stripe WebView
                if (paymentMethod == "1") {
                  final providerId = (cart.cart?.cart_items != null &&
                          cart.cart!.cart_items!.isNotEmpty)
                      ? cart.cart!.cart_items!.first.provider_id
                      : null;
                  final transactionId = await _payWithStripe(
                      total: total, providerId: providerId, disableWallets: true);
                  if (transactionId == null) return;
                  _stripeTransactionId = transactionId;
                  Progress.progressDialogue(context);
                  await OrderPlaceButton(cart, context);
                } else {
                  // Cash (0) or PayPal (2)
                  Progress.progressDialogue(context);
                  try {
                    await OrderPlaceButton(cart, context);
                  } catch (_) {
                    try {
                      Navigator.pop(context);
                    } catch (_) {}
                  } finally {
                    if (mounted) {
                      setState(() {
                        inClicked = true;
                      });
                    }
                  }
                }
              },
              child: Text(
                isGuest ? 'Registrati per ordinare' : (addressMissing ? 'Completa dati consegna' : 'Fai ordine'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }),
        ],
      ),
    );
  }

  //Stripe PaymentSheet - دفع آمن بدون إرسال بيانات الكارت مباشرة
  Future<String?> _payWithStripe(
      {required double total, int? providerId, bool disableWallets = false, bool applePayOnly = false}) async {
    try {
      final amountInCents = (total * 100).round();
      String walletParam = '';
      if (applePayOnly) {
        walletParam = '&methods=apple_pay';
      } else if (disableWallets) {
        walletParam = '&wallets=none';
      }
      final url = '$globalUrl/stripe/mobile-payment?amount=$amountInCents$walletParam';

      // استخدام الـ WebViewController المجهز مسبقاً لو الـ URL متطابق
      final preloaded =
          (_preloadedStripeUrl == url && _preloadedStripeController != null)
              ? _preloadedStripeController
              : null;

      final paymentIntentId = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => StripeWebViewPage(
            url: url,
            preloadedController: preloaded,
            hideApplePay: disableWallets,
          ),
        ),
      );

      // إعادة تجهيز controller جديد للمرة القادمة
      _preloadStripeWebView(
          Provider.of<CartTextProvider>(context, listen: false));

      return paymentIntentId;
    } catch (e) {
      Auth2.show("Errore nel pagamento: $e");
      return null;
    }
  }

  String? _applePayTransactionId;
  String? _googlePayTransactionId;


  /// Google Pay native → get token → charge on server
  /// Falls back to Stripe WebView if native fails
  Future<String?> _payWithNativeGpay({required int amountInCents}) async {
    // Try native Google Pay first
    try {
      final payClient = Pay({
        PayProvider.google_pay:
            PaymentConfiguration.fromJsonString(googlePayConfigJson),
      });

      final result = await payClient.showPaymentSelector(
        PayProvider.google_pay,
        [
          PaymentItem(
            label: 'Ordine EBORO',
            amount: (amountInCents / 100).toStringAsFixed(2),
            status: PaymentItemStatus.final_price,
          ),
        ],
      );

      // Extract token from Google Pay result
      final tokenData = result['paymentMethodData']?['tokenizationData']?['token'];
      if (tokenData != null) {
        final tokenJson = json.decode(tokenData);
        final stripeToken = tokenJson['id'];

        if (stripeToken != null) {
          // Send token to server to charge
          final response = await http.post(
            Uri.parse('$globalUrl/api/stripe/charge-gpay'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: json.encode({'token': stripeToken, 'amount': amountInCents}),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true) {
              return data['payment_intent'];
            }
          }
        }
      }
    } catch (e) {
      debugPrint("🔴 Google Pay error: $e");
      if (mounted) {
        Auth2.show("Google Pay error: $e");
      }
      return null;
    }

    return null;
  }

  // Helper method للعرض في الـ Confirmation Dialog
  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> OrderPlaceButton(
      CartTextProvider cart, BuildContext context) async {
    // Block order if guest (no token) — redirect to quick registration
    if (MyApp2.token == null || MyApp2.token!.isEmpty) {
      try { Navigator.pop(context); } catch (_) {}
      final registered = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const QuickRegister()),
      );
      if (registered == true && mounted) {
        // Registered successfully, refresh UI
        setState(() {});
      }
      return;
    }


    // Check if restaurant is open
    final providerController =
        Provider.of<ProviderController>(context, listen: false);
    final currentProvider = providerController.providers
        ?.where((e) => e.id == cart.cart?.cart_items?.firstOrNull?.provider_id)
        .firstOrNull;

    if (currentProvider != null && currentProvider.state != '1') {
      // Restaurant is closed
      String message = "Il ristorante è chiuso";
      if (currentProvider.nextOpeningTime != null) {
        message += ". Apre alle ${currentProvider.nextOpeningTime}";
      }
      try {
        Navigator.pop(context);
      } catch (_) {}
      Auth2.show(message);
      return;
    }

    // Valid payment methods: 0=Cash, 1=Card, 2=PayPal, 3=Apple Pay, 4=Google Pay
    final validPaymentMethods = ['0', '1', '2', '3', '4'];

    if (cart.cart?.cart_items == null || cart.cart!.cart_items!.isEmpty) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Home()),
        (Route<dynamic> route) => false,
      );
    } else if (!validPaymentMethods.contains(paymentMethod)) {
      try {
        Navigator.pop(context);
      } catch (_) {}
      Auth2.show("choose payment method");
    } else {
      if (inClicked) {
        inClicked = false;
        bool success = false;
        try {
          success = await Order2().makeOrder(
            context,
            date: order_at.toUtc().toIso8601String(),
            gratuity: selected_gratuity,
            options: selected_options,
            comment: _commentController.text,
            type: paymentMethod,
            posate: needsPosate,
            transactionId: _stripeTransactionId ?? _applePayTransactionId ?? _googlePayTransactionId,
          );
        } catch (e) {
          try {
            Navigator.pop(context);
          } catch (_) {}
          Auth2.show("Errore: $e");
        } finally {
          // إعادة تمكين الزر وتنظيف transaction IDs في حالة الفشل
          if (mounted && !success) {
            setState(() {
              inClicked = true;
              _stripeTransactionId = null;
              _applePayTransactionId = null;
              _googlePayTransactionId = null;
            });
          }
        }
      } else {
        // الزر معطل (طلب سابق قيد التنفيذ) - إغلاق Progress dialog
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
    }
  }
}
