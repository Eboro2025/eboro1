import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/Helper/DailySpecialData.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/Providers/ClickProvider.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:flutter/material.dart';

class DailySpecialCard extends StatelessWidget {
  final DailySpecialData special;
  final String lang;
  final ProviderController providerController;
  final CartTextProvider cart;

  const DailySpecialCard({
    super.key,
    required this.special,
    required this.lang,
    required this.providerController,
    required this.cart,
  });

  Widget _deliveryChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final productName = special.getProductName(lang);
    final providerName = special.providerName ?? '';
    final hasDiscount = special.hasDiscount;
    final imageUrl = special.productImage != null
        ? fixImageUrl(special.productImage!)
        : null;
    final logoUrl = special.providerLogo != null
        ? fixImageUrl(special.providerLogo!)
        : null;

    return GestureDetector(
      onTap: () {
        if (special.providerId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClickProvider(
                providerID: special.providerId,
                name: providerName,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant header (logo + name)
              Container(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.06),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: logoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: logoUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: const Color(0xFF6C5CE7).withOpacity(0.15),
                                  child: const Icon(Icons.store, size: 18, color: Color(0xFF6C5CE7)),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF6C5CE7).withOpacity(0.15),
                                child: const Icon(Icons.store, size: 18, color: Color(0xFF6C5CE7)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        providerName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF6C5CE7)),
                  ],
                ),
              ),
              // Dish info row
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 55,
                          height: 55,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (imageUrl != null)
                                CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheHeight: 150,
                                  errorWidget: (_, __, ___) => Container(
                                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                    child: const Icon(Icons.restaurant_menu, color: Color(0xFF6C5CE7), size: 24),
                                  ),
                                )
                              else
                                Container(
                                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                  child: const Icon(Icons.restaurant_menu, color: Color(0xFF6C5CE7), size: 24),
                                ),
                              if (hasDiscount)
                                Positioned(
                                  top: 3,
                                  right: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE17055),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "-${special.discountPercentage}%",
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (hasDiscount && special.originalPrice != null)
                                  Text(
                                    "€${special.originalPrice!.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                if (hasDiscount && special.originalPrice != null)
                                  const SizedBox(width: 4),
                                if (special.displayPrice > 0)
                                  Text(
                                    "€${special.displayPrice.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6C5CE7),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (special.productId != null)
                              SizedBox(
                                height: 28,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await cart.addCartItem(
                                      null,
                                      special.productId,
                                      1,
                                      providerId: special.providerId,
                                      context: context,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("$productName aggiunto al carrello"),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add_shopping_cart, size: 14),
                                  label: const Text("Ordina", style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C5CE7),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // بيانات التوصيل من المحل (المسافة، السعر، الوقت، الحد الأدنى)
              if (special.delivery != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (special.delivery!.Distance != null && special.delivery!.Distance!.isNotEmpty)
                        _deliveryChip(Icons.location_on_outlined,
                            "${double.tryParse(special.delivery!.Distance!)?.toStringAsFixed(1) ?? special.delivery!.Distance} km"),
                      if (special.delivery!.shipping != null && special.delivery!.shipping!.isNotEmpty)
                        _deliveryChip(Icons.delivery_dining_outlined,
                            "${special.delivery!.shipping} €"),
                      if (special.delivery!.Duration != null && special.delivery!.Duration!.isNotEmpty)
                        _deliveryChip(Icons.access_time_outlined,
                            special.delivery!.Duration!),
                      if (special.delivery!.OrderMin != null && special.delivery!.OrderMin!.isNotEmpty)
                        _deliveryChip(Icons.receipt_outlined,
                            "${special.delivery!.OrderMin} €"),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
