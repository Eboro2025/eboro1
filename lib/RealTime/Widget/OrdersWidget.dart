import 'package:date_format/date_format.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:eboro/RealTime/Provider/OrdersProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrdersWidget extends StatelessWidget {
  final String? status;
  OrdersWidget({Key? key, required this.status}) : super(key: key);

  // ✅ safe fontSize
  double _fs([double add = 0]) => (MyApp2.fontSize14 ?? 14.0) + add;

  // ✅ opacity safe (بديل withOpacity لو عندك warnings)
  Color _op(Color c, double a) => c.withValues(alpha: a);

  String _safeStr(dynamic v, [String fallback = '']) =>
      (v == null) ? fallback : v.toString();

  // ---------- Status mapping ----------
  Color _statusColor(String? s) {
    final v = (s ?? '').toLowerCase();
    if (v == 'pending') return Colors.amber;
    if (v == 'in progress') return Colors.blue;
    if (v == 'to delivering' || v == 'on way') return Colors.cyan.shade800;
    if (v == 'on delivering') return Colors.indigo;
    if (v == 'delivered') return Colors.orange;
    if (v == 'complete') return Colors.green;
    if (v == 'cancelled' || v == 'interrupt') return Colors.red;
    if (v == 'user not found') return Colors.deepOrange;
    if (v == 'sys_cancelled') return Colors.deepPurple;
    if (v == 'donerefund' || v == 'doneRefund'.toLowerCase())
      return Colors.purple;
    return Colors.grey;
  }

  IconData _statusIcon(String? s) {
    final v = (s ?? '').toLowerCase();
    if (v == 'pending') return Icons.access_time_rounded;
    if (v == 'in progress') return Icons.sync_rounded;
    if (v == 'to delivering' || v == 'on way')
      return Icons.shopping_bag_rounded;
    if (v == 'on delivering') return Icons.delivery_dining_rounded;
    if (v == 'delivered') return Icons.check_circle_outline_rounded;
    if (v == 'complete') return Icons.verified_rounded;
    if (v == 'cancelled') return Icons.cancel_rounded;
    if (v == 'user not found') return Icons.help_outline_rounded;
    if (v == 'sys_cancelled') return Icons.shield_rounded;
    return Icons.receipt_long_rounded;
  }

  String _statusText(BuildContext context, String? s) {
    final v = (s ?? '').toLowerCase();
    if (v == 'pending')
      return AppLocalizations.of(context)!.translate("pending").toString();
    if (v == 'in progress')
      return AppLocalizations.of(context)!.translate("in_progress").toString();
    if (v == 'to delivering' || v == 'on way') {
      return AppLocalizations.of(context)!
          .translate("to_delivering")
          .toString();
    }
    if (v == 'on delivering')
      return AppLocalizations.of(context)!
          .translate("on_delivering")
          .toString();
    if (v == 'delivered')
      return AppLocalizations.of(context)!.translate("delivered").toString();
    if (v == 'complete')
      return AppLocalizations.of(context)!.translate("complete").toString();
    if (v == 'cancelled')
      return AppLocalizations.of(context)!.translate("cancelled").toString();
    if (v == 'user not found')
      return AppLocalizations.of(context)!
          .translate("user_not_found")
          .toString();
    if (v == 'sys_cancelled')
      return AppLocalizations.of(context)!
          .translate("SyS_cancelled")
          .toString();

    // refund label fallback (لو مفيش key)
    if (v == 'donerefund' || v == 'doneRefund'.toLowerCase()) {
      return (MyApp2.apiLang?.toString() ?? '').toLowerCase().contains('it')
          ? 'Rimborso'
          : 'Refund';
    }

    return s?.toString() ?? '';
  }

  String _priceText(OrderData? o) {
    // انت كنت مستخدم Delivery_Price في كودك القديم
    final p = _safeStr(o?.Delivery_Price, "0");
    return "$p €";
  }

  String _titleText(OrderData? o, BuildContext context) {
    // حاول تجيب اسم الفرع
    final branchName = o?.branch?.name;
    if (branchName != null && branchName.toString().isNotEmpty) {
      return branchName.toString();
    }

    // fallback
    return AppLocalizations.of(context)!.translate("order_id").toString();
  }

  String _dateTimeText(OrderData? o) {
    final createdAt = DateTime.tryParse(_safeStr(o?.created_at, ""));
    if (createdAt == null) return "-";
    final d = formatDate(createdAt, [dd, '/', mm, '/', yyyy]).toString();
    final t = formatDate(createdAt, [hh, ':', nn, " ", am]).toString();
    return "$d  •  $t";
  }

  @override
  Widget build(BuildContext context) {
    final order = Provider.of<OrdersProvider>(context);

    Future<void> refresh() async => order.updateOrder();

    // نفس منطق الفلاتر بتاعك (بس بدون late-crash)
    List<String?> allowStates = [];
    List<OrderData?> newOrder = [];

    final allOrders = order.All ?? [];

    if (MyApp2.type == "4") {
      if (Auth2.user?.online.toString() == '1') {
        if (status == "pending") {
          allowStates = ["to delivering"];
        } else if (status == "active") {
          allowStates = ['on way', 'on delivering', 'delivered'];
        } else if (status == "previous") {
          allowStates = [
            'complete',
            'user not found',
            'cancelled',
            'interrupt',
            'SyS_cancelled',
            'doneRefund'
          ];
        }
      }

      newOrder = allOrders
          .where((e) =>
              allowStates.contains(e.status.toString()) &&
              (e.delivery == null || e.delivery!.id == Auth2.user?.id))
          .toList();
    } else if (MyApp2.type == "3") {
      if (status == "pending") {
        allowStates = ["pending", ""];
      } else if (status == "active") {
        allowStates = ['on way', 'on delivering', 'delivered'];
      } else if (status == "previous") {
        allowStates = [
          'complete',
          'user not found',
          'cancelled',
          'interrupt',
          'SyS_cancelled',
          'doneRefund'
        ];
      }

      newOrder = allOrders
          .where((e) =>
              allowStates.contains(e.branch?.status.toString()) ||
              (allowStates.contains(e.status.toString()) &&
                  (e.delivery == null || e.delivery!.id == Auth2.user?.id)))
          .toList();
    } else {
      newOrder = allOrders;
    }

    final isAr =
        (MyApp2.apiLang?.toString() ?? 'ar').toLowerCase().contains('ar');

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        onRefresh: refresh,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          itemCount: newOrder.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final o = newOrder[i];

            final st = _safeStr(o?.status);
            final c = _statusColor(st);
            final icon = _statusIcon(st);

            final title = _titleText(o, context);
            final dateTime = _dateTimeText(o);
            final orderId = _safeStr(o?.id);
            final price = _priceText(o);

            final statusLabel = _statusText(context, st);

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => order.updateSelectedOrder(o?.id, context, true),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _op(Colors.black, 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: _op(Colors.grey, 0.12)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon box
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _op(c, 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _op(c, 0.28)),
                      ),
                      child: Icon(icon, color: c),
                    ),

                    const SizedBox(width: 12),

                    // Middle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID + title
                          Row(
                            children: [
                              Text(
                                "#$orderId",
                                style: TextStyle(
                                  fontSize: _fs(2),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: _fs(0),
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // datetime
                          Text(
                            dateTime,
                            style: TextStyle(
                              fontSize: _fs(-2),
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: price + chip
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: _fs(1),
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _op(c, 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _op(c, 0.25)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: _fs(-2),
                              fontWeight: FontWeight.w800,
                              color: c,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
