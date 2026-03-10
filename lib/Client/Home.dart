export 'package:eboro/Client/Home.dart' show CartButton;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:date_format/date_format.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Categories.dart';
import 'package:eboro/All/language.dart';
import 'package:eboro/Auth/Profile.dart';
import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/Client/Contact Us/WriteContact.dart';
import 'package:eboro/Client/Location.dart';
import 'package:eboro/Client/MyCart.dart';
import 'package:eboro/Client/MyFavorit.dart';
import 'package:eboro/Providers/AllProviders.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../API/Provider.dart';

class Home extends StatefulWidget {
  @override
  Home2 createState() => Home2();
}

class Home2 extends State<Home> {
  bool isNavigationInProgress = false;

  @override
  void initState() {
    super.initState();
    isNavigationInProgress = false;
  }

  // Helper Functions
  Widget _statusIcon(String status) {
    final icons = {
      'pending': {
        'color': Colors.deepOrange,
        'path': 'images/icons/pending.png'
      },
      'in progress': {'color': Colors.blue, 'path': 'images/icons/sync.png'},
      'to delivering': {
        'color': Colors.cyan[900]!,
        'path': 'images/icons/shopping-bagg.png'
      },
      'on way': {
        'color': Colors.cyan[900]!,
        'path': 'images/icons/shopping-bagg.png'
      },
      'on delivering': {
        'color': Colors.indigo,
        'path': 'images/icons/scooterr.png'
      },
      'delivered': {'color': Colors.amber, 'path': 'images/icons/checkk.png'},
      // Add other status mappings here
    };

    final icon = icons[status] ??
        {'color': Colors.grey, 'path': 'images/icons/unknown.png'};

    return Container(
      padding: const EdgeInsets.all(7.5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: icon['color'] as Color),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Image.asset(
        icon['path'] as String,
        height: 25,
        width: 25,
        color: icon['color'] as Color,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'in progress':
        return Colors.blue;
      case 'to delivering':
      case 'on way':
        return Colors.cyan[900]!;
      case 'on delivering':
        return Colors.indigo;
      case 'delivered':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProviderController>(context, listen: false);
    final order = Provider.of<UserOrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: myColor,
        title: SetLocation(rout: "home"),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // مؤشر السلة - يظهر عندما يكون هناك عناصر في السلة
          Consumer<CartTextProvider>(
            builder: (context, cart, child) {
              final hasItems = cart.cart?.cart_items != null &&
                  cart.cart!.cart_items!.isNotEmpty;
              final itemCount = cart.cart?.cart_items
                      ?.fold<int>(0, (sum, item) => sum + (item.qty ?? 0)) ??
                  0;

              if (!hasItems) return const SizedBox.shrink();

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyCart()),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: myColor,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: myColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$itemCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
            children: [
              // Categories row
              SizedBox(
                height: 100, // Adjust height as needed
                child: ListView.builder(
                  padding: const EdgeInsets.all(5),
                  scrollDirection: Axis.horizontal,
                  itemCount: Categories2.categories?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    final cat = Categories2.categories![index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: GestureDetector(
                        onTap: () async {
                          if (Auth2.user?.activeLat == null ||
                              Auth2.user?.activeLat == 0 ||
                              Auth2.user?.activeLat == "") {
                            Auth2.show("Seleziona la posizione");
                          } else if (!isNavigationInProgress) {
                            isNavigationInProgress = true;
                            await Provider2.showFilter(
                              cat.id.toString(),
                              cat.name.toString(),
                              context,
                            );
                            await provider.Providers(
                              cat.id.toString(),
                              context,
                            );
                            // تأكد إن الـ context لسه mounted
                            if (!mounted) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllProviders(
                                  catID: cat.id.toString(),
                                  name: cat.name.toString(),
                                ),
                              ),
                            );
                            isNavigationInProgress = false;
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: cat.image.toString(),
                                fit: BoxFit.contain,
                                width: 70,
                                height: 70,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${cat.name}",
                              style: TextStyle(
                                fontSize: MyApp2.fontSize12,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Latest order box
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int i = 0; i < (order.order?.length ?? 0); i++)
                        if ([
                          "pending",
                          "in progress",
                          "to delivering",
                          "on way",
                          "on delivering",
                          "delivered"
                        ].contains(order.order![i].status))
                          Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 15),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  spreadRadius: 3,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await order.updateSelectedOrder(context, i);
                                  },
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      // Left Column: Status Icon
                                      _statusIcon(
                                          order.order![i].status ?? "pending"),

                                      // Middle Column: Order Details
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '#${order.order![i].id}',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: MyApp2.fontSize14,
                                                ),
                                              ),
                                              if (order
                                                      .order![i].branch?.name !=
                                                  null)
                                                Text(
                                                  order.order![i].branch!.name!,
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: MyApp2.fontSize12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              Builder(builder: (context) {
                                                final rawDate =
                                                    order.order![i].created_at;
                                                DateTime createdAt;
                                                try {
                                                  createdAt = rawDate != null &&
                                                          rawDate.isNotEmpty
                                                      ? safeDateParse(rawDate)
                                                      : DateTime(2025, 1, 1);
                                                } catch (_) {
                                                  createdAt =
                                                      DateTime(2025, 1, 1);
                                                }
                                                return Text(
                                                  "${formatDate(createdAt, [
                                                        dd,
                                                        '/',
                                                        mm,
                                                        '/',
                                                        yyyy
                                                      ])} "
                                                  "${formatDate(createdAt, [
                                                        hh,
                                                        ':',
                                                        nn,
                                                        ' ',
                                                        am
                                                      ])}",
                                                  style: TextStyle(
                                                    fontSize: MyApp2.fontSize12,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              }),
                                              if (order.order![i].content !=
                                                      null &&
                                                  order.order![i].content!
                                                      .isNotEmpty)
                                                Text(
                                                  order.order![i].content!
                                                      .where((c) =>
                                                          c.product != null)
                                                      .map((c) => (c.qty !=
                                                                  null &&
                                                              c.qty! > 1)
                                                          ? '${c.product!.name} x${c.qty}'
                                                          : c.product!.name ??
                                                              '')
                                                      .join(', '),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: MyApp2.fontSize12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Right Column: Price and Status Text
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${order.order![i].total_price} €',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: MyApp2.fontSize14,
                                            ),
                                          ),
                                          Text(
                                            AppLocalizations.of(context)!
                                                    .translate(order
                                                            .order![i].status ??
                                                        "pending") ??
                                                order.order![i].status ??
                                                "pending",
                                            style: TextStyle(
                                              color: _statusColor(
                                                  order.order![i].status ??
                                                      "pending"),
                                              fontSize: MyApp2.fontSize14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Builder(
                                    builder: (context) {
                                      return ElevatedButton.icon(
                                        icon: const Icon(Icons.shopping_cart),
                                        label: const Text("Reorder"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final cartProvider =
                                              Provider.of<CartTextProvider>(
                                                  context,
                                                  listen: false);
                                          final orderContent =
                                              order.order![i].content ?? [];
                                          for (final item in orderContent) {
                                            if (item.product != null) {
                                              // الحصول على provider_id من المنتج (provider.id فقط)
                                              final providerId = item.product!
                                                  .branch?.provider?.id;
                                              await cartProvider.addCartItem(
                                                null, // extras (if any, handle as needed)
                                                item.product!.id,
                                                item.qty ?? 1,
                                                providerId: providerId,
                                                context: context,
                                              );
                                            }
                                          }
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text("Order added to cart!"),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
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
      // ❌ drawer اتشال علشان تستخدم BottomSheet للأكاونت
    );
  }
}

/// CartButton widget always visible, even if cart is empty
class CartButton extends StatelessWidget {
  const CartButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartTextProvider>(context);
    final hasCart = cart.cart?.total_price != null &&
        cart.cart!.total_price!.toDouble() > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          final cartItems = cart.cart?.cart_items ?? [];
          if (cartItems.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.translate("cart_empty") ??
                      "Il carrello è vuoto",
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => MyCart()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: hasCart ? Colors.redAccent : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              if (hasCart)
                BoxShadow(
                  color: Colors.black45.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      color: hasCart ? Colors.white : Colors.black45),
                  if (hasCart && (cart.cart?.cart_items?.isNotEmpty ?? false))
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cart.cart!.cart_items!.fold<int>(0, (sum, item) => sum + (item.qty ?? 0))}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate("mycart"),
                style: TextStyle(
                  color: hasCart ? Colors.white : Colors.black45,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BottomSheet بتاع الأكاونت – نفس اللي كان في الـ Drawer
class AccountSheet extends StatelessWidget {
  final UserOrderProvider order;

  const AccountSheet({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Auth2.user;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الخط الصغير فوق الشيت
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // الهيدر (صورة + اسم + إيميل)
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade300,
                  child: ClipOval(
                    child: (user?.image != null && user!.image!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: user.image!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.grey,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? "",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            if (Auth2.user!.email != "info@eboro.com") ...[
              _accountItem(
                icon: Icons.person_outline_rounded,
                label: AppLocalizations.of(context)!.translate("myprofile"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyProfile(),
                    ),
                  );
                },
              ),
              _accountItem(
                icon: Icons.favorite_border,
                label: AppLocalizations.of(context)!.translate("myfavorite"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyFavorite(),
                    ),
                  );
                },
              ),
              _accountItem(
                icon: Icons.shopping_cart_outlined,
                label: AppLocalizations.of(context)!.translate("mycart"),
                onTap: () async {
                  final cart =
                      Provider.of<CartTextProvider>(context, listen: false);
                  await cart.updateCart();
                  Navigator.pop(context);
                  if (cart.cart!.total_price! > 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyCart(),
                      ),
                    );
                  } else {
                    Auth2.show("Cart is empty");
                  }
                },
              ),
              _accountItem(
                icon: Icons.shopping_bag_outlined,
                label: AppLocalizations.of(context)!.translate("myorders"),
                onTap: () {
                  Navigator.pop(context);
                  order.updateOpenOrder(context);
                },
              ),
            ],

            _accountItem(
              icon: Icons.language,
              label: AppLocalizations.of(context)!.translate("language"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Language(),
                  ),
                );
              },
            ),
            _accountItem(
              icon: Icons.person_add_outlined,
              label: 'Invita un amico',
              onTap: () {
                Navigator.pop(context);
                Share.share('Scarica Eboro e ordina i tuoi piatti preferiti! https://play.google.com/store/apps/details?id=com.codiano.eboro');
              },
            ),
            _accountItem(
              icon: Icons.info_outline,
              label: AppLocalizations.of(context)!.translate("contactus"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WriteContact(),
                  ),
                );
              },
            ),

            if (Auth2.user!.email != "info@eboro.com") ...[
              const Divider(),
              _accountItem(
                icon: Icons.restore_from_trash_rounded,
                label: AppLocalizations.of(context)!.translate("delete"),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext bc) {
                      return _deleteBottomSheet(context);
                    },
                  );
                },
              ),
            ],

            _accountItem(
              icon: Icons.logout,
              label: AppLocalizations.of(context)!.translate("logout"),
              onTap: () {
                Navigator.pop(context);
                Auth2.deleteToken(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _accountItem({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      icon,
      color: myColor,
      size: MyApp2.fontSize22,
    ),
    title: Text(
      label,
      style: TextStyle(
        fontSize: MyApp2.fontSize14,
        color: myColor2,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: onTap,
  );
}

Widget _deleteBottomSheet(BuildContext context) {
  return Container(
    child: Wrap(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.restore_from_trash_rounded),
          title: const Text('Delete Account'),
          onTap: () {
            Categories2.delete_user(context);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cancel),
          title: const Text('Cancel'),
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}
