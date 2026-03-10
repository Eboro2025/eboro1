import 'dart:async';
import 'package:eboro/MainScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart' as app;

// Providers
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';

// الشاشة الرئيسية الجديدة

class SuccessfulOrder extends StatefulWidget {
  const SuccessfulOrder({Key? key}) : super(key: key);

  @override
  State<SuccessfulOrder> createState() => _SuccessfulOrderState();
}

class _SuccessfulOrderState extends State<SuccessfulOrder> {
  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    // تحديث Orders فقط — السلة اتفرغت خلاص في Order.makeOrder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final order = Provider.of<UserOrderProvider>(context, listen: false);
      order.updateOrder(force: true);
    });

    // Auto-navigate to orders page after 30 seconds
    _autoNavigateTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) _goToOrders();
    });
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    super.dispose();
  }

  void _goToOrders() async {
    final cart = Provider.of<CartTextProvider>(context, listen: false);
    final order = Provider.of<UserOrderProvider>(context, listen: false);
    await cart.updateCart();
    await order.updateOrder(force: true);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainScreen(initialIndex: 1),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final ordersText = localizations?.translate("orders") ?? "orders";
    final ordersMsgText =
        localizations?.translate("orders_msg") ?? "orders_msg";
    final homeText = localizations?.translate("home") ?? "home";

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(left: 50, right: 50),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 100,
              height: 100,
              child: MaterialButton(
                onPressed: () {},
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.check,
                  color: app.myColor,
                  size: 65,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              ordersText,
              style: TextStyle(
                fontSize: 32,
                color: app.myColor2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              ordersMsgText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: app.myColor2,
              ),
            ),
            const SizedBox(height: 40),
            MaterialButton(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
              color: Theme.of(context).primaryColorDark,
              textColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                // تقدر تغيّر الـ key لو حابب مثلاً "myorders"
                homeText,
                style: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                _autoNavigateTimer?.cancel();
                _goToOrders();
              },
            ),
          ],
        ),
      ),
    );
  }
}
