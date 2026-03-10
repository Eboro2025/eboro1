import 'package:flutter/material.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/main.dart';
import 'package:eboro/Helper/ProductData.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/Widget/ProductDetails.dart';

class RecommendedSection extends StatelessWidget {
  final CartTextProvider cart;
  final Future<List<ProductData>?>? recommendedFuture;
  final Map<String, int> initialCartCounts;
  final BoxDecoration cardDecoration;

  const RecommendedSection({
    super.key,
    required this.cart,
    required this.recommendedFuture,
    required this.initialCartCounts,
    required this.cardDecoration,
  });

  int _getCartCountForProduct(dynamic product) {
    final pid = product.id?.toString();
    if (pid == null) return 0;
    return initialCartCounts[pid] ?? 0;
  }

  Future<void> _addOneFromRecommended(
    BuildContext context,
    CartTextProvider cart,
    ProductData product,
  ) async {
    try {
      final List<String> emptyExtras = [];
      final int? providerId = product.branch?.provider?.id;
      await cart.addCartItem(
        emptyExtras,
        product.id.toString(),
        1,
        providerId: providerId,
        context: context,
      );
    } catch (e) {
      Auth2.show("Errore nell'aggiunta al carrello");
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerId = cart.cart?.cart_items?.firstOrNull?.provider_id;
    if (providerId == null) return const SizedBox.shrink();

    return FutureBuilder<List<ProductData>?>(
      future: recommendedFuture ?? Provider2.getProducts(providerId),
      builder: (context, snapshot) {
        // استخدام cached product data لتجنب loading flash
        final allProducts = Provider2.product ?? [];
        
        if (snapshot.connectionState == ConnectionState.waiting &&
            allProducts.isEmpty) {
          // فقط show SizedBox.shrink إذا لا توجد بيانات cached
          return const SizedBox.shrink();
        }

        if (allProducts.isEmpty) return const SizedBox.shrink();

        final productsWithScore = allProducts
            .map((p) => MapEntry(p, _getCartCountForProduct(p)))
            .toList();
        productsWithScore.sort((a, b) => b.value.compareTo(a.value));
        final recommendedItems = productsWithScore.map((e) => e.key).take(10).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Consigliati per te',
                    style: TextStyle(fontSize: MyApp2.fontSize14, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Vedi tutto',
                      style: TextStyle(fontSize: MyApp2.fontSize12, color: myColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = recommendedItems[index];
                    return _RecommendedCard(
                      item: item,
                      cart: cart,
                      onAdd: () => _addOneFromRecommended(context, cart, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final ProductData item;
  final CartTextProvider cart;
  final VoidCallback onAdd;

  const _RecommendedCard({
    required this.item,
    required this.cart,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final String name = item.name?.toString() ?? "Prodotto";
    final String imageUrl = fixImageUrl(item.image?.toString());
    final double price = double.tryParse(item.price?.toString() ?? "0") ?? 0.0;
    final bool hasOffer = (item.offer?.toString() == "1") || (item.offer == true);

    return GestureDetector(
      onTap: () async {
        if (Provider2.product == null) {
          Provider2.product = [item];
        } else if (!Provider2.product!.any((p) => p.id == item.id)) {
          Provider2.product!.add(item);
        }
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetails(productID: item.id)),
        );
        if (result == true) {
          await cart.updateCart();
        }
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _placeholder();
                          },
                          errorBuilder: (context, error, stackTrace) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                if (hasOffer)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'OFFERTA',
                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: MyApp2.fontSize12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${price.toStringAsFixed(2)} \u20ac',
                        style: TextStyle(fontSize: MyApp2.fontSize12, color: myColor2, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: onAdd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: myColor, borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
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

  Widget _placeholder() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade200, Colors.grey.shade100],
        ),
      ),
      child: Icon(Icons.restaurant, size: 32, color: Colors.grey.shade400),
    );
  }
}
