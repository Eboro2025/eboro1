import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/Helper/OfferData.dart';
import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:flutter/material.dart';

class HorizontalProviderCard extends StatelessWidget {
  final ProviderData eProvider;
  final ProviderController providerController;
  final CartTextProvider cart;
  final String Function(OfferData) buildOfferText;

  const HorizontalProviderCard({
    super.key,
    required this.eProvider,
    required this.providerController,
    required this.cart,
    required this.buildOfferText,
  });

  Widget _infoItem(IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isClosed = eProvider.state == '0';
    final OfferData? displayOffer = eProvider.offer;
    final bool hasOffer = displayOffer != null;

    String rawDuration = eProvider.Delivery?.Duration?.toString() ?? '--';
    rawDuration = rawDuration.replaceAll(RegExp(r'\s*mins?\b', caseSensitive: false), '').trim();
    final String time = "$rawDuration min";
    final String shipping = "${eProvider.Delivery?.shipping?.toString() ?? '--'} €";

    final String distanceRaw = eProvider.Delivery?.Distance?.toString() ?? '';
    final double? distanceVal = double.tryParse(distanceRaw);
    final String distance = distanceVal != null
        ? "${distanceVal.toStringAsFixed(1)} km"
        : '';

    String rateValue = eProvider.rateRatio?.toString() ?? '0';
    if (rateValue == 'null' || rateValue.isEmpty) rateValue = '0';

    return GestureDetector(
      onTap: () async {
        final userEmail = Auth2.user?.email ?? "";
        final cartItemsEmpty = cart.cart?.cart_items?.isEmpty ?? true;

        if (userEmail == "info@eboro.com" || cartItemsEmpty) {
          await providerController.updateProduct(eProvider, context, true);
        } else {
          cart.restCartItem(context);
          cart.cart?.cart_items?.clear();
          await providerController.updateProduct(eProvider, context, true);
        }
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with offer badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: fixImageUrl(eProvider.logo.toString()),
                    height: 120,
                    width: 280,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.store, color: Colors.grey),
                    ),
                  ),
                ),
                // Offer badge
                if (hasOffer)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      constraints: const BoxConstraints(maxWidth: 150),
                      decoration: BoxDecoration(
                        color: displayOffer.isTwoForOne ? Colors.deepOrange : const Color(0xFF00CCBC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            displayOffer.isTwoForOne ? Icons.card_giftcard : Icons.local_offer,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              buildOfferText(displayOffer),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Closed overlay
                if (isClosed)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Center(
                        child: Text(
                          'Chiuso',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eProvider.name ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoItem(Icons.star, rateValue, Colors.amber),
                      if (distance.isNotEmpty)
                        _infoItem(Icons.location_on_outlined, distance, Colors.grey),
                      _infoItem(Icons.delivery_dining, shipping, Colors.grey),
                      _infoItem(Icons.access_time, time, Colors.grey),
                    ],
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
