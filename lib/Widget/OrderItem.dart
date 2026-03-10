import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/main.dart';
import 'package:eboro/Widget/ProductDetails.dart';
import 'package:eboro/API/Provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderItem extends StatefulWidget {
  final dynamic selfOrder;

  /// عدد العناصر اللي هتظهر في الوضع compact
  final int maxItems;

  const OrderItem({
    Key? key,
    required this.selfOrder,
    this.maxItems = 3,
  }) : super(key: key);

  @override
  OrderItemState createState() => OrderItemState();
}

class OrderItemState extends State<OrderItem> {
  void _openProductDetails(BuildContext context, dynamic prod) {
    // التأكد من أن المنتج موجود في Provider2.product قبل فتح التفاصيل
    if (Provider2.product == null) {
      Provider2.product = [];
    }
    if (!Provider2.product!.any((p) => p.id == prod.id)) {
      try {
        Provider2.product!.add(prod);
      } catch (_) {
        // تجاهل خطأ النوع
      }
    }

    // ProductDetails bottom sheet
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProductDetails(productID: prod.id),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // fallback
      showModalBottomSheet(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prod.name ?? '',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('${prod.price} €', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text(prod.description?.toString() ?? ''),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = Provider.of<UserOrderProvider>(context);

    final content = order.selectedOrder.content ?? [];
    if (content.isEmpty) {
      return const Center(child: Text("No items"));
    }

    final visible = content.take(widget.maxItems).toList();
    final remaining = content.length - visible.length;

    return Column(
      children: [
        // ✅ Compact list without scroll
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(), // ✅ NO SCROLL
            shrinkWrap: true,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (context, i) {
              final row = visible[i];
              final prod = row.product;

              return GestureDetector(
                onTap: () {
                  if (prod != null) _openProductDetails(context, prod);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${prod?.name ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis, // ✅ no overflow
                              style: TextStyle(
                                fontSize: MyApp2.fontSize14,
                                color: myColor2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${prod?.price ?? ''} €',
                            style: TextStyle(
                              fontSize: MyApp2.fontSize14,
                              color: myColor2,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'x ${row.qty ?? 1}',
                            style: TextStyle(
                              fontSize: MyApp2.fontSize14,
                              color: myColor2,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      // Sauces (compact)
                      if (prod?.sauces != null && (prod!.sauces!).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...prod.sauces!.take(2).map(
                                    (sauce) => Text(
                                      '${sauce.name ?? ''} - ${sauce.price ?? ''} €',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: MyApp2.fontSize14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              if (prod.sauces!.length > 2)
                                Text(
                                  '+ ${prod.sauces!.length - 2} more sauces',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),

                      // Extras (compact)
                      if (row.extras != null && row.extras!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Extras:',
                                style: TextStyle(
                                  fontSize: MyApp2.fontSize14,
                                  color: Colors.blue,
                                ),
                              ),
                              ...row.extras!.take(2).map(
                                    (extra) => Text(
                                      '${extra.name ?? ''} - ${extra.price ?? ''} €',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: MyApp2.fontSize14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              if (row.extras!.length > 2)
                                Text(
                                  '+ ${row.extras!.length - 2} more extras',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ✅ "+ more items" footer
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+ $remaining more items',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
