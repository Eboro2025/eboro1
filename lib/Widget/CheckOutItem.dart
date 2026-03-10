import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckOutItem extends StatefulWidget {
  @override
  CheckOutItem2 createState() => CheckOutItem2();
}

class CheckOutItem2 extends State<CheckOutItem> {
  final TextEditingController _comment = TextEditingController();
  static final List<String?> comments = [];

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartTextProvider>(context);
    final items = cartProvider.cart?.cart_items ?? [];

    if (items.isEmpty) {
      return SizedBox.shrink();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = items[i];

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // TODO: open product page if needed
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image on the right (RTL)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      height: MyApp2.W! * .18,
                      width: MyApp2.W! * .18,
                      fit: BoxFit.cover,
                      useOldImageOnUrlChange: true,
                      imageUrl: fixImageUrl(item.product_image.toString()),
                      progressIndicatorBuilder: (context, url, downloadProgress) =>
                          SizedBox(
                            height: 32,
                            width: 32,
                            child: CircularProgressIndicator(
                              value: downloadProgress.progress,
                              strokeWidth: 2,
                            ),
                          ),
                      errorWidget: (context, url, error) =>
                          Image.asset("images/icons/logo.png", color: Colors.black26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text + price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          item.product_name.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Price and quantity
                        Text(
                          '${item.qty} × ${item.product_price} €',
                          style: TextStyle(
                            fontSize: MyApp2.fontSize14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Comment (if present)
                        if (i < comments.length && (comments[i]?.isNotEmpty ?? false))
                          Row(
                            children: [
                              Icon(Icons.notes, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  comments[i]!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: MyApp2.fontSize12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action buttons (delete + comment)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.highlight_remove_rounded,
                          color: myColor,
                          size: MyApp2.fontSize20,
                        ),
                        onPressed: () {
                          cartProvider.deleteCartItem(item.id, context);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.note_add_outlined,
                          color: myColor,
                          size: MyApp2.fontSize20,
                        ),
                        onPressed: () {
                          _showCommentSheet(context, i);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCommentSheet(BuildContext context, int index) {
    _comment.text = (index < comments.length && comments[index] != null)
        ? comments[index]!
        : "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Aggiungi una nota all\'ordine',
                  style: TextStyle(
                    fontSize: MyApp2.fontSize16,
                    fontWeight: FontWeight.w600,
                    color: myColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 3,
                  controller: _comment,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    hintText: 'Es. senza cipolla, più formaggio, ...',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCFCFCF)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: myColor.withOpacity(.5), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFCFCFCF), width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _comment.clear();
                        },
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (index < comments.length) {
                            comments[index] = _comment.text.trim();
                          } else {
                            comments.add(_comment.text.trim());
                          }
                          Navigator.of(ctx).pop();
                          setState(() {});
                          _comment.clear();
                        },
                        child: const Text(
                          'Salva',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
