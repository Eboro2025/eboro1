import 'dart:convert';

import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/Auth/Signup.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetails extends StatefulWidget {
  final int? productID;
  final ScrollController? scrollController;

  const ProductDetails({Key? key, required this.productID, this.scrollController}) : super(key: key);

  @override
  ProductDetails2 createState() => ProductDetails2();
}

class ProductDetails2 extends State<ProductDetails> {
  int itemCount = 1;
  bool _showDetails = false;

  /// ✅ Extras vecchi (sauces) Multi-select
  List<String> sauceValues = [];

  /// ✅ Se extraGroups proviene da una nuova API (Objects)
  final Map<int, String> _singleSelected = {}; // groupId -> optionId
  final Map<int, Set<String>> _multiSelected = {}; // groupId -> {optionIds}

  /// ✅ NEW: Index prezzo extra: extraId -> price
  final Map<String, double> _extraPriceIndex = {};

  // Flag to track if price index has been built
  bool _priceIndexBuilt = false;
  int? _lastProductId;

  /// قفل لمنع الضغط المزدوج على زر الإضافة للسلة
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    itemCount = 1;
    sauceValues = [];
    _priceIndexBuilt = false;
  }

  bool _isArabic(String text) {
    if (text.isEmpty) return false;
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, color: Colors.white, size: 60),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                      // ignore: avoid_print
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
                      // ignore: avoid_print
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
                      // ignore: avoid_print
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- Helpers Data ----------------------

  dynamic _getProduct() {
    final list = Provider2.product;
    if (list == null || list.isEmpty) return null;

    try {
      return list.firstWhere(
        (item) => item.id.toString() == widget.productID.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// ✅ extraGroups se presenti (nuovo formato: Objects)
  List<dynamic> _getExtraGroups(dynamic product) {
    try {
      final groups = product.extraGroups;
      if (groups == null) return [];
      if (groups is List) return groups;
      return [];
    } catch (_) {
      return [];
    }
  }

  /// ✅ Il prodotto ha degli Extras? (FIXED: only if there are actual items/options)
  bool _hasAnyExtras(dynamic product) {
    if (product == null) return false;

    // 1) extraGroups objects -> only if options not empty
    final groups = _getExtraGroups(product);
    if (groups.isNotEmpty) {
      for (final g in groups) {
        final opts = g.options;
        if (opts is List && opts.isNotEmpty) return true;
      }
    }

    // 2) sauces
    if (product.sauces is List && product.sauces.isNotEmpty) return true;

    // 3) extra1..extra4 maps -> only if items not empty
    final extrasMaps = [
      product.extra1,
      product.extra2,
      product.extra3,
      product.extra4
    ];
    for (final ex in extrasMaps) {
      if (ex is Map<String, dynamic>) {
        final items = ex['items'];
        if (items is List && items.isNotEmpty) return true;
      }
    }

    // 4) additions JSON -> only if any group has items not empty
    final additionsStr = product.additions?.toString().trim();
    if (additionsStr != null &&
        additionsStr.isNotEmpty &&
        additionsStr != '[]' &&
        additionsStr.toLowerCase() != 'null') {
      try {
        final parsed = jsonDecode(additionsStr);
        if (parsed is List) {
          for (final group in parsed) {
            final items = group['items'];
            if (items is List && items.isNotEmpty) return true;
          }
        }
      } catch (_) {}
    }

    return false;
  }

  /// ✅ Raccogli tutti gli ID selezionati (da extraGroups o additions o sauces o extra1..4)
  List<String> _getAllSelectedExtraIds(dynamic product) {
    final List<String> ids = [];

    // Da extraGroups objects
    _singleSelected.forEach((_, value) {
      if (value.isNotEmpty) ids.add(value);
    });
    _multiSelected.forEach((_, set) {
      ids.addAll(set);
    });

    final groups = _getExtraGroups(product);

    // Se non ci sono extraGroups → fallback: additions + sauces
    if (groups.isEmpty) {
      ids.addAll(sauceValues);
      // additions/extra1..4 selections already stored in _multiSelected/_singleSelected ✅
    }

    return ids.toSet().toList();
  }

  /// ✅ Verifica le condizioni dei gruppi (required, min, max) - لكل أنواع الـ Extras
  String? _validateExtraGroups(dynamic product) {
    // 1) التحقق من extraGroups objects
    final groups = _getExtraGroups(product);
    for (final g in groups) {
      final groupId = int.tryParse(g.id.toString()) ?? g.hashCode;
      final groupName = g.title?.toString() ?? 'Extra';
      final isRequired = g.is_required == true || g.is_required == 1;
      final minSelection = int.tryParse(g.min_selection?.toString() ?? '0') ?? 0;
      final maxSelection = int.tryParse(g.max_selection?.toString() ?? '100') ?? 100;
      final bool isMultiple = g.multiple == true || g.multiple?.toString() == 'true';

      int selectedCount;
      if (isMultiple) {
        selectedCount = (_multiSelected[groupId] ?? <String>{}).length;
      } else {
        selectedCount = _singleSelected[groupId] != null ? 1 : 0;
      }

      if (isRequired && selectedCount == 0) {
        return 'Devi selezionare un elemento da "$groupName"';
      }
      if (minSelection > 0 && selectedCount < minSelection) {
        return 'Devi selezionare almeno $minSelection elementi da "$groupName"';
      }
      if (selectedCount > maxSelection) {
        return 'Non puoi selezionare più di $maxSelection elementi da "$groupName"';
      }
    }

    // 2) التحقق من extra1-4 maps
    final extras = [
      {'data': product.extra1, 'name': 'Primo gruppo'},
      {'data': product.extra2, 'name': 'Secondo gruppo'},
      {'data': product.extra3, 'name': 'Terzo gruppo'},
      {'data': product.extra4, 'name': 'Quarto gruppo'},
    ];

    for (var extra in extras) {
      final data = extra['data'] as Map<String, dynamic>?;
      if (data == null || (data['items'] as List?)?.isEmpty == true) continue;

      final groupName = data['name']?.toString() ?? extra['name'] as String;
      final isRequired =
          data['is_required'] == true || data['is_required'] == 1;
      final minSelection =
          int.tryParse(data['min_selection']?.toString() ?? '0') ?? 0;
      final maxSelection =
          int.tryParse(data['max_selection']?.toString() ?? '100') ?? 100;

      final groupId = data.hashCode;
      final selectedCount = (_multiSelected[groupId] ?? <String>{}).length;

      if (isRequired && selectedCount == 0) {
        return 'Devi selezionare un elemento da "$groupName"';
      }

      if (minSelection > 0 && selectedCount < minSelection) {
        return 'Devi selezionare almeno $minSelection elementi da "$groupName"';
      }

      if (selectedCount > maxSelection) {
        return 'Non puoi selezionare più di $maxSelection elementi da "$groupName"';
      }
    }

    // 3) التحقق من additions JSON
    if (product.additions != null &&
        product.additions.toString().trim().isNotEmpty &&
        product.additions.toString().trim() != '[]') {
      try {
        final parsed = jsonDecode(product.additions.toString());
        if (parsed is List) {
          for (final group in parsed) {
            final groupId = group.hashCode;
            final groupName = (group['title'] ?? group['name'] ?? 'Opzioni').toString();
            final isRequired = group['is_required'] == true || group['is_required'] == 1;
            final minSelection = int.tryParse(group['min_selection']?.toString() ?? '0') ?? 0;
            final maxSelection = int.tryParse(group['max_selection']?.toString() ?? '100') ?? 100;
            final bool isMultiple = group['multiple'] == true || group['multiple']?.toString() == 'true';

            int selectedCount;
            if (isMultiple) {
              selectedCount = (_multiSelected[groupId] ?? <String>{}).length;
            } else {
              selectedCount = _singleSelected[groupId] != null ? 1 : 0;
            }

            if (isRequired && selectedCount == 0) {
              return 'Devi selezionare un elemento da "$groupName"';
            }
            if (minSelection > 0 && selectedCount < minSelection) {
              return 'Devi selezionare almeno $minSelection elementi da "$groupName"';
            }
            if (selectedCount > maxSelection) {
              return 'Non puoi selezionare più di $maxSelection elementi da "$groupName"';
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  bool _isMeaningful(String? value) {
    if (value == null) return false;
    final v = value.trim().toLowerCase();
    return v.isNotEmpty && v != 'null';
  }

  /// ✅ Verifica se il negozio è aperto
  bool _isStoreOpen(dynamic product) {
    try {
      if (product.store != null) {
        if (product.store.is_open != null) {
          return product.store.is_open == true || product.store.is_open == 1;
        }
        if (product.store.status != null) {
          return product.store.status.toString().toLowerCase() == 'open' ||
              product.store.status == 1;
        }
        if (product.store.is_closed != null) {
          return product.store.is_closed == false ||
              product.store.is_closed == 0;
        }
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  // ---------------------- NEW: Price Index Builder ----------------------

  /// ✅ يبني Index: extraId -> price من كل المصادر (extraGroups/sauces/extra1..4/additions)
  void _buildExtraPriceIndex(dynamic product) {
    _extraPriceIndex.clear();
    if (product == null) return;

    // 1) extraGroups objects
    final groups = _getExtraGroups(product);
    if (groups.isNotEmpty) {
      for (final g in groups) {
        final List options = g.options ?? [];
        for (final o in options) {
          final id = o.id.toString();
          final price = double.tryParse(o.price.toString()) ?? 0.0;
          _extraPriceIndex[id] = price;
        }
      }
    }

    // 2) sauces fallback
    if (product.sauces != null) {
      for (final s in product.sauces) {
        final id = s.sauce_id.toString();
        final price = double.tryParse(s.price.toString()) ?? 0.0;
        _extraPriceIndex[id] = price;
      }
    }

    // 3) extra1..extra4 maps
    final extrasMaps = [
      product.extra1,
      product.extra2,
      product.extra3,
      product.extra4
    ];
    for (final ex in extrasMaps) {
      if (ex is Map<String, dynamic>) {
        final items = (ex['items'] ?? []) as List;
        for (final item in items) {
          final id =
              (item['id']?.toString() ?? item['sauce_id']?.toString() ?? '');
          if (id.isEmpty) continue;
          final price =
              double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
          _extraPriceIndex[id] = price;
        }
      }
    }

    // 4) additions JSON
    if (product.additions != null &&
        product.additions.toString().trim().isNotEmpty &&
        product.additions.toString().trim() != '[]') {
      try {
        final parsed = jsonDecode(product.additions.toString());
        if (parsed is List) {
          for (final group in parsed) {
            final items = (group['items'] ?? []) as List;
            for (final item in items) {
              final id = item['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              final price =
                  double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
              _extraPriceIndex[id] = price;
            }
          }
        }
      } catch (_) {}
    }
  }

  // ---------------------- Extras UI ----------------------

  Widget _header(String title, {IconData icon = Icons.local_restaurant}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  /// ✅ sauces: dividi per product_type (Gruppi multipli)
  Widget _buildSaucesGroupWithItems(List sauces) {
    if (sauces.isEmpty) return const SizedBox.shrink();

    Map<String, List> groupedSauces = {};
    for (var sauce in sauces) {
      final type = sauce.product_type?.toString() ?? 'Altri extra';
      groupedSauces.putIfAbsent(type, () => []);
      groupedSauces[type]!.add(sauce);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var entry in groupedSauces.entries) ...[
          const SizedBox(height: 8),
          Text(
            entry.key.isNotEmpty ? entry.key : 'Extra',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 4),
          for (var sauce in entry.value)
            Directionality(
              textDirection: TextDirection.ltr,
              child: InkWell(
                onTap: () {
                  setState(() {
                    final sauceId = sauce.sauce_id.toString();
                    if (sauceValues.contains(sauceId)) {
                      sauceValues.remove(sauceId);
                    } else if (sauceValues.length < 4) {
                      sauceValues.add(sauceId);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          sauce.name?.toString() ?? '',
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                      if ((double.tryParse(sauce.price?.toString() ?? '0') ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '+${sauce.price.toString().replaceAll('.', ',')} €',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ),
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: sauceValues.contains(sauce.sauce_id.toString()) ? Colors.black : Colors.grey[400]!,
                            width: 1.5,
                          ),
                          color: sauceValues.contains(sauce.sauce_id.toString()) ? Colors.black : Colors.transparent,
                        ),
                        child: sauceValues.contains(sauce.sauce_id.toString())
                            ? const Icon(Icons.check, size: 15, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// ✅ Gruppo additions JSON: multiple=true => Multi (checkbox) altrimenti Single (radio)
  Widget _buildAdditionsGroup(String groupName, List items, dynamic groupData) {
    final int groupId = groupData.hashCode;

    final bool isMultiple = groupData['multiple'] == true ||
        groupData['multiple']?.toString().toLowerCase() == 'true';

    // قراءة خصائص الإجبارية
    final bool isRequired = groupData['is_required'] == true || groupData['is_required'] == 1;
    final int minSelection = int.tryParse(groupData['min_selection']?.toString() ?? '0') ?? 0;
    final int maxSelection = int.tryParse(groupData['max_selection']?.toString() ?? '4') ?? 4;

    if (items.isEmpty) return const SizedBox.shrink();

    // حساب عدد العناصر المختارة
    int selectedCount;
    if (isMultiple) {
      selectedCount = (_multiSelected[groupId] ?? <String>{}).length;
    } else {
      selectedCount = _singleSelected[groupId] != null ? 1 : 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان مع شارة إجباري/اختياري
        Row(
          children: [
            Expanded(child: _header(groupName, icon: Icons.label)),
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  'Obbligatorio',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  'Opzionale',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        // معلومات الحد الأدنى والأقصى
        if (minSelection > 0 || maxSelection < 100)
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
            child: Text(
              minSelection > 0
                  ? 'Seleziona da $minSelection a $maxSelection elementi ($selectedCount selezionati)'
                  : 'Massimo $maxSelection elementi ($selectedCount selezionati)',
              style: TextStyle(
                fontSize: 11,
                color: selectedCount >= minSelection
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 4),
        if (isMultiple)
          Column(
            children: items.map<Widget>((item) {
              final id = item['id'].toString();
              final name = (item['name'] ?? 'Opzione').toString();
              final price = (item['price'] ?? '0.00').toString();

              final selectedSet = _multiSelected[groupId] ?? <String>{};
              final isSelected = selectedSet.contains(id);

              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    final set = _multiSelected[groupId] ?? <String>{};
                    if (v == true) {
                      if (set.length < maxSelection) {
                        set.add(id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Puoi selezionare un massimo di $maxSelection elementi'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      set.remove(id);
                    }
                    _multiSelected[groupId] = set;
                  });
                },
                activeColor: myColor,
                title: Text(
                  '$name - $price €',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              );
            }).toList(),
          )
        else
          Column(
            children: items.map<Widget>((item) {
              final id = item['id'].toString();
              final name = (item['name'] ?? 'Opzione').toString();
              final price = (item['price'] ?? '0.00').toString();

              return RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                value: id,
                groupValue: _singleSelected[groupId],
                activeColor: myColor,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _singleSelected[groupId] = v);
                },
                title: Text(
                  '$name - $price €',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildExtraGroupFromMap(
      Map<String, dynamic> extraData, String extraKey) {
    final String groupName = extraData['name']?.toString() ?? extraKey;
    final List items = extraData['items'] ?? [];

    final bool isRequired =
        extraData['is_required'] == true || extraData['is_required'] == 1;
    final int minSelection =
        int.tryParse(extraData['min_selection']?.toString() ?? '0') ?? 0;
    final int maxSelection =
        int.tryParse(extraData['max_selection']?.toString() ?? '4') ?? 4;

    if (items.isEmpty) return const SizedBox.shrink();

    final int groupId = extraData.hashCode;
    final selectedCount = (_multiSelected[groupId] ?? <String>{}).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                groupName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            Text(
              isRequired ? 'Richiesto' : 'Opzionale',
              style: TextStyle(
                fontSize: 13,
                color: isRequired ? Colors.black87 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (minSelection > 0 || maxSelection < 100)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              minSelection > 0
                  ? 'Seleziona da $minSelection a $maxSelection ($selectedCount selezionati)'
                  : 'Massimo $maxSelection ($selectedCount selezionati)',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 4),
        Column(
          children: items.map<Widget>((item) {
            final id =
                item['id']?.toString() ?? item['sauce_id']?.toString() ?? '';
            final name = (item['name'] ?? 'Elemento').toString();
            final priceStr = (item['price'] ?? '0.00').toString();
            final priceVal = double.tryParse(priceStr) ?? 0;

            final selectedSet = _multiSelected[groupId] ?? <String>{};
            final isSelected = selectedSet.contains(id);

            return Directionality(
              textDirection: TextDirection.ltr,
              child: InkWell(
                onTap: () {
                  setState(() {
                    final set = _multiSelected[groupId] ?? <String>{};
                    if (isSelected) {
                      set.remove(id);
                    } else if (set.length < maxSelection) {
                      set.add(id);
                    }
                    _multiSelected[groupId] = set;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                      if (priceVal > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '+${priceVal.toStringAsFixed(2).replaceAll('.', ',')} €',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ),
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey[400]!,
                            width: 1.5,
                          ),
                          color: isSelected ? Colors.black : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 15, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// ✅ extraGroups Objects (se presenti) - مع دعم إجباري/اختياري
  Widget _buildSingleExtraGroup(dynamic group) {
    final int groupId = int.tryParse(group.id.toString()) ?? group.hashCode;

    final String title = (group.title?.toString().trim().isNotEmpty ?? false)
        ? group.title.toString()
        : (AppLocalizations.of(context)!.translate("extras") ?? "Extra");

    final bool multiple =
        (group.multiple?.toString() == 'true' || group.multiple == true);

    // قراءة خصائص الإجبارية
    final bool isRequired = group.is_required == true || group.is_required == 1;
    final int minSelection = int.tryParse(group.min_selection?.toString() ?? '0') ?? 0;
    final int maxSelection = int.tryParse(group.max_selection?.toString() ?? '4') ?? 4;

    final List options = group.options ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    // حساب عدد العناصر المختارة
    int selectedCount;
    if (multiple) {
      selectedCount = (_multiSelected[groupId] ?? <String>{}).length;
    } else {
      selectedCount = _singleSelected[groupId] != null ? 1 : 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Title row with required/optional tag
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            Text(
              isRequired ? 'Richiesto' : 'Opzionale',
              style: TextStyle(
                fontSize: 13,
                color: isRequired ? Colors.black87 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (minSelection > 0 || maxSelection < 100)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              minSelection > 0
                  ? 'Seleziona da $minSelection a $maxSelection elementi ($selectedCount selezionati)'
                  : 'Massimo $maxSelection elementi ($selectedCount selezionati)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        const SizedBox(height: 4),
        // Options list - clean style like reference
        if (multiple)
          Column(
            children: options.map<Widget>((o) {
              final id = o.id.toString();
              final selectedSet = _multiSelected[groupId] ?? <String>{};
              final isSelected = selectedSet.contains(id);
              final price = double.tryParse(o.price?.toString() ?? '0') ?? 0;

              return InkWell(
                onTap: () {
                  setState(() {
                    final set = _multiSelected[groupId] ?? <String>{};
                    if (isSelected) {
                      set.remove(id);
                    } else if (set.length < maxSelection) {
                      set.add(id);
                    }
                    _multiSelected[groupId] = set;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.name?.toString() ?? '',
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                      if (price > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '+${price.toStringAsFixed(2).replaceAll('.', ',')} €',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ),
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey[400]!,
                            width: 1.5,
                          ),
                          color: isSelected ? Colors.black : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 15, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        else
          Column(
            children: options.map<Widget>((o) {
              final id = o.id.toString();
              final isSelected = _singleSelected[groupId] == id;
              final price = double.tryParse(o.price?.toString() ?? '0') ?? 0;

              return InkWell(
                onTap: () {
                  setState(() => _singleSelected[groupId] = id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.name?.toString() ?? '',
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                      if (price > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '+${price.toStringAsFixed(2).replaceAll('.', ',')} €',
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ),
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey[400]!,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12, height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// ✅ Seleziona extras in base alla disponibilità (extraGroups -> sauces+additions+extra1..4)
  Widget _buildExtraGroups(dynamic product) {
    final groups = _getExtraGroups(product);

    // 1) Se extraGroups sono presenti (Objects)
    if (groups.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in groups) ...[
            _buildSingleExtraGroup(g),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    // 2) fallback: sauces + additions(JSON) + extra1-4
    final List<Widget> allGroups = [];

    if (product.sauces != null && product.sauces.isNotEmpty) {
      allGroups.add(_buildSaucesGroupWithItems(product.sauces));
      allGroups.add(const SizedBox(height: 8));
    }

    if (product.extra1 != null) {
      allGroups.add(_buildExtraGroupFromMap(product.extra1!, 'extra1'));
      allGroups.add(const SizedBox(height: 8));
    }
    if (product.extra2 != null) {
      allGroups.add(_buildExtraGroupFromMap(product.extra2!, 'extra2'));
      allGroups.add(const SizedBox(height: 8));
    }
    if (product.extra3 != null) {
      allGroups.add(_buildExtraGroupFromMap(product.extra3!, 'extra3'));
      allGroups.add(const SizedBox(height: 8));
    }
    if (product.extra4 != null) {
      allGroups.add(_buildExtraGroupFromMap(product.extra4!, 'extra4'));
      allGroups.add(const SizedBox(height: 8));
    }

    if (product.additions != null &&
        product.additions.toString().trim().isNotEmpty &&
        product.additions.toString().trim() != '[]') {
      try {
        final parsed = jsonDecode(product.additions.toString());
        if (parsed is List) {
          for (final group in parsed) {
            final groupName =
                (group['title'] ?? group['name'] ?? 'Opzioni').toString();
            final items = (group['items'] ?? []) as List;
            allGroups.add(_buildAdditionsGroup(groupName, items, group));
            allGroups.add(const SizedBox(height: 8));
          }
        }
      } catch (e) {
        // ignore: avoid_print
      }
    }

    if (allGroups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allGroups,
    );
  }

  // ---------------------- Price calc (FIXED) ----------------------

  double _calculateItemPrice(dynamic product) {
    if (product == null) return 0.0;

    final double itemPrice = double.tryParse(product.price.toString()) ?? 0.0;
    final double offerValue =
        double.tryParse(product.offer?.offer_price?.toString() ?? "0") ?? 0.0;

    double basePrice = itemPrice - offerValue;
    if (basePrice < 0) basePrice = 0;

    // ✅ اجمع أسعار كل الإضافات المختارة (من أي مصدر)
    double extrasPrice = 0.0;
    final selectedIds = _getAllSelectedExtraIds(product);
    for (final id in selectedIds) {
      extrasPrice += _extraPriceIndex[id] ?? 0.0;
    }

    return itemCount * (basePrice + extrasPrice);
  }

  // ---------------------- Add to cart ----------------------

  Widget _buildAddToCartButton(BuildContext context, dynamic product) {
    final cart = Provider.of<CartTextProvider>(context, listen: false);
    final totalPrice = _calculateItemPrice(product);
    final bool isStoreOpen = _isStoreOpen(product);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isStoreOpen ? myColor : Colors.grey.shade400,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: !isStoreOpen
              ? null
              : () async {
                  if (_isAddingToCart) return;
                  _isAddingToCart = true;
                  setState(() {});

                  try {
                    if (Auth2.user?.email == "info@eboro.com") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignupScreen()),
                      );
                      return;
                    }

                    if (!_isStoreOpen(product)) {
                      Auth2.show(AppLocalizations.of(context)!
                              .translate("store_closed_message") ??
                          'Spiacenti, il negozio è attualmente chiuso e non è possibile completare l\'ordine');
                      return;
                    }

                    if (product == null || product.has_outofstock != 0) return;
                    if (itemCount <= 0) return;

                    final selectedIds = _getAllSelectedExtraIds(product);

                    final validationError = _validateExtraGroups(product);
                    if (validationError != null) {
                      Auth2.show(validationError);
                      return;
                    }

                    final String? extrasIds =
                        selectedIds.isNotEmpty ? selectedIds.join(',') : null;

                    final int? providerId = product.branch?.provider?.id;

                    await cart.addCartItem(
                      extrasIds,
                      product.id.toString(),
                      itemCount,
                      providerId: providerId,
                      context: context,
                    );

                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    // addToCart error
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isAddingToCart = false;
                        itemCount = 1;
                      });
                    } else {
                      _isAddingToCart = false;
                    }
                  }
                },
          child: Text(
            isStoreOpen
                ? 'Aggiungi per ${totalPrice.toStringAsFixed(2).replaceAll('.', ',')} €'
                : "Negozio chiuso",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------- BUILD ----------------------

  @override
  Widget build(BuildContext context) {
    final product = _getProduct();

    // إذا لم يكن المنتج موجودًا، نعرض رسالة خطأ بدلاً من تحميل لا نهائي
    if (product == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: myColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Prodotto'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Prodotto non trovato',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: myColor),
                child: const Text('Torna indietro', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ مهم: بناء الـ Index للأسعار مرة واحدة فقط لكل منتج
    if (!_priceIndexBuilt || _lastProductId != product.id) {
      _buildExtraPriceIndex(product);
      _priceIndexBuilt = true;
      _lastProductId = product.id;
    }

    final totalPrice = _calculateItemPrice(product);

    final String description = product.description?.toString() ?? '';

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: Stack(
            children: [
              ListView(
                controller: widget.scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Product image - full width square
                  GestureDetector(
                    onTap: () => _showFullImage(context, fixImageUrl(product.image ?? "")),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          imageUrl: fixImageUrl(product.image ?? ""),
                          memCacheHeight: 800,
                          memCacheWidth: 800,
                          errorWidget: (context, url, error) => Container(
                            height: 220,
                            color: Colors.grey[200],
                            child: Icon(Icons.restaurant, color: Colors.grey[400], size: 40),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
                              ],
                            ),
                            child: const Icon(Icons.fullscreen, size: 22, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product name + description
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name?.toString() ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        if (description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              description,
                              style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.4),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (product.has_outofstock != 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate("outofstock") ?? "Non disponibile",
                          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                  if (!_isStoreOpen(product))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.translate("store_closed") ??
                                    "Il negozio è attualmente chiuso.",
                                style: TextStyle(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Contact restaurant box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        final providerItem = Provider2.provider?.firstWhere(
                          (e) => e.id == product.branch?.provider?.id,
                          orElse: () => Provider2.provider!.first,
                        );
                        final phone = providerItem?.user?.mobile?.toString() ?? '';
                        if (phone.isNotEmpty && phone != '--') {
                          launchUrl(Uri(scheme: 'tel', path: phone));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: 'Hai delle domande su allergeni, ingredienti o metodi di preparazione? ',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                            children: [
                              TextSpan(
                                text: 'Contatta il ristorante.',
                                style: TextStyle(color: myColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),

                  // Extras
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: _buildExtraGroups(product),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),

              // X close button - red
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom: quantity + add to cart button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quantity selector centered
                if (product.has_outofstock == 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () { setState(() { if (itemCount > 1) itemCount--; }); },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: itemCount > 1 ? myColor : Colors.grey[300]!),
                            ),
                            child: Icon(Icons.remove, color: itemCount > 1 ? myColor : Colors.grey[400], size: 20),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            itemCount.toString(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        GestureDetector(
                          onTap: () { setState(() { itemCount++; }); },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: myColor),
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF00CCBC), size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Add to cart button
                _buildAddToCartButton(context, product),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 2,
              child: Text(
                value,
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
