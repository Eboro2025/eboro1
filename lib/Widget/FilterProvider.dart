import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Favorite.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/API/Rates.dart';
import 'package:eboro/Helper/FilterData.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class FilterProvider extends StatefulWidget {
  @override
  FilterProvider2 createState() => FilterProvider2();
}

class FilterProvider2 extends State<FilterProvider> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProviderController>(context);
    return ListView(children: [
      Column(children: <Widget>[
        for (FilterData filter in Provider2.filter!) ...[
          if (filter.providers!.state == '1') ...[
            Padding(
                padding:
                    EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
                child: Card(
                    semanticContainer: true,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    elevation: 3,
                    child: Column(
                      children: [
                        GestureDetector(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: fixImageUrl(
                                    filter.providers!.logo.toString()),
                                useOldImageOnUrlChange: true,
                                progressIndicatorBuilder:
                                    (context, url, downloadProgress) =>
                                        CircularProgressIndicator(
                                            value: downloadProgress.progress),
                                errorWidget: (context, url, error) => Container(
                                  alignment: Alignment.topLeft,
                                  height:
                                      MediaQuery.of(context).size.height * .2,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image:
                                          AssetImage('images/icons/logo.png'),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (filter.providers!.offer != null)
                                        (Container(
                                          padding: EdgeInsets.only(
                                              left: 10, right: 10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(50.0),
                                              gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFFE43945),
                                                    Color(0xFFC12732),
                                                  ])),
                                          child: Text(
                                            filter.providers!.offer!.offer_value
                                                .toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ))
                                    ],
                                  ),
                                ),
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  padding: EdgeInsets.all(10),
                                  alignment: Alignment.topLeft,
                                  height:
                                      MediaQuery.of(context).size.height * .2,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      colorFilter: new ColorFilter.mode(
                                          Colors.black.withOpacity(.3),
                                          BlendMode.darken),
                                      image: imageProvider,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (filter.providers!.state == '0')
                                        (Container(
                                          padding: EdgeInsets.only(
                                              left: 10, right: 10),
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50)),
                                              gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFFE43945),
                                                    Color(0xFFC12732),
                                                  ])),
                                          child: Text(
                                            "Closed",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        )),
                                      if (filter.providers!.offer != null)
                                        (Container(
                                          padding: EdgeInsets.only(
                                              left: 10, right: 10),
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(50),
                                                  bottomLeft:
                                                      Radius.circular(50)),
                                              gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFFE43945),
                                                    Color(0xFFC12732),
                                                  ])),
                                          child: Text(
                                            filter.providers!.offer!.offer_value
                                                .toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        )),
                                      Container(
                                        child: GestureDetector(
                                          child: provider.Favorites!
                                                      .firstWhereOrNull(
                                                          (item) =>
                                                              item.provider!
                                                                  .id ==
                                                              filter.providers!
                                                                  .id) !=
                                                  null
                                              ? Icon(
                                                  FontAwesomeIcons.heartCrack,
                                                  color: myColor,
                                                  size: MyApp2.W! * .06,
                                                )
                                              : Icon(
                                                  FontAwesomeIcons.heart,
                                                  color: myColor,
                                                  size: MyApp2.W! * .06,
                                                ),
                                          onTap: () async {
                                            Progress.progressDialogue(context);
                                            Favorite2.removeFromFavorite(
                                                filter.providers!.id, context);
                                            await provider.updateProvider(
                                                provider.categoryId);
                                            Progress.dimesDialog(context);
                                          },
                                        ),
                                        padding:
                                            EdgeInsets.only(top: 5, right: 5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Center(
                                child: Container(
                                    child: Column(
                                  children: [
                                    Text(
                                      filter.providers!.name.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        for (var items
                                            in filter.providers!.type!)
                                          Text(
                                            items.type!.type.toString() + " ",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                backgroundColor:
                                                    Colors.black54),
                                          )
                                      ],
                                    ),
                                  ],
                                )),
                              ),
                            ],
                          ),
                          onTap: () async {
                            if (filter.providers!.state == '1')
                              await provider.updateProduct(
                                  filter.providers!, context, true);
                            else
                              Auth2.show("closed");
                          },
                        ),
                        Container(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      FaIcon(
                                        FontAwesomeIcons.clock,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                      Text(
                                        ' ' +
                                            filter.providers!.duration
                                                .toString() +
                                            "-" +
                                            (int.parse(filter
                                                        .providers!.duration!) +
                                                    5)
                                                .toString() +
                                            ' Min',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ]),
                                    Row(children: [
                                      FaIcon(
                                        FontAwesomeIcons.motorcycle,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                      Text(
                                        ' ' +
                                            filter.providers!.Delivery!.shipping
                                                .toString() +
                                            ' € ',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ]),
                                    Row(
                                      children: [
                                        Container(
                                          child: GestureDetector(
                                            child: Rates2.rate!.length > 0 &&
                                                    Rates2.rate!
                                                        .where((item) => item
                                                            .provider!.id
                                                            .toString()
                                                            .contains(filter
                                                                .providers!.id
                                                                .toString()))
                                                        .isNotEmpty
                                                ? FaIcon(
                                                    FontAwesomeIcons
                                                        .solidThumbsUp,
                                                    color: Colors.amberAccent,
                                                    size: 20,
                                                  )
                                                : FaIcon(
                                                    FontAwesomeIcons.thumbsUp,
                                                    color: Colors.grey[400],
                                                    size: 20,
                                                  ),
                                            onTap: () {},
                                          ),
                                          padding: EdgeInsets.only(
                                              left: 5, right: 5),
                                        ),
                                        Text(
                                          filter.providers!.rateRatio
                                                  .toString() +
                                              " %" +
                                              "(${int.parse(filter.providers!.rate_user!) > 999 ? "+${(int.parse(filter.providers!.rate_user!) / 1000).toStringAsFixed(0)}k" : filter.providers!.rate_user.toString()})",
                                          // "100 %" + "(1000)",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ))
                      ],
                    )))
          ]
        ]
      ])
    ]);
  }
}
