import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/Helper/OfferData.dart';
import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProviderCard extends StatelessWidget {
  final ProviderData eProvider;
  final ProviderController providerController;
  final CartTextProvider cart;
  final String Function(OfferData) buildOfferText;

  const ProviderCard({
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
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
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
    final bool hasRealDiscount = hasOffer;

    // New store (last 30 days)
    bool isNewStore = false;
    if (eProvider.created_at != null) {
      try {
        final createdDate = safeDateParse(eProvider.created_at!);
        final now = DateTime.now();
        final daysSinceCreated = now.difference(createdDate).inDays;
        isNewStore = daysSinceCreated <= 30 && daysSinceCreated >= 0;
      } catch (_) {}
    }

    final favorites = providerController.Favorites ?? [];
    final bool isFav = favorites
            .firstWhereOrNull((item) => eProvider.id == item.provider!.id) !=
        null;

    final String orderMin =
        "${eProvider.Delivery?.OrderMin?.toString() ?? '--'} €";
    final String distanceRaw = eProvider.Delivery?.Distance?.toString() ?? '';
    final double? distanceVal = double.tryParse(distanceRaw);
    final String distance = distanceVal != null
        ? "${distanceVal.toStringAsFixed(1)} km"
        : '';

    final String shippingRaw = eProvider.Delivery?.shipping?.toString() ?? '';
    final String shipping = shippingRaw.isNotEmpty ? "$shippingRaw €" : '';

    final String duration = eProvider.Delivery?.Duration?.toString() ?? '';

    String rateValue = eProvider.rateRatio?.toString() ?? '0';
    if (rateValue == 'null' || rateValue.isEmpty) {
      rateValue = '0';
    }
    final String rate = "$rateValue%";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
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
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- IMAGE SECTION --------
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: fixImageUrl(eProvider.logo.toString()),
                          useOldImageOnUrlChange: true,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          memCacheHeight: 650,
                          memCacheWidth: 1200,
                          maxHeightDiskCache: 900,
                          maxWidthDiskCache: 1600,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Center(
                            child: SizedBox(
                              height: 26,
                              width: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: downloadProgress.progress,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.store,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      // Offer badge
                      if (hasRealDiscount)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFD32F2F),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              buildOfferText(displayOffer),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Closed badge
                      if (isClosed)
                        Positioned(
                          top: hasRealDiscount ? 50 : 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade700,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              eProvider.nextOpeningTime != null
                                  ? "Aperto ${eProvider.nextOpeningTime}"
                                  : "Chiuso",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // New badge
                      if (isNewStore && !isClosed)
                        Positioned(
                          top: hasRealDiscount ? 50 : 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4CAF50),
                                  Color(0xFF2E7D32),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fiber_new,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "NUOVO",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  // -------- TEXT SECTION --------
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eProvider.name?.toString() ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _infoItem(Icons.star_rounded, rate, Colors.amber),
                            if (distance.isNotEmpty)
                              _infoItem(Icons.location_on_outlined, distance, Colors.grey[700]!),
                            _infoItem(Icons.receipt_outlined, orderMin, Colors.grey[700]!),
                            if (shipping.isNotEmpty)
                              _infoItem(Icons.delivery_dining_outlined, shipping, Colors.grey[700]!),
                            if (duration.isNotEmpty)
                              _infoItem(Icons.access_time_outlined, duration, Colors.grey[700]!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------- Favorite button --------
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await providerController.toggleFavorite(eProvider, context);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isFav
                      ? FontAwesomeIcons.heartCircleMinus
                      : FontAwesomeIcons.heartCircleCheck,
                  color: isFav ? Colors.red : myColor,
                  size: MyApp2.W! * .055,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
