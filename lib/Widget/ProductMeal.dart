import 'package:eboro/API/Provider.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// شاشة عرض عرض الوجبة (Meal Offer)
/// بتظهر لما المستخدم يضغط على عرض "Buy X Get X"
/// ------------------------------------------------------------
class ProductMeal extends StatefulWidget {
  final int? productID; // رقم المنتج المرتبط بالعرض

  ProductMeal({Key? key, required this.productID}) : super(key: key);

  @override
  ProductMeal2 createState() => ProductMeal2();
}

class ProductMeal2 extends State<ProductMeal> {

  @override
  void initState() {
    super.initState();

    // طباعة الـ ID للتأكد إن العرض جاي للصفحة صح
    // print(widget.productID);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, top: 0, bottom: 0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          /// كارد العرض الكبير
          Card(
            semanticContainer: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 3,

            child: Container(
              /// خلفية الصورة
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('images/icons/coc.png'),
                  colorFilter: ColorFilter.mode(
                    myColor.withOpacity(.6),
                    BlendMode.darken,
                  ),
                  fit: BoxFit.cover,
                ),
              ),

              padding: const EdgeInsets.all(15),
              height: MediaQuery.of(context).size.height * .7,

              child: Row(
                children: [
                  /// الجزء الموجود في النص (نص العرض)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .8,

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        /// ---------------------------
                        /// عنوان العرض الأساسي
                        /// Buy X Pizza to get...
                        /// ---------------------------
                        Text(
                          'Buy '
                          + Provider2.meal!
                              .where((item) =>
                                  item.Product!.id.toString() ==
                                  widget.productID.toString())
                              .first
                              .value
                              .toString()
                          + ' '
                          + Provider2.meal!
                              .where((item) =>
                                  item.Product!.id.toString() ==
                                  widget.productID.toString())
                              .first
                              .Product!
                              .name
                              .toString()
                          + ' to get ',
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        /// ---------------------------
                        /// المنتجات اللي المستخدم يحصل عليها مجاناً
                        /// (Buy X get these products)
                        /// ---------------------------
                        for (int i = 0;
                            i <
                                Provider2.meal![0].products!.length;
                            i++)
                          Text(
                            Provider2.meal!
                                    .where((item) =>
                                        item.Product!.id.toString() ==
                                        widget.productID.toString())
                                    .first
                                    .value
                                    .toString() +
                                ' ' +
                                Provider2.meal!
                                    .where((item) =>
                                        item.Product!.id.toString() ==
                                        widget.productID.toString())
                                    .first
                                    .products![i]
                                    .Product!
                                    .name
                                    .toString(),
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
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
    );
  }
}
