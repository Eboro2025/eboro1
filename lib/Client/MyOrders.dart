import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/RealTime/Widget/UserOrderWidget.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({Key? key}) : super(key: key);

  @override
  _MyOrdersState createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  @override
  void initState() {
    super.initState();
    // استدعاء updateOrder عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserOrderProvider>(context, listen: false).updateOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: myColor,
        title: Text(
          AppLocalizations.of(context)!.translate("myorders"),
          style: TextStyle(
            color: Colors.white,
            fontSize: MyApp2.fontSize20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<UserOrderProvider>(
        builder: (context, orderProvider, _) {
          final orders = orderProvider.order;

          if (orders == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('images/icons/empty.png'),
                  const SizedBox(height: 20),
                  const Text('No orders found', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => orderProvider.updateOrder(force: true),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: orders.length,
              itemBuilder: (ctx, i) => UserOrderWidget(index: i),
            ),
          );
        },
      ),
    );
  }
}
