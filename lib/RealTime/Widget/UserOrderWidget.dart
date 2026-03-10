import 'package:date_format/date_format.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserOrderWidget extends StatefulWidget {
  final int? index;

  const UserOrderWidget({Key? key, this.index}) : super(key: key);

  @override
  UserOrder2 createState() => new UserOrder2();
}

class UserOrder2 extends State<UserOrderWidget> {
  DateTime? _safeParseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final raw = value.trim();
    DateTime? parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed;
    }

    final normalized = raw.replaceAllMapped(
      RegExp(r'(\d{2}:\d{2}:\d{2})(\d+)(Z?)$'),
      (m) => '${m[1]}.${m[2]}${m[3] ?? ''}',
    );
    parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }

    final truncMatch =
        RegExp(r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})').firstMatch(raw);
    if (truncMatch != null) {
      final suffix = raw.endsWith('Z') ? 'Z' : '';
      return DateTime.tryParse('${truncMatch.group(1)}$suffix');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final order = Provider.of<UserOrderProvider>(context);

    if (order.order == null || order.order!.isEmpty) {
      return Container();
    }

    if (widget.index == null || widget.index! >= order.order!.length) {
      return Container();
    }

    final int i = widget.index!;
    final createdAt = _safeParseDate(order.order![i].created_at);

    return Container(
      padding: EdgeInsets.only(right: 15, left: 15, top: 5, bottom: 5),
      child: Stack(alignment: Alignment.center, children: [
        Container(
          padding: EdgeInsets.only(right: 5, left: 5, top: 5, bottom: 5),
          child: GestureDetector(
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 3,
                      blurRadius: 3,
                    ),
                  ],
                ),
                width: MediaQuery.of(context).size.width,
                child: Container(
                  padding:
                      EdgeInsets.only(right: 5, left: 5, top: 10, bottom: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            if (order.order![i].status == 'pending')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.deepOrange),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/pending.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            if (order.order![i].status == 'in progress')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.lightBlue),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/sync.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.blue,
                                ),
                              ),
                            if (order.order![i].status == 'to delivering' ||
                                order.order![i].status == 'on way')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.cyan[900]!),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/shopping-bagg.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.cyan[900],
                                ),
                              ),
                            if (order.order![i].status == 'on delivering')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.indigo),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/scooterr.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.indigo,
                                ),
                              ),
                            if (order.order![i].status == 'delivered')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.amber),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/checkk.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.amber,
                                ),
                              ),
                            if (order.order![i].status == 'cancelled' ||
                                order.order![i].status == 'interrupt')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.red),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/close.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.red,
                                ),
                              ),
                            if (order.order![i].status == 'complete')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.green),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/check.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.green,
                                ),
                              ),
                            if (order.order![i].status == 'User Not Found')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.orange),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/unknown.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.orange,
                                ),
                              ),
                            if (order.order![i].status == 'SyS_cancelled')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.deepPurple),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/sys.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            if (order.order![i].status == 'refund')
                              Container(
                                padding: EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.cyan),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.0)),
                                ),
                                child: Image.asset(
                                  'images/icons/refund.png',
                                  height: 25,
                                  width: 25,
                                  color: Colors.cyan,
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Text('#' + order.order![i].id.toString(),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: MyApp2.fontSize14)),
                              if (order.order![i].branch?.name != null)
                                Text(order.order![i].branch!.name!,
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: MyApp2.fontSize14,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              Text(
                                createdAt != null
                                    ? "${formatDate(createdAt, [
                                            dd,
                                            '/',
                                            mm,
                                            '/',
                                            yyyy
                                          ]).toString()} ${formatDate(createdAt, [
                                            hh,
                                            ':',
                                            nn,
                                            " ",
                                            am
                                          ])}"
                                    : "N/A",
                                style: TextStyle(
                                    fontSize: MyApp2.fontSize12,
                                    color: Colors.grey),
                              ),
                              if (order.order![i].content != null &&
                                  order.order![i].content!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    order.order![i].content!
                                        .where((c) => c.product?.name != null)
                                        .map((c) =>
                                            "${c.product!.name!}${c.qty != null && c.qty! > 1 ? ' x${c.qty}' : ''}")
                                        .join(', '),
                                    style: TextStyle(
                                      fontSize: MyApp2.fontSize12,
                                      color: Colors.black54,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(order.order![i].total_price.toString() + ' € ',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: MyApp2.fontSize14)),
                            if (order.order![i].status == 'pending')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("pending")}',
                                  style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: MyApp2.fontSize14)),
                            if (order.order![i].status == 'in progress')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("in_progress")}',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: MyApp2.fontSize14)),
                            if (order.order![i].status == 'to delivering' ||
                                order.order![i].status == 'on way')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("to_delivering")}',
                                  style: TextStyle(
                                      color: Colors.cyan[900],
                                      fontSize: MyApp2.fontSize14)),
                            if (order.order![i].status == 'on delivering')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("on_delivering")}',
                                  style: TextStyle(
                                      color: Colors.indigo,
                                      fontSize: MyApp2.fontSize14)),
                            if (order.order![i].status == 'delivered')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("delivered")}',
                                  style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: MyApp2.fontSize14)),
                            if (order.order![i].status == 'complete')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("complete")}',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: MyApp2.fontSize12)),
                            if (order.order![i].status == 'cancelled' ||
                                order.order![i].status == 'interrupt')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("cancelled")}',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: MyApp2.fontSize14)),
                            if (order.order![i].status == 'User Not Found')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("user_not_found")}',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: MyApp2.fontSize14)),
                            if (order.order![i].status == 'SyS_cancelled')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("SyS_cancelled")}',
                                  style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontSize: MyApp2.fontSize14)),
                            if (order.order![i].status == 'refund')
                              Text(
                                  '${AppLocalizations.of(context)!.translate("refund")}',
                                  style: TextStyle(
                                      color: Colors.cyan,
                                      fontSize: MyApp2.fontSize14)),
                          ],
                        ),
                      ]),
                )),
            onTap: () async {
              await order.updateSelectedOrder(context, i);
            },
          ),
        ),
      ]),
    );
  }
}
