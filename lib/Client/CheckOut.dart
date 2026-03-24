import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Order.dart';
import 'package:eboro/API/Provider.dart' as prov;
import 'package:eboro/API/Cart.dart' as cartApi;
import 'package:eboro/Client/Home.dart';
import 'package:eboro/Client/SuccessfulOrder.dart';
import 'package:eboro/Client/Location.dart';
import 'package:eboro/Helper/ProductData.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/Widget/CheckOutItem.dart';
import 'package:eboro/main.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pay/pay.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:eboro/Widget/StripeWebViewPage.dart';
import 'package:eboro/Client/MyCart.dart';


class CheckOut extends StatefulWidget {
  @override
  CheckOut2 createState() => CheckOut2();
}

class CheckOut2 extends State<CheckOut> {
  static String? address2, shippi, tax, payment, dateTime;
  double total = 0.00;
  TextEditingController _cardController = new TextEditingController();
  TextEditingController _dateController = new TextEditingController();
  TextEditingController _cvvController = new TextEditingController();
  TextEditingController _gratuityController = new TextEditingController();

  // ✅ GDPR: حفظ بيانات الدفع
  bool _saveCard = false;
  bool _hasSavedCard = false;
  String? _savedCardLast4;

  // ✅ العناصر المرشحة (أكثر 10 منتجات مبيعاً)
  List<ProductData> _topProducts = [];
  bool _loadingTopProducts = true;

  // Apple Pay availability
  bool _isApplePayAvailable = false;

  @override
  initState() {
    super.initState();
    payment = Platform.isAndroid ? '4' : '0';
    if (dateTime == null || dateTime == "null") {
      final now = DateTime.now().add(Duration(hours: 1));
      dateTime =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    }
    _loadSavedCard();
    _loadTopProducts();
    _checkApplePayAvailability();
    postTest();
  }

  Future<void> _checkApplePayAvailability() async {
    if (!Platform.isIOS) return;
    try {
      final payClient = Pay({
        PayProvider.apple_pay: PaymentConfiguration.fromJsonString(
            MyCart2.applePayConfigJson),
      });
      final canPay = await payClient.userCanPay(PayProvider.apple_pay);
      if (mounted) {
        setState(() => _isApplePayAvailable = canPay);
      }
    } catch (_) {}
  }

  Future<void> _loadTopProducts() async {
    try {
      final products = await prov.Provider2.getTopProducts();
      if (mounted) {
        setState(() {
          _topProducts = products.take(10).toList();
          _loadingTopProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTopProducts = false);
    }
  }

  Future<void> _quickAddToCart(ProductData product) async {
    final cart = Provider.of<CartTextProvider>(context, listen: false);
    try {
      await cartApi.Cart().addToCart('', product.id, 1);
      await cart.updateCart();
      if (mounted) {
        // تحديث الإجمالي
        postTest();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} aggiunto al carrello'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  /// تحميل بيانات الكارت المحفوظة
  Future<void> _loadSavedCard() async {
    final prefs = await SharedPreferences.getInstance();
    final card = prefs.getString('saved_card_number');
    final exp = prefs.getString('saved_card_exp');
    if (card != null && card.isNotEmpty && exp != null && exp.isNotEmpty) {
      setState(() {
        _hasSavedCard = true;
        final clean = card.replaceAll(' ', '');
        _savedCardLast4 =
            clean.length >= 4 ? clean.substring(clean.length - 4) : clean;
        _cardController.text = card;
        _dateController.text = exp;
        _saveCard = true;
      });
    }
  }

  /// حفظ بيانات الكارت (بدون CVV للأمان)
  Future<void> _saveCardData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_saveCard &&
        _cardController.text.isNotEmpty &&
        _dateController.text.isNotEmpty) {
      await prefs.setString('saved_card_number', _cardController.text);
      await prefs.setString('saved_card_exp', _dateController.text);
      await prefs.setBool('saved_card_consent', true);
    }
  }

  /// مسح بيانات الكارت المحفوظة
  Future<void> _deleteSavedCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_card_number');
    await prefs.remove('saved_card_exp');
    await prefs.remove('saved_card_consent');
    setState(() {
      _hasSavedCard = false;
      _savedCardLast4 = null;
      _saveCard = false;
      _cardController.clear();
      _dateController.clear();
      _cvvController.clear();
    });
  }

  Future<String?> timeZone({DateTime? date}) async {
    String? dateTimeString;

    /* try {
      // Initialize time zone data
      tzdata.initializeTimeZones();

      // Initialize time zone provider
      await TimeMachine.initialize({'rootBundle': tz.getLocation('Europe/Rome')});

      // Get the time zone for 'Europe/Rome'
      var timezone = await DateTimeZoneProviders.tzdb;
      var italy = timezone['Europe/Rome'];

      // Convert the provided date or the current time to the specified time zone
      var dateTime = date != null
          ? italy.getLocationAt(tz.TZDateTime.from(date, italy)).toDateTimeLocal()
          : italy.getLocationAt(now).toDateTimeLocal();


      // Format the date and time
      dateTimeString = DateFormat("y-M-d H:mm").format(dateTime);
    } catch (error) {
      // Handle the error appropriately, e.g., throw an exception or return a default value
      dateTimeString = 'Error occurred';
    }*/

    return dateTimeString;
  }

  /// Calcola il subtotale applicando gli sconti dei prodotti (come MyCart)
  double _calculateSubtotal(CartTextProvider cart) {
    final items = cart.cart?.cart_items ?? [];
    double subtotal = 0.0;

    for (final it in items) {
      try {
        final int qty = it.qty ?? 1;
        double productPrice = it.product_price ?? 0.0;

        // Applica lo sconto se il prodotto ha un'offerta
        if (prov.Provider2.product != null) {
          try {
            final product = prov.Provider2.product!.firstWhere(
              (p) => p.id == it.product_id,
            );
            final offer = product.offer;
            if (offer != null &&
                offer.offer_price != null &&
                offer.offer_price.toString().trim().isNotEmpty &&
                offer.offer_price.toString() != '0' &&
                offer.offer_price.toString() != '0.0') {
              final double offerValue =
                  double.tryParse(offer.offer_price?.toString() ?? '0') ?? 0.0;
              if (offerValue > 0) {
                productPrice = productPrice - offerValue;
              }
            }
          } catch (_) {}
        }

        double saucesPrice = 0.0;
        for (final s in it.sauces ?? []) {
          saucesPrice += s.price ?? 0.0;
        }

        double extrasPrice = 0.0;
        for (final e in it.extras ?? []) {
          extrasPrice += e.price ?? 0.0;
        }

        subtotal += (productPrice + saucesPrice + extrasPrice) * qty;
      } catch (_) {}
    }

    return subtotal;
  }

  postTest() async {
    final Cart = Provider.of<CartTextProvider>(context, listen: false);
    // dateTime = await timeZond();
    setState(() {
      dateTime = dateTime;
      address2 = Auth2.user!.activeAddress.toString();
      final double subtotal = _calculateSubtotal(Cart);
      if (SetLocation2.ship!.contains('NaN')) {
        shippi = "Unknown";
        tax = SetLocation2.tax.toString() + " %";
        total =
            (double.parse(SetLocation2.tax ?? "0") * subtotal) +
                subtotal;
      } else {
        tax = SetLocation2.tax.toString() + " %";
        shippi = SetLocation2.ship.toString() + " €";
        total = double.parse(SetLocation2.ship ?? "0") +
            (double.parse(SetLocation2.tax ?? "0") * subtotal) +
            subtotal;
      }
    });
  }

  bool inClicked = true;

  @override
  Widget build(BuildContext context) {
    final Cart = Provider.of<CartTextProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        title: Text('Checkout',
            style: TextStyle(color: Colors.white, fontSize: MyApp2.H! * .03)),
        iconTheme: new IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
        child: ListView(
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    child: Text(
                      AppLocalizations.of(context)!
                          .translate("shippingaddress"),
                      textAlign: TextAlign.start, // has impact
                      style: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Colors.black38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  child: Row(
                    children: [
                      Text(AppLocalizations.of(context)!.translate("edit"),
                          style: TextStyle(
                              color: myColor, fontSize: MyApp2.fontSize18)),
                      Icon(
                        Icons.edit,
                        color: myColor,
                        size: MyApp2.fontSize22,
                      ),
                    ],
                  ),
                  onTap: () {
                    SetLocation(rout: "home");
                  },
                )
              ],
            ),
            SizedBox(
              height: 5,
            ),
            Container(
              width: MediaQuery.of(context).size.width * .6,
              child: GestureDetector(
                child: Text(
                  Auth2.user!.activeAddress.toString(),
                  textAlign: TextAlign.start, // has impact
                  style: TextStyle(
                    fontSize: MyApp2.fontSize14,
                    color: myColor2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * .6,
              child: GestureDetector(
                child: Text(
                  AppLocalizations.of(context)!.translate("tax") +
                      " : " +
                      tax.toString(),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: MyApp2.fontSize14,
                    color: myColor2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * .6,
              child: GestureDetector(
                child: Text(
                  AppLocalizations.of(context)!.translate("shipping") +
                      " : " +
                      shippi.toString(),
                  textAlign: TextAlign.start, // has impact
                  style: TextStyle(
                    fontSize: MyApp2.fontSize14,
                    color: myColor2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * .6,
              child: GestureDetector(
                child: Text(
                  AppLocalizations.of(context)!.translate("deliverytime") +
                      " : " +
                      double.parse(SetLocation2.duration.toString())
                          .toStringAsFixed(0) +
                      ' min',
                  textAlign: TextAlign.start, // has impact
                  style: TextStyle(
                    fontSize: MyApp2.fontSize14,
                    color: myColor2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Divider(),
            Container(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                child: Text(
                  AppLocalizations.of(context)!.translate("yourorder") +
                      ' (${_calculateSubtotal(Cart).toStringAsFixed(2)} €)',
                  textAlign: TextAlign.start, // has impact
                  style: TextStyle(
                    fontSize: MyApp2.fontSize16,
                    color: myColor2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            CheckOutItem(),
            SizedBox(
              height: 10,
            ),
            // ✅ العناصر المرشحة — أكثر 10 منتجات مبيعاً في الشهر الماضي
            if (_loadingTopProducts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else if (_topProducts.isNotEmpty) ...[
              Divider(),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: myColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Consigliati per te',
                      style: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Colors.black38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _topProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final product = _topProducts[index];
                    return _buildTopProductCard(product);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            Divider(),
            Column(children: [
              Container(
                padding: const EdgeInsets.only(bottom: 5),
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.translate("date"),
                  textAlign: TextAlign.start, // has impact
                  style: TextStyle(
                    fontSize: MyApp2.fontSize16,
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                width: MediaQuery.of(context).size.width,
                child: GestureDetector(
                  onTap: () {
                    DatePicker.showDateTimePicker(context,
                        showTitleActions: true,
                        minTime: DateTime.now().add(const Duration(hours: 1)),
                        maxTime: DateTime.now().add(const Duration(days: 1)),
                        onConfirm: (date) async {
                      // تحديث التاريخ بالقيمة المختارة
                      setState(() {
                        dateTime =
                            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                      });
                    }, locale: LocaleType.en);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: Colors.grey,
                        size: 20,
                      ),
                      Text(
                        ' ${dateTime.toString()}',
                        style: TextStyle(
                          fontSize: MyApp2.fontSize14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey,
                    width: .5,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ]),
            SizedBox(
              height: 10,
            ),
            Column(
              children: <Widget>[
                Container(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    child: Text(
                      AppLocalizations.of(context)!.translate("paymentmethod"),
                      textAlign: TextAlign.start, // has impact
                      style: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Colors.black38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // اختيار طريقة الدفع
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Android: only Google Pay
                    if (Platform.isAndroid) ...[  
                      _buildPaymentOption(
                        value: "4",
                        icon: Icons.g_mobiledata,
                        label: 'Google Pay',
                        isGooglePay: true,
                      ),
                    ] else ...[
                      // Carta (Credit Card)
                      _buildPaymentOption(
                        value: "1",
                        icon: Icons.credit_card,
                        label: 'Carta',
                      ),
                      // Contanti (Cash)
                      _buildPaymentOption(
                        value: "0",
                        icon: Icons.money,
                        label: 'Contanti',
                      ),
                      // PayPal
                      _buildPaymentOption(
                        value: "2",
                        icon: Icons.payment,
                        label: 'PayPal',
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.only(top: 15),
                  child: (payment == "1") ? visa(context) : Container(),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  child: GestureDetector(
                    child: Text(
                      AppLocalizations.of(context)!.translate("total") +
                          " : " +
                          total.toStringAsFixed(2) +
                          " €",
                      textAlign: TextAlign.start, // has impact
                      style: TextStyle(
                        fontSize: MyApp2.fontSize18,
                        color: myColor2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * .4,
                  child: MaterialButton(
                    child: Text(
                      AppLocalizations.of(context)!.translate("placeorder"),
                      style: TextStyle(
                        fontSize: MyApp2.fontSize18,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.only(top: 12.5, bottom: 12.5),
                    color: myColor,
                    textColor: Colors.white,
                    onPressed: () async {
                      if (Cart.cart!.cart_items!.isEmpty) {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => Home()),
                            (Route<dynamic> route) => false);
                      } else if (payment != '0' &&
                          payment != '1' &&
                          payment != '2' &&
                          payment != '3' &&
                          payment != '4') {
                        Auth2.show("choose payment method");
                      } else if (payment == '1' &&
                          (_cardController.text.isEmpty ||
                              _cvvController.text.isEmpty ||
                              _dateController.text.isEmpty)) {
                        Auth2.show("complete payment information");
                      } else if (dateTime == null) {
                        Auth2.show("choose order date");
                      } else {
                        // ===== إضافة Confirmation Dialog =====
                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            String paymentMethodText = payment == '0'
                                ? 'Contanti'
                                : payment == '1'
                                    ? 'Carta'
                                    : payment == '2'
                                        ? 'PayPal'
                                        : payment == '3'
                                            ? 'Apple'
                                            : 'Google Pay';
                            String cardDisplay = '';
                            if (payment == '1' &&
                                _cardController.text.isNotEmpty) {
                              final cardNum =
                                  _cardController.text.replaceAll(' ', '');
                              cardDisplay = cardNum.length >= 4
                                  ? '\n**** ${cardNum.substring(cardNum.length - 4)}'
                                  : '';
                            }

                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    payment == '0'
                                        ? Icons.money
                                        : payment == '1'
                                            ? Icons.credit_card
                                            : payment == '3'
                                                ? Icons.apple
                                                : payment == '4'
                                                ? Icons.g_mobiledata
                                                : Icons.payment,
                                    color: myColor,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Conferma ordine',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Stai per confermare l\'ordine:',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Totale:',
                                                style: TextStyle(fontSize: 14)),
                                            Text(
                                              '${total.toStringAsFixed(2)} €',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Pagamento:',
                                                style: TextStyle(fontSize: 14)),
                                            Text(
                                              '$paymentMethodText$cardDisplay',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (payment == '1') ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded,
                                              color: Colors.orange.shade700,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'L\'importo sarà addebitato immediatamente',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: Text(
                                    'Annulla',
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: myColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: Text(
                                    payment == '0'
                                        ? 'Conferma ordine'
                                        : payment == '1'
                                            ? 'Conferma pagamento'
                                            : payment == '3'
                                                ? 'Paga con Apple'
                                                : payment == '4'
                                                    ? 'Paga con Google Pay'
                                                    : 'Conferma ordine',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        // لو المستخدم ضغط Annulla، نوقف
                        if (confirmed != true) return;

                        // لو confirmed، نكمل
                        if (inClicked) {
                          inClicked = false;

                          // جمع كل التعليقات من CheckOutItem
                          String allComments = CheckOutItem2.comments
                              .where((c) => c != null && c.isNotEmpty)
                              .join(', ');

                          String? transactionId;

                          final amountInCents = (total * 100).round();

                          // Apple Pay → Stripe WebView (Apple Pay only)
                          if (payment == '3' && Platform.isIOS) {
                            final stripeUrl = '$globalUrl/stripe/mobile-payment?amount=$amountInCents&methods=apple_pay';

                            transactionId = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StripeWebViewPage(url: stripeUrl),
                              ),
                            );

                            if (transactionId == null || transactionId.isEmpty) {
                              inClicked = true;
                              return;
                            }
                          }
                          // Google Pay → Native
                          else if (payment == '4' && Platform.isAndroid) {
                            try {
                              final payClient = Pay({
                                PayProvider.google_pay: PaymentConfiguration.fromJsonString(
                                    MyCart2.googlePayConfigJson),
                              });
                              final result = await payClient.showPaymentSelector(
                                PayProvider.google_pay,
                                [PaymentItem(label: 'Ordine EBORO', amount: (amountInCents / 100).toStringAsFixed(2), status: PaymentItemStatus.final_price)],
                              );
                              final tokenData = result['paymentMethodData']?['tokenizationData']?['token'];
                              if (tokenData != null) {
                                final tokenJson = json.decode(tokenData);
                                final stripeToken = tokenJson['id'];
                                if (stripeToken != null) {
                                  final resp = await http.post(
                                    Uri.parse('$globalUrl/api/stripe/charge-gpay'),
                                    headers: {'Content-Type': 'application/json'},
                                    body: json.encode({'token': stripeToken, 'amount': amountInCents}),
                                  );
                                  if (resp.statusCode == 200) {
                                    final data = json.decode(resp.body);
                                    if (data['success'] == true) transactionId = data['payment_intent'];
                                  }
                                }
                              }
                            } catch (_) {}
                          }
                          // Carta → Stripe WebView (wallets disabled - card only)
                          else if (payment == '1') {
                            final stripeUrl = '$globalUrl/stripe/mobile-payment?amount=$amountInCents&wallets=none';

                            transactionId = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StripeWebViewPage(url: stripeUrl, hideApplePay: true),
                              ),
                            );

                            if (transactionId == null || transactionId.isEmpty) {
                              // User cancelled payment
                              inClicked = true;
                              return;
                            }
                          }

                          Progress.progressDialogue(context);

                          bool success = await Order2().makeOrder(context,
                              card: _cardController.text,
                              cvv: _cvvController.text,
                              exp: _dateController.text,
                              date: dateTime,
                              type: payment,
                              comment:
                                  allComments.isNotEmpty ? allComments : "",
                              gratuity: _gratuityController.text.isNotEmpty
                                  ? _gratuityController.text
                                  : "",
                              transactionId: transactionId,
                              options: "");

                          if (success) {
                            // ✅ GDPR: حفظ أو مسح بيانات الكارت حسب اختيار المستخدم
                            if (payment == '1' && _saveCard) {
                              await _saveCardData();
                            } else if (payment == '1' && !_saveCard) {
                              await _deleteSavedCard();
                            }
                          } else {
                            // إذا فشل الطلب، أعد تفعيل الزر
                            inClicked = true;
                          }
                        } else {
                        }
                      }
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ✅ كارت منتج مرشح
  Widget _buildTopProductCard(ProductData product) {
    final imageUrl = product.image;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final price =
        double.tryParse(product.price ?? '0')?.toStringAsFixed(2) ?? '0.00';

    return GestureDetector(
      onTap: () => _quickAddToCart(product),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      height: 60,
                      width: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 60,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                    )
                  : Container(
                      height: 60,
                      color: Colors.grey.shade100,
                      child: const Center(
                          child: Icon(Icons.fastfood, color: Colors.grey)),
                    ),
            ),
            // اسم المنتج + سعر + زر إضافة
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$price €',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: myColor),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: myColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// بناء خيار الدفع
  Widget _buildPaymentOption({
    required String value,
    required IconData icon,
    required String label,
    bool isGooglePay = false,
    bool isApplePay = false,
  }) {
    final isSelected = payment == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          payment = value;
        });
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 56) / 2,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? myColor.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? myColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGooglePay) ...[
              Image.asset(
                'images/icons/google_pay.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.g_mobiledata,
                  color: isSelected ? myColor : Colors.grey,
                  size: 24,
                ),
              ),
            ] else if (isApplePay) ...[
              Icon(
                Icons.apple,
                color: isSelected ? myColor : Colors.black,
                size: 24,
              ),
            ] else ...[
              Icon(
                icon,
                color: isSelected ? myColor : Colors.grey,
                size: 24,
              ),
            ],
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: MyApp2.fontSize14,
                  color: isSelected ? myColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget visa(BuildContext context) {
    return Container(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        // ✅ بانر الكارت المحفوظ
        if (_hasSavedCard && _savedCardLast4 != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.credit_card, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Carta salvata **** $_savedCardLast4',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: _deleteSavedCard,
                  child: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 20),
                ),
              ],
            ),
          ),

        Container(
          width: MediaQuery.of(context).size.width,
          child: TextField(
            controller: _cardController,
            style: TextStyle(fontSize: MyApp2.fontSize14, color: Colors.grey),
            keyboardType: TextInputType.number,
            inputFormatters: [
              CreditCardNumberInputFormatter(),
            ],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.translate("cardnumber"),
              labelStyle: TextStyle(
                fontSize: MyApp2.fontSize14,
                color: Color(0xFFCBCBCB),
              ),
              contentPadding:
                  new EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCBCBCB), width: 0.5),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width * .45,
              child: TextField(
                controller: _dateController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CreditCardExpirationDateFormatter(),
                ],
                style:
                    TextStyle(fontSize: MyApp2.fontSize14, color: Colors.grey),
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.translate("expirationdate"),
                  labelStyle: TextStyle(
                    fontSize: MyApp2.fontSize14,
                    color: Color(0xFFCBCBCB),
                  ),
                  contentPadding:
                      new EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFFCBCBCB), width: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * .45,
              child: TextField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CreditCardCvcInputFormatter(),
                ],
                style:
                    TextStyle(fontSize: MyApp2.fontSize14, color: Colors.grey),
                decoration: InputDecoration(
                  labelText: 'CVV',
                  labelStyle: TextStyle(
                    fontSize: MyApp2.fontSize14,
                    color: Color(0xFFCBCBCB),
                  ),
                  contentPadding:
                      new EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFFCBCBCB), width: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ),
        // ✅ GDPR: خيار حفظ بيانات الكارت
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _saveCard = !_saveCard),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  _saveCard ? myColor.withOpacity(0.06) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _saveCard ? myColor.withOpacity(0.3) : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _saveCard,
                    activeColor: myColor,
                    onChanged: (v) => setState(() => _saveCard = v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salva carta per acquisti futuri',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ai sensi del GDPR, i dati saranno salvati in modo sicuro sul tuo dispositivo. Il CVV non verrà mai memorizzato.',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}

class WebViewClass extends StatefulWidget {
  final String? link;
  WebViewClass({Key? key, this.link}) : super(key: key);
  @override
  _WebViewClassState createState() => _WebViewClassState();
}

class _WebViewClassState extends State<WebViewClass> {
  late final WebViewController _controller;
  bool _handled = false;

  void _checkUrl(String url) {
    if (_handled) return;
    if (!mounted) return;
    if (url.contains('payment-success')) {
      _handled = true;
      // تفريغ السلة بدون Progress dialog لتجنب crash
      try {
        final cart = Provider.of<CartTextProvider>(context, listen: false);
        cart.updateCart(); // تحديث السلة بدون dialog
      } catch (_) {}
      // الانتقال لصفحة النجاح
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => SuccessfulOrder()),
          (route) => false,
        );
      }
    } else if (url.contains('cancel-payment')) {
      _handled = true;
      // Payment cancelled
      // Clear cache عند الرجوع من PayPal لتحديث البيانات
      prov.Provider2.clearProvidersCache();
      // إرجاع فوري بدون تأخير
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Page finished
            _checkUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Navigation request
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            _checkUrl(change.url ?? '');
          },
        ),
      )
      ..loadRequest(Uri.parse('${widget.link}'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('PayPal'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // User pressed close
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
          ],
        ),
      ),
    );
  }
}
