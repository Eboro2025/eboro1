import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/API/Provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartItem extends StatefulWidget {
  const CartItem({Key? key}) : super(key: key);

  @override
  CartItem2 createState() => CartItem2();
}

class CartItem2 extends State<CartItem> {
  // حساب السعر مع الخصم (نفس طريقة ProductDetails)
  double _calculatePriceWithDiscount(dynamic cartItem) {
    double productPrice = cartItem.product_price ?? 0.0;

    // محاولة الحصول على المنتج الأصلي من Provider2
    if (Provider2.product != null) {
      try {
        final product = Provider2.product!.firstWhere(
          (p) => p.id == cartItem.product_id,
        );
        final offer = product.offer;
        // التحقق من وجود عرض صحيح وفعلي
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

    // جمع أسعار الصوصات/الإضافات
    double saucesPrice = 0.0;
    for (final s in cartItem.sauces ?? []) {
      saucesPrice += s.price ?? 0.0;
    }
    double extrasPrice = 0.0;
    for (final e in cartItem.extras ?? []) {
      extrasPrice += e.price ?? 0.0;
    }

    int qty = cartItem.qty ?? 1;
    double total = (productPrice + saucesPrice + extrasPrice) * qty;
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartTextProvider>(
      builder: (context, cartProvider, child) {
        final items = cartProvider.cart?.cart_items ?? [];

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) Divider(color: Colors.grey[200], height: 16),
                  KeyedSubtree(
                    key: ValueKey('cart_item_${items[i].id}'),
                    child: _buildCartItemRow(cartProvider, i, context),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartItemRow(
      CartTextProvider cartProvider, int i, BuildContext context) {
    final cartItem = cartProvider.cart!.cart_items![i];

    // حساب السعر مع الخصم (لو موجود)
    double displayPrice = _calculatePriceWithDiscount(cartItem);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // صورة المنتج (يمين في RTL)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  height: MyApp2.W! * .16,
                  width: MyApp2.W! * .16,
                  fit: BoxFit.cover,
                  imageUrl: fixImageUrl(cartItem.product_image),
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: Icon(
                      Icons.fastfood,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // اسم المنتج + السعر + الكمية
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      cartItem.product_name.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        fontWeight: FontWeight.w600,
                        color: myColor2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // السعر × الكمية
                    Text(
                      '${displayPrice.toStringAsFixed(2)} € × ${cartItem.qty}',
                      style: TextStyle(
                        fontSize: MyApp2.fontSize14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              // زر الحذف
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: myColor,
                  size: 22,
                ),
                onPressed: () async {
                  await cartProvider.deleteCartItem(cartItem.id, context);
                  if (cartProvider.cart!.cart_items?.isEmpty ?? true) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          // الصوصات (لو موجودة)
          if (cartItem.sauces != null && cartItem.sauces!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6.0, left: 6.0, top: 4),
              child: buildSauceWidgets(cartItem),
            ),
          // الإضافات extras (لو موجودة)
          if (cartItem.extras != null && cartItem.extras!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6.0, left: 6.0, top: 4),
              child: buildExtraWidgets(cartItem),
            ),
        ],
    );
  }

  Widget buildSauceWidgets(cart) {
    List<Widget> sauceWidgets = [];
    if (cart.sauces != null) {
      for (var sauce in cart.sauces!) {
        sauceWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.circle,
                  size: 6,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${sauce.name}",
                    style: TextStyle(
                      fontSize: MyApp2.fontSize14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${sauce.price.toString()} € × ${cart.qty.toString()}',
                  style: TextStyle(
                    fontSize: MyApp2.fontSize14,
                    color: myColor2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sauceWidgets,
    );
  }

  Widget buildExtraWidgets(cart) {
    List<Widget> extraWidgets = [];
    if (cart.extras != null) {
      for (var extra in cart.extras!) {
        extraWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.add_circle,
                  size: 6,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${extra.name}",
                    style: TextStyle(
                      fontSize: MyApp2.fontSize14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${extra.price?.toStringAsFixed(2) ?? "0.00"} € × ${cart.qty.toString()}',
                  style: TextStyle(
                    fontSize: MyApp2.fontSize14,
                    color: myColor2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: extraWidgets,
    );
  }
}
