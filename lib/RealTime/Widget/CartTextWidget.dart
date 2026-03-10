import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import 'package:eboro/Client/Location.dart';
import 'package:eboro/Client/MyCart.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';

import '../../API/Auth.dart';

class CartTextWidget extends StatelessWidget
{

  @override
  Widget build(BuildContext context)
  {
    final cart = Provider.of<CartTextProvider>(context);
    return Auth2.user!.email != "info@eboro.com" ? badges.Badge(
      // badgeColor: Colors.white,
      position: BadgePosition.topEnd(top: 0, end: 3),
      // animationDuration: Duration(milliseconds: 300),
      badgeContent: Text(
          cart.cart == null ? "0" : cart.cart!.cart_items!.fold<int>(0, (sum, item) => sum + (item.qty ?? 0)).toString(),
          style: TextStyle(color: myColor)),
      child: IconButton(
        icon: new Icon(Icons.shopping_cart_outlined),
        onPressed: () async {
          final cart = Provider.of<CartTextProvider>(context);
          await cart.updateCart();
          await SetLocation2.authenticate();
          if(cart.cart!.total_price! > 0)
          {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyCart()));
          }
          else
          {
            Auth2.show("Cart is empty");
          }
        },
      ),
    ) : badges.Badge(
      // badgeColor: Colors.white,
      position: BadgePosition.topEnd(top: 0, end: 3),
      // animationDuration: Duration(milliseconds: 300),
      badgeContent: Text(
          "0",
          style: TextStyle(color: myColor)),
      child: IconButton(
        icon: new Icon(Icons.remove_shopping_cart_outlined),
        onPressed: () {
        },
      ),
    );
  }
}
//CartTextWidget()