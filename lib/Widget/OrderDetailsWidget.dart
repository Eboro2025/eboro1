import 'package:flutter/material.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/Helper/ContentData.dart';
import 'package:eboro/Helper/RateData.dart';

class OrderDetailsWidget extends StatelessWidget {
  final OrderData order;
  const OrderDetailsWidget({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (order.content != null)
          ...order.content!.map((item) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Quantità: ${item.qty ?? ''}   Prezzo: ${item.price ?? ''} €'),
                      if (item.sauces != null && item.sauces!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const Text('Extra:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...item.sauces!.map((extra) => Row(
                              children: [
                                if (extra.image != null && extra.image!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Image.network(extra.image!, width: 24, height: 24),
                                  ),
                                Text('${extra.name ?? ''} (${extra.price ?? ''} €)'),
                              ],
                            )),
                      ],
                      if (item.comment != null && item.comment!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text('Nota: ${item.comment}'),
                        ),
                    ],
                  ),
                ),
              )),
        if (order.Rate != null && order.Rate!.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Valutazione ordine:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...order.Rate!.map((rate) => ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text('Valutazione: ${rate.value ?? ''}'),
                subtitle: rate.comment != null ? Text(rate.comment!) : null,
              )),
        ],
      ],
    );
  }
}
