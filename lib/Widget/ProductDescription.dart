import 'dart:convert';

import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Auth/Signup.dart';

class ProductDescription extends StatefulWidget {
  final int? productID;
  ProductDescription({Key? key, this.productID}) : super(key: key);

  @override
  ProductDescription2 createState() => ProductDescription2();
}

class ProductDescription2 extends State<ProductDescription> {
  int _itemCount = 1;

  Map<String, Set<String>> selectedExtras = {};

  @override
  void initState() {
    super.initState();
    // print(widget.productID);
  }

  bool get hasAnySelection {
    return selectedExtras.values.any((set) => set.isNotEmpty);
  }

  String? get selectedExtrasIdsOrNull {
    final allIds = selectedExtras.values.expand((s) => s).toSet().toList();
    if (allIds.isEmpty) return null;
    return allIds.join(',');
  }

  void toggleSelection(String groupName, String itemId, bool isSelected) {
    setState(() {
      final set = selectedExtras[groupName] ?? <String>{};
      if (isSelected) {
        set.add(itemId);
      } else {
        set.remove(itemId);
      }
      if (set.isEmpty) {
        selectedExtras.remove(groupName);
      } else {
        selectedExtras[groupName] = set;
      }
      // print('📋 selections: $selectedExtras');
    });
  }

  void _showShareOptions(BuildContext context, dynamic product) {
    final String productName = product.name?.toString() ?? '';
    final String productPrice = product.price?.toString() ?? '0';
    final String shareText =
        'Check out $productName - €$productPrice on Eboro!';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: myColor),
                const SizedBox(width: 8),
                const Text(
                  'Condividi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  context,
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final url =
                          'https://wa.me/?text=${Uri.encodeComponent(shareText)}';
                      final uri = Uri.parse(url);
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } catch (e) {
                      Auth2.show('Errore apertura WhatsApp');
                      // print('WhatsApp error: $e');
                    }
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.email,
                  label: 'Email',
                  color: Colors.red.shade700,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final url =
                          'mailto:?subject=${Uri.encodeComponent(productName)}&body=${Uri.encodeComponent(shareText)}';
                      final uri = Uri.parse(url);
                      await launchUrl(uri);
                    } catch (e) {
                      Auth2.show('Errore apertura Email');
                      // print('Email error: $e');
                    }
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.textsms,
                  label: 'SMS',
                  color: Colors.blue.shade700,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final url = 'sms:?body=${Uri.encodeComponent(shareText)}';
                      final uri = Uri.parse(url);
                      await launchUrl(uri);
                    } catch (e) {
                      Auth2.show('Errore apertura SMS');
                      // print('SMS error: $e');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartTextProvider>(context);

    final product = Provider2.product!
        .where((item) => item.id.toString() == widget.productID.toString())
        .first;

    // Guard against null or empty values
    final productImage = product.image ?? '';
    final productPrice = product.price != null
        ? double.tryParse(product.price.toString()) ?? 0.0
        : 0.0;
    bool productAdditions = false;
    if (product.additions != null &&
        product.additions.toString().trim().isNotEmpty &&
        product.additions.toString() != '[]' &&
        product.additions.toString() != '' &&
        product.additions.toString() != 'null') {
      try {
        final parsed = jsonDecode(product.additions.toString());
        if (parsed is List && parsed.isNotEmpty) {
          // Check that there are real items inside each group
          productAdditions = parsed.any((group) {
            final items = (group['items'] ?? []) as List?;
            return items != null && items.isNotEmpty;
          });
        }
      } catch (_) {
        productAdditions = false;
      }
    }

    final productSauces = product.sauces != null &&
        product.sauces is List &&
        product.sauces!.isNotEmpty;
    bool hasExtras = productAdditions || productSauces;

    return Container(
      child: ListView(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Card(
                  semanticContainer: true,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: (productImage.isNotEmpty)
                      ? CachedNetworkImage(
                          height: MediaQuery.of(context).size.width * .5,
                          width: MediaQuery.of(context).size.width * .5,
                          fit: BoxFit.cover,
                          useOldImageOnUrlChange: true,
                          imageUrl: productImage,
                          memCacheHeight: 800,
                          memCacheWidth: 800,
                          maxHeightDiskCache: 1000,
                          maxWidthDiskCache: 1000,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Center(
                            child: CircularProgressIndicator(
                                value: downloadProgress.progress),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: MediaQuery.of(context).size.width * .5,
                            width: MediaQuery.of(context).size.width * .5,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.fastfood,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Container(
                          height: MediaQuery.of(context).size.width * .5,
                          width: MediaQuery.of(context).size.width * .5,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.fastfood,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                ),
              ),

              Container(
                margin: const EdgeInsets.only(
                    left: 20, right: 20, top: 5, bottom: 5),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (product.has_outofstock == 0)
                          Column(
                            children: <Widget>[
                              if (product.offer != null)
                                Text(
                                  ((_itemCount) *
                                                  double.parse(product.price
                                                      .toString()) -
                                              double.parse(product
                                                  .offer!.offer_price
                                                  .toString()))
                                          .toString() +
                                      ' €',
                                  style: TextStyle(
                                    color: myColor,
                                    fontSize: 18,
                                  ),
                                )
                              else
                                Text(
                                  ((_itemCount) *
                                              double.parse(
                                                  product.price.toString()))
                                          .toString() +
                                      ' €',
                                  style: TextStyle(
                                    color: myColor,
                                    fontSize: 18,
                                  ),
                                )
                            ],
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (product.has_outofstock == 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              _itemCount > 1
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        color: myColor,
                                        size: 25,
                                      ),
                                      onPressed: () =>
                                          setState(() => _itemCount--),
                                    )
                                  : Container(),
                              Text(
                                _itemCount.toString(),
                                style: TextStyle(color: myColor, fontSize: 20),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: myColor,
                                  size: 25,
                                ),
                                onPressed: () => setState(() => _itemCount++),
                              )
                            ],
                          ),
                        ],
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (Auth2.user!.email != "info@eboro.com" &&
                            product.has_outofstock == 0) ...[
                          Container(
                            child: MaterialButton(
                              child: Text(
                                "${AppLocalizations.of(context)!.translate("addtocart")}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              color: myColor,
                              textColor: Colors.white,
                              onPressed: () {
                                if (hasExtras && !hasAnySelection) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Seleziona prima le aggiunte'),
                                    ),
                                  );
                                  return;
                                }
                                // If there are no extras or sauces, add directly without any check
                                // If there are no extras, add directly without any check

                                final extrasIds = selectedExtrasIdsOrNull;
                                // Get provider_id from the product (provider.id only)
                                final providerId = product.branch?.provider?.id;
                                cart.addCartItem(
                                  extrasIds,
                                  widget.productID.toString(),
                                  _itemCount,
                                  providerId: providerId,
                                  context: context,
                                );
                              },
                            ),
                          ),
                        ] else if (Auth2.user!.email == "info@eboro.com") ...[
                          Container(
                            child: MaterialButton(
                              child: Text(
                                "${AppLocalizations.of(context)!.translate("addtocart")}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              color: myColor,
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SignupScreen()),
                                );
                              },
                            ),
                          ),
                        ]
                      ],
                    )
                  ],
                ),
              ),

              if (product.description != null) ...[
                Container(
                  margin: const EdgeInsets.only(
                      left: 20, right: 20, top: 0, bottom: 0),
                  child: Column(
                    children: [
                      Text(
                        product.description.toString(),
                        textAlign: TextAlign.start,
                        style: TextStyle(color: myColor2, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],

              // Share button
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        _showShareOptions(context, product);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.share,
                                color: Colors.blue.shade700, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Condividi',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ...(() {
                List<Widget> extraWidgets = [];

                if (product.additions != null &&
                    product.additions.toString().trim().isNotEmpty &&
                    product.additions.toString() != '[]') {
                  try {
                    // print('📦 additions raw: ${product.additions}');
                    final parsed = jsonDecode(product.additions.toString());
                    // print('📦 additions parsed type: ${parsed.runtimeType}');

                    if (parsed is List && parsed.isNotEmpty) {
                      for (var i = 0; i < parsed.length; i++) {
                        final group = parsed[i] as Map<String, dynamic>;
                        final groupName = 'Aggiunta ${i + 1}';
                        final items = (group['items'] ?? []) as List;

                        if (items.isEmpty) continue;

                        extraWidgets.add(
                          Container(
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 8, bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                  color: Colors.black.withOpacity(.04),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_restaurant,
                                        size: 18,
                                        color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        groupName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...items.map((item) {
                                  final id = item['id'].toString();
                                  final name = (item['name'] ?? '').toString();
                                  final price =
                                      (item['price'] ?? '').toString();

                                  final isChecked =
                                      (selectedExtras[groupName] ?? {})
                                          .contains(id);

                                  return CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    value: isChecked,
                                    onChanged: (v) {
                                      toggleSelection(groupName, id, v == true);
                                    },
                                    title: Text(
                                      '$name - $price €',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      }

                      return extraWidgets;
                    }
                  } catch (e) {
                    // print('Error parsing additions: $e');
                  }
                }

                if (product.sauces != null && product.sauces!.isNotEmpty) {
                  const saucesGroup = "Salse";

                  extraWidgets.add(
                    Container(
                      margin: const EdgeInsets.only(
                          left: 20, right: 20, top: 8, bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                            color: Colors.black.withOpacity(.04),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_restaurant,
                                  size: 18, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  saucesGroup,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...product.sauces!.map((sauce) {
                            final id = sauce.sauce_id.toString();
                            final isChecked =
                                (selectedExtras[saucesGroup] ?? {})
                                    .contains(id);

                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: isChecked,
                              onChanged: (v) {
                                toggleSelection(saucesGroup, id, v == true);
                              },
                              title: Row(
                                children: [
                                  if (sauce.image != null &&
                                      sauce.image.toString().isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                        imageUrl: sauce.image.toString(),
                                        errorWidget: (context, url, error) =>
                                            Image.asset(
                                          "images/icons/logo.png",
                                          color: Colors.black26,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${sauce.name ?? ""} - ${sauce.price ?? ""} €',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }

                return extraWidgets;
              })(),
            ],
          ),
        ],
      ),
    );
  }
}
