import 'package:eboro/API/Offer.dart';
import 'package:eboro/Helper/OfferData.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class MyOffers extends StatefulWidget {
  const MyOffers({Key? key}) : super(key: key);

  @override
  State<MyOffers> createState() => _MyOffersState();
}

class _MyOffersState extends State<MyOffers> {
  List<OfferData> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _loading = true);
    final result = await OfferAPI.getActiveOffers();
    if (mounted) {
      setState(() {
        _offers = result ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final title = loc?.translate("Offers") ?? "Offerte";

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: myColor,
          centerTitle: true,
          title: Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: MyApp2.H! * .03),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _offers.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadOffers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _offers.length,
                      itemBuilder: (context, index) =>
                          _buildOfferCard(_offers[index]),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.translate("Offers") ?? "Offerte",
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(OfferData offer) {
    final loc = AppLocalizations.of(context);

    // Determine offer label and icon
    String label;
    IconData icon;
    Color badgeColor;

    if (offer.isFreeDelivery) {
      label = loc?.translate("Free_Delivery") ?? "Consegna gratuita";
      icon = Icons.delivery_dining;
      badgeColor = const Color(0xFF4CAF50);
    } else if (offer.isTwoForOne) {
      label = "2x1";
      icon = Icons.card_giftcard;
      badgeColor = const Color(0xFFFF9800);
    } else if (offer.isDiscount) {
      label = loc?.translate("promocode") ?? "Sconto";
      icon = Icons.percent;
      badgeColor = const Color(0xFFC12732);
    } else {
      label = loc?.translate("Offers") ?? "Offerta";
      icon = Icons.local_offer;
      badgeColor = const Color(0xFF2196F3);
    }

    // Build value text
    String valueText = "";
    if (offer.offer_value != null && offer.offer_value!.isNotEmpty) {
      if (offer.isDiscount) {
        valueText = "${offer.offer_value}%";
      } else {
        valueText = offer.offer_value!;
      }
    }
    if (offer.fixed_discount_value != null && offer.fixed_discount_value! > 0) {
      valueText = "-${offer.fixed_discount_value!.toStringAsFixed(2)}€";
    }

    // Min order text
    String? minOrderText;
    if (offer.min_order_amount != null && offer.min_order_amount! > 0) {
      minOrderText = "Min. ${offer.min_order_amount!.toStringAsFixed(2)}€";
    } else if (offer.min_spend != null && offer.min_spend! > 0) {
      minOrderText = "Min. ${offer.min_spend!.toStringAsFixed(2)}€";
    }

    // Code text
    String? codeText;
    if (offer.code != null && offer.code!.isNotEmpty) {
      codeText = offer.code;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: badgeColor, size: 28),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type label
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Value
                  if (valueText.isNotEmpty)
                    Text(
                      valueText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  // Gift product for 2x1
                  if (offer.hasGiftProduct)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "+ ${offer.getGiftProductName(MyApp2.apiLang ?? 'it')}",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  // Min order
                  if (minOrderText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        minOrderText,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  // Code
                  if (codeText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          codeText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
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
  }
}
