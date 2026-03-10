import 'dart:convert';
import 'package:eboro/main.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/Widget/ProductDetails.dart';
import 'package:eboro/API/Provider.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final bool compact;

  const ProductCard({Key? key, required this.product, this.compact = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final image = product.image ?? product.photo ?? '';
    final name = product.name ?? '';
    final price = product.price ?? 0;
    final hasOffer = product.offer != null;

    return GestureDetector(
      onTap: () {
        // Ensure the product exists in Provider2.product before navigating
        if (Provider2.product == null) {
          Provider2.product = [product];
        } else if (!Provider2.product!.any((p) => p.id == product.id)) {
          Provider2.product!.add(product);
        }

        // Open product details page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ProductDetails(productID: product.id),
          ),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image != ''
                    ? Image.network(fixImageUrl(image),
                        width: compact ? 60 : 80,
                        height: compact ? 60 : 80,
                        fit: BoxFit.cover)
                    : Container(
                        width: compact ? 60 : 80,
                        height: compact ? 60 : 80,
                        color: Colors.grey[200]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: MyApp2.fontSize14,
                            fontWeight: FontWeight.w600,
                            color: myColor2)),
                    const SizedBox(height: 6),
                    // Display each group separately with its title
                    // Display the Sauces group
                    if (product.sauces != null &&
                        product.sauces.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salse:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          for (var sauce in product.sauces)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 2, left: 8),
                              child: Text(
                                '• ${sauce.name}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Display each additions group separately
                    if (product.additions != null &&
                        product.additions.toString().trim().isNotEmpty)
                      ...(() {
                        try {
                          final parsed =
                              jsonDecode(product.additions.toString());
                          final List<Widget> groupWidgets = [];

                          if (parsed is List) {
                            for (var group in parsed) {
                              final groupName =
                                  group['title'] ?? group['name'] ?? 'Opzioni';
                              groupWidgets.add(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$groupName:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Display group items if they exist
                                    if (group['items'] != null &&
                                        group['items'] is List)
                                      for (var item in group['items'])
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 2, left: 8),
                                          child: Text(
                                            '• ${item['name'] ?? item}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              );
                            }
                          }
                          return groupWidgets;
                        } catch (e) {
                          return <Widget>[];
                        }
                      })(),
                    Row(
                      children: [
                        Text('$price €',
                            style: TextStyle(
                                fontSize: MyApp2.fontSize14, color: myColor2)),
                        if (hasOffer) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            constraints: const BoxConstraints(maxWidth: 140),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getOfferColors(product.offer?.offer_type),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isTwoForOne(product.offer?.offer_type)
                                      ? Icons.card_giftcard
                                      : Icons.local_offer,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _getOfferText(product.offer),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isTwoForOne(String? offerType) {
    return offerType == 'two_for_one' ||
        offerType == 'one_plus_one' ||
        offerType == 'two_for_one_free_delivery';
  }

  List<Color> _getOfferColors(String? offerType) {
    if (_isTwoForOne(offerType)) {
      return [Colors.deepOrange, Colors.orange.shade700];
    }
    if (offerType == 'free_delivery') {
      return [const Color(0xFF00CCBC), const Color(0xFF00A89D)];
    }
    return [const Color(0xFFE43945), const Color(0xFFC12732)];
  }

  String _getOfferText(dynamic offer) {
    if (offer == null) return 'OFFER';

    final offerType = offer.offer_type;
    final List<String> parts = [];

    // Check if it's a discount offer
    if (offerType == 'discount' || offerType == 'fixed_discount') {
      parts.add('-${offer.offer_value ?? offer.value ?? 25}%');
    }

    // Check if it's a 2×1 or 1+1 offer
    if (_isTwoForOne(offerType)) {
      if (offerType == 'one_plus_one') {
        parts.add('1+1');
      } else {
        // Check if gift product info is available
        final giftName = offer.giftProductName ??
            offer.giftProductNameIt ??
            (offer.gift_product != null ? offer.gift_product['name'] : null);

        if (giftName != null && giftName.toString().isNotEmpty) {
          parts.add('2×1 + $giftName');
        } else {
          parts.add('2×1');
        }
      }
    }

    // Check if free delivery is included
    if (offerType == 'free_delivery' || offerType == 'two_for_one_free_delivery') {
      parts.add('fs');
    }

    if (parts.isEmpty) {
      return 'OFFER';
    }

    return parts.join(' ');
  }
}
