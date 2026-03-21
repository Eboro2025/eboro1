import 'package:eboro/Helper/FavoriteData.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../API/Auth.dart';
import '../RealTime/Provider/CartTextProvider.dart';

class Favorites extends StatefulWidget {
  @override
  Favorites2 createState() => Favorites2();
}

class Favorites2 extends State<Favorites> {
  @override
  void initState() {
    super.initState();
  }

  /// helper صغير يطلع أول رقم من الـ Duration
  double _parseDurationMinutes(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    final String text = raw.toString();
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(text);
    if (match == null) return 0.0;
    return double.tryParse(match.group(1)!) ?? 0.0;
  }

  /// Helper method to build offer badge text
  String _buildOfferTextFromOffer(dynamic offer) {
    if (offer == null) return 'Offerta';

    final offerType = offer.offer_type;
    final List<String> parts = [];

    if (offerType == 'discount' || offerType == 'fixed_discount') {
      final value = offer.offer_value?.toString().trim();
      if (value != null && value.isNotEmpty) {
        parts.add('-$value%');
      } else {
        parts.add('-25%');
      }
    }

    if (offerType == 'two_for_one' ||
        offerType == 'one_plus_one' ||
        offerType == 'two_for_one_free_delivery') {
      if (offerType == 'one_plus_one') {
        parts.add('1+1');
      } else {
        parts.add('2×1');
      }
    }

    if (offerType == 'free_delivery' || offerType == 'two_for_one_free_delivery') {
      parts.add('fs');
    }

    if (parts.isEmpty) return 'Offerta';
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final providerController = Provider.of<ProviderController>(context);
    final cart = Provider.of<CartTextProvider>(context);
    final favoritesList = providerController.Favorites ?? [];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 5),
        children: [
          for (FavoriteData favorite in favoritesList)
            Padding(
              padding:
                  const EdgeInsets.only(left: 7, right: 7, top: 5, bottom: 5),
              child: Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 3,
                child: Column(
                  children: [
                    GestureDetector(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: fixImageUrl(favorite.provider?.logo?.toString() ?? ''),
                            useOldImageOnUrlChange: true,
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) =>
                                    CircularProgressIndicator(
                                        value: downloadProgress.progress),
                            errorWidget: (context, url, error) => Container(
                              alignment: Alignment.topLeft,
                              height: MediaQuery.of(context).size.height * .2,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('images/icons/logo.png'),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              child: const Row(children: []),
                            ),
                            imageBuilder: (context, imageProvider) => Container(
                              padding: const EdgeInsets.all(10),
                              alignment: Alignment.topLeft,
                              height: MediaQuery.of(context).size.height * .2,
                              foregroundDecoration: favorite.provider?.state ==
                                      '0'
                                  ? const BoxDecoration(
                                      color: Colors.grey,
                                      backgroundBlendMode: BlendMode.saturation,
                                    )
                                  : const BoxDecoration(),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withValues(alpha: 0.3),
                                    BlendMode.darken,
                                  ),
                                  image: imageProvider,
                                  fit: BoxFit.fill,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (favorite.provider?.state == '0')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(50),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFFE43945),
                                            Color(0xFFC12732),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        "Closed",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: MyApp2.fontSize16,
                                        ),
                                      ),
                                    ),
                                  if (favorite.provider?.state != '0' &&
                                      favorite.provider?.offer != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: const Color(0xFFD32F2F),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _buildOfferTextFromOffer(favorite.provider?.offer),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    padding:
                                        const EdgeInsets.only(top: 5, right: 5),
                                    child: GestureDetector(
                                      child: Icon(
                                        FontAwesomeIcons.heartCircleMinus,
                                        color: Colors.red,
                                        size: MyApp2.W! * .06,
                                      ),
                                      onTap: () async {
                                        if (favorite.provider != null) {
                                          await providerController.toggleFavorite(
                                              favorite.provider!, context);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  "${favorite.provider?.name}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var items
                                        in favorite.provider?.type ?? []) ...[
                                      Container(
                                        margin: const EdgeInsets.only(right: 5),
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          items.type?.type?.toString() ?? '',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: MyApp2.fontSize14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (favorite.provider?.state == '1') {
                          final userEmail = Auth2.user?.email ?? "";
                          final cartEmpty = cart.cart?.cart_items?.isEmpty ?? true;

                          if (userEmail == "info@eboro.com" || cartEmpty) {
                            await providerController.updateProduct(
                                favorite.provider, context, true);
                          } else {
                            cart.restCartItem(context);
                            cart.cart?.cart_items?.clear();
                            await providerController.updateProduct(
                                favorite.provider, context, true);
                          }
                        } else {
                          Auth2.show("closed");
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.black),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // الوقت
                              Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.clock,
                                    color: Colors.grey[400],
                                    size: MyApp2.fontSize16,
                                  ),
                                  const SizedBox(width: 4),
                                  Builder(
                                    builder: (context) {
                                      final d = _parseDurationMinutes(favorite
                                          .provider?.Delivery?.Duration);
                                      if (d == 0) {
                                        return Text(
                                          "0 Min",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: MyApp2.fontSize14,
                                          ),
                                        );
                                      }
                                      final text =
                                          "${d.toStringAsFixed(0)} - ${(d + 5).toStringAsFixed(0)} Min";
                                      return Text(
                                        text,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: MyApp2.fontSize14,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              // الشحن
                              Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.motorcycle,
                                    color: Colors.grey[400],
                                    size: MyApp2.fontSize16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    favorite.provider?.Delivery != null
                                        ? "${favorite.provider?.Delivery!.shipping} €"
                                        : "0 €",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: MyApp2.fontSize14,
                                    ),
                                  ),
                                ],
                              ),

                              // التقييم
                              Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.star,
                                    color: Colors.amberAccent,
                                    size: MyApp2.fontSize16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${favorite.provider?.rateRatio ?? 0}%",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: MyApp2.fontSize14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
