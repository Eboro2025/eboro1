import 'package:eboro/Helper/CartData.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:eboro/API/Cart.dart';
import 'package:http/http.dart' as http;

class CartTextProvider with ChangeNotifier {
  CartData? cart = CartData();

  /// قفل لمنع الضغط المزدوج على إضافة/حذف
  bool _isProcessing = false;

  /// الحصول على provider_id للسلة الحالية (إن وجد)
  int? get currentProviderId {
    if (cart?.cart_items == null || cart!.cart_items!.isEmpty) {
      return null;
    }
    return cart!.cart_items!.first.provider_id;
  }

  /// التحقق إذا السلة فارغة
  bool get isCartEmpty {
    return cart?.cart_items == null || cart!.cart_items!.isEmpty;
  }

  updateCart() async {
    cart = await Cart().getCart();
    notifyListeners();
  }

  /// إضافة منتج للسلة مع التحقق من المحل
  addCartItem(extras, item, qty, {int? providerId, BuildContext? context}) async {
    // منع الضغط المزدوج
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // التحقق من المحل إذا كانت السلة غير فارغة
      if (!isCartEmpty && providerId != null && currentProviderId != null) {
        if (providerId != currentProviderId) {
          // المنتج من محل مختلف - نعرض تحذير للمستخدم
          if (context != null) {
            final shouldClear = await _showClearCartDialog(context);
            if (shouldClear != true) {
              return;
            }
            await _clearCartFromAPI(context);
          } else {
            final ctx = navigatorKey.currentContext;
            if (ctx != null) {
              final shouldClear = await _showClearCartDialog(ctx);
              if (shouldClear != true) {
                return;
              }
              await _clearCartFromAPI(ctx);
            }
          }
        }
      }

      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      Progress.progressDialogue(ctx);
      await Cart().addToCart(extras, item, qty);
      await updateCart();
      if (navigatorKey.currentContext != null) {
        Progress.dimesDialog(navigatorKey.currentContext!);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// عرض dialog للتأكيد على تفريغ السلة
  Future<bool?> _showClearCartDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Nuovo ristorante',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Hai già prodotti nel carrello da un altro ristorante.\n\nVuoi svuotare il carrello e aggiungere questo prodotto?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Annulla',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: myColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Svuota e aggiungi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// تفريغ السلة من الـ API
  Future<void> _clearCartFromAPI(BuildContext context) async {
    try {
      if (cart?.cart_items != null) {
        for (var item in cart!.cart_items!) {
          await Cart().deleteCartItem(item.id, context);
        }
      }
      await updateCart();
    } catch (_) {}
  }

  deleteCartItem(i, context) async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      Progress.progressDialogue(context);
      await Cart().deleteCartItem(i, context);
      await updateCart();
      Progress.dimesDialog(context);
    } finally {
      _isProcessing = false;
    }
  }

  restCartItem(context) async {
    await Cart().restCartItem(context);
    notifyListeners();
  }

  /// تفريغ السلة بالكامل
  clearCart(context) async {
    Progress.progressDialogue(context);
    await _clearCartFromAPI(context);
    Progress.dimesDialog(context);
  }

  /// تفريغ السلة بدون progress dialog
  Future<void> clearCartSilent() async {
    try {
      String myUrl = "$globalUrl/api/rest-cart-item/";
      await http.get(Uri.parse(myUrl), headers: {
        'apiLang': MyApp2.apiLang.toString(),
        'Accept': 'application/json',
        'Authorization': "${MyApp2.token}",
      });
    } catch (_) {}
    cart?.cart_items?.clear();
    await updateCart();
  }
}
