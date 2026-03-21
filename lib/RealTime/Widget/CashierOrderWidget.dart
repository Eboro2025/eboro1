import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:date_format/date_format.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/CashierAPI.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/RealTime/Provider/CashierOrderProvider.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────
// Full Cashier Page: header + tabs (Attivo / Precedente) + Chiuso screen
// ─────────────────────────────────────────────────────────────

class CashierOrderWidget extends StatefulWidget {
  final String status; // kept for backward-compat, ignored when used as full page
  const CashierOrderWidget({Key? key, this.status = "active"}) : super(key: key);

  @override
  CashierOrderState createState() => CashierOrderState();
}

class CashierOrderState extends State<CashierOrderWidget>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? timer;
  final player = AudioPlayer();
  bool _isClosed = false;
  late TabController _tabController;

  final Set<int> _confirmingOrders = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    // Check initial branch status then start polling
    _initBranchStatus();
  }

  Future<void> _initBranchStatus() async {
    final orderProvider = Provider.of<CashierOrderProvider>(context, listen: false);
    await orderProvider.updateOrder();
    _syncBranchStatus(orderProvider);
    if (mounted) setState(() {});
    timer = Timer.periodic(const Duration(seconds: 10), (Timer t) => checkInternetState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    timer?.cancel();
    player.dispose();
    super.dispose();
  }

  // ─── Lifecycle: background → chiuso ───
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final orderProvider = Provider.of<CashierOrderProvider>(context, listen: false);
    final branchId = orderProvider.BranchStaff?[0].branch?.id;
    if (branchId == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      CashierAPI2().toggleBranchStatus(branchId, 1);
      if (player.state == PlayerState.playing) player.stop();
      setState(() => _isClosed = true);
    }
  }

  void _openBranch() async {
    final orderProvider = Provider.of<CashierOrderProvider>(context, listen: false);
    final branchId = orderProvider.BranchStaff?[0].branch?.id;
    if (branchId == null) {
      return;
    }

    final success = await CashierAPI2().toggleBranchStatus(branchId, 0);
    if (!success) {
      return;
    }

    // Switch screen immediately
    if (mounted) setState(() => _isClosed = false);

    // Refresh data in background
    try {
      await orderProvider.updateOrder();
      if (mounted) setState(() {});
    } catch (e) {
    }
  }

  void _closeBranch() async {
    final orderProvider = Provider.of<CashierOrderProvider>(context, listen: false);
    final branchId = orderProvider.BranchStaff?[0].branch?.id;
    if (branchId == null) return;

    final success = await CashierAPI2().toggleBranchStatus(branchId, 1);
    if (player.state == PlayerState.playing) player.stop();
    setState(() => _isClosed = true);
  }

  @override
  void didUpdateWidget(covariant CashierOrderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (player.state == PlayerState.playing) player.stop();
  }

  Future<void> checkInternetState() async {
    final orderProvider = Provider.of<CashierOrderProvider>(context, listen: false);
    await orderProvider.updateOrder();
    _syncBranchStatus(orderProvider);
    if (!_isClosed) {
      handleOrderSound(orderProvider);
    }
    if (mounted) setState(() {});
  }

  /// Sync _isClosed with the actual branch status from server
  /// BranchRescource returns status as "open" or "close"
  void _syncBranchStatus(CashierOrderProvider orderProvider) {
    final branch = orderProvider.BranchStaff?[0].branch;
    if (branch == null) return;
    final isServerOpen = branch.status?.toString().toLowerCase() == 'open';
    if (!isServerOpen && !_isClosed) {
      _isClosed = true;
      if (player.state == PlayerState.playing) player.stop();
    } else if (isServerOpen && _isClosed) {
      _isClosed = false;
    }
  }

  void handleOrderSound(CashierOrderProvider orderProvider) {
    if (orderProvider.All != null) {
      final hasPending = orderProvider.All!.any((o) => o.status!.toLowerCase() == "pending");
      if (hasPending && player.state != PlayerState.playing) {
        player.play(UrlSource('$globalUrl/public/uploads/sound/sound.mp3'), volume: 5);
      } else if (!hasPending && player.state == PlayerState.playing) {
        player.stop();
      }
    }
  }

  Future<void> refresh() async {
    final orderProvider = Provider.of<CashierOrderProvider>(context, listen: false);
    await orderProvider.updateOrder();
    setState(() {});
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isClosed) return _buildChiusoScreen();
    return _buildOpenScreen();
  }

  // ─── Parse today's open/close time from comma-separated branch data ───
  Map<String, String> _getTodayTimes() {
    final orderProvider = Provider.of<CashierOrderProvider>(context, listen: false);
    final branch = orderProvider.BranchStaff?[0].branch;
    if (branch == null) return {'open': '', 'close': ''};

    final openDays = branch.open_days?.split(',') ?? [];
    final openTimes = branch.open_time?.split(',') ?? [];
    final closeTimes = branch.close_time?.split(',') ?? [];

    // Day names matching Laravel's Carbon englishDayOfWeek
    final now = DateTime.now();
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayName = dayNames[now.weekday - 1]; // weekday: 1=Mon, 7=Sun

    // Find today's index in open_days
    for (int i = 0; i < openDays.length; i++) {
      if (openDays[i].trim() == todayName) {
        final todayOpen = i < openTimes.length ? openTimes[i].trim() : '';
        final todayClose = i < closeTimes.length ? closeTimes[i].trim() : '';
        return {'open': todayOpen, 'close': todayClose};
      }
    }
    return {'open': '', 'close': ''};
  }

  // ─────────────────────────────────────────
  //  OPEN STATE: green header + tabs + orders
  // ─────────────────────────────────────────
  Widget _buildOpenScreen() {
    final orderProvider = Provider.of<CashierOrderProvider>(context);
    final branch = orderProvider.BranchStaff?[0].branch;
    final branchName = branch?.name ?? '';
    final todayTimes = _getTodayTimes();
    final closeTime = todayTimes['close'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(branchName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            if (closeTime.isNotEmpty)
              Text('Aperto fino alle $closeTime', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _closeBranch,
              icon: const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
              label: const Text('Chiudi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 0,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Attivo'),
            Tab(text: 'Precedente'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(orderProvider, "active"),
          _buildOrderList(orderProvider, "previous"),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  ORDER LIST for a given tab
  // ─────────────────────────────────────────
  Widget _buildOrderList(CashierOrderProvider orderProvider, String status) {
    List<String> allowStates = [];
    if (status == "active") {
      allowStates = ["pending", "in progress", "to delivering", "on way", "on delivering", "delivered"];
    } else {
      allowStates = ['complete', 'user not found', 'cancelled', 'interrupt', 'SyS_cancelled', 'doneRefund'];
    }

    final newOrder = orderProvider.All?.where((o) => allowStates.contains(o.status.toString())).toList() ?? [];

    return RefreshIndicator(
      onRefresh: refresh,
      child: newOrder.isEmpty
          ? ListView(children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Center(child: Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey[300])),
              const SizedBox(height: 12),
              Center(child: Text(
                status == "active" ? 'Nessun ordine attivo' : 'Nessun ordine precedente',
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              )),
            ])
          : ListView(
              children: newOrder.map((order) {
                if (status == "active" &&
                    (DateTime.now().getLocalTimeZone().difference(safeDateParse("${order.ordar_at}").getLocalTimeZone()).inHours > 3))
                  return const SizedBox();

                return _buildOrderCard(orderProvider, order, status);
              }).toList(),
            ),
    );
  }

  // ─────────────────────────────────────────
  //  SINGLE ORDER CARD
  // ─────────────────────────────────────────
  Widget _buildOrderCard(CashierOrderProvider orderProvider, OrderData order, String status) {
    return GestureDetector(
      onTap: () async {
        Progress.progressDialogue(context);
        final fetched = await CashierAPI2().getOrders(order.id, orderProvider.BranchStaff![0].branch!.id);
        Progress.dimesDialog(context);
        if (fetched != null && fetched.isNotEmpty) {
          player.stop();
          orderProvider.OOrder = fetched[0];
          _showOrderDetail(fetched[0]);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _getStatusIcon(order.status!),
                              getStatusText(order.status!),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('#${order.id}', style: TextStyle(color: Colors.black45, fontSize: MyApp2.fontSize14)),
                        if (order.status!.toLowerCase() == "on way" && order.Delivery_time.toString() != "0")
                          Text('${order.Delivery_time} min', style: TextStyle(fontSize: MyApp2.fontSize24)),
                        if (order.status!.toLowerCase() == "on way" && order.Delivery_time.toString() == "0")
                          Text('${AppLocalizations.of(context)!.translate("arrived")}',
                              style: TextStyle(fontSize: MyApp2.fontSize24, color: myColor, fontWeight: FontWeight.w900)),
                        if (order.status!.toLowerCase() != "on way") ...[
                          Text(formatDate(safeDateParse(order.ordar_at.toString()).getLocalTimeZone(), [dd, '/', mm, '/', yyyy]),
                              style: TextStyle(fontSize: MyApp2.fontSize14)),
                          Text(formatDate(safeDateParse(order.ordar_at.toString()).getLocalTimeZone(), [hh, ':', nn, " ", am]),
                              style: TextStyle(fontSize: MyApp2.fontSize14)),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('${AppLocalizations.of(context)!.translate("price")} ',
                              style: TextStyle(color: Colors.black45, fontSize: MyApp2.fontSize14)),
                          Text('${order.total_price} €', style: TextStyle(color: Colors.black, fontSize: MyApp2.fontSize14)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (order.Delivery_time.toString() != "0" && status == "active")
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green[200], borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('${AppLocalizations.of(context)!.translate("time")}',
                                style: TextStyle(color: Colors.black45, fontSize: MyApp2.fontSize14)),
                            Text(
                                '${safeDateParse("${order.ordar_at}").add(Duration(minutes: order.Delivery_time ?? 1)).getLocalTimeZone().difference(DateTime.now().getLocalTimeZone()).inMinutes} min',
                                style: TextStyle(fontSize: MyApp2.fontSize14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),

                // ── Customer order count badge ──
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (order.user_orders_count ?? 0) == 0 ? Colors.green[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (order.user_orders_count ?? 0) == 0 ? Colors.green : Colors.blue,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (order.user_orders_count ?? 0) == 0 ? Icons.fiber_new_rounded : Icons.repeat_rounded,
                          size: 16,
                          color: (order.user_orders_count ?? 0) == 0 ? Colors.green : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (order.user_orders_count ?? 0) == 0
                              ? 'Nuovo Cliente'
                              : '${order.user_orders_count} ordini precedenti',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (order.user_orders_count ?? 0) == 0 ? Colors.green[800] : Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Action buttons ──
                if (status == "active") ...[
                  if (order.status!.toLowerCase() == 'pending')
                    _buildActionBtn(context, order, 'in progress', 'Accetta', Colors.green),
                  if (order.status!.toLowerCase() == 'in progress')
                    _buildActionBtn(context, order, 'to delivering', 'Invia', Colors.blue),
                  if (order.status!.toLowerCase() == 'to delivering')
                    _buildActionBtn(context, order, 'on delivering', 'Consegna', Colors.orange),
                  if (order.status!.toLowerCase() == 'on delivering')
                    _buildActionBtn(context, order, 'complete', 'Completato', Colors.indigo),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  ACTION BUTTON (double-click confirm)
  // ─────────────────────────────────────────
  Widget _buildActionBtn(BuildContext context, OrderData order, String nextStatus, String label, Color color) {
    final isConfirming = _confirmingOrders.contains(order.id);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isConfirming ? Colors.green : color,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(isConfirming ? 'Conferma' : label, style: const TextStyle(fontSize: 14, color: Colors.white)),
          onPressed: () async {
            if (!isConfirming) {
              setState(() => _confirmingOrders.add(order.id!));
              return;
            }
            final cashierOrder = Provider.of<CashierOrderProvider>(context, listen: false);
            try {
              await cashierOrder.ordersStateEdit(nextStatus, order.id.toString(), null, context);
              setState(() => _confirmingOrders.remove(order.id));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
            }
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  ORDER DETAIL BOTTOM SHEET
  // ═══════════════════════════════════════════
  void _showOrderDetail(OrderData order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  // Header: order ID + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ordine #${order.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(order.status ?? '').withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(order.status ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _statusColor(order.status ?? ''))),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Customer info
                  if (order.user != null) ...[
                    Row(children: [
                      const Icon(Icons.person_rounded, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order.user!.name ?? 'Cliente', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                      if (order.user!.mobile != null && order.user!.mobile!.isNotEmpty)
                        Text(order.user!.mobile!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ]),
                    const SizedBox(height: 6),
                  ],

                  // Address
                  if (order.address != null && order.address!.isNotEmpty) ...[
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order.address!, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                    ]),
                    const SizedBox(height: 6),
                  ],

                  // Comment
                  if (order.comment != null && order.comment!.isNotEmpty) ...[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order.comment!, style: TextStyle(fontSize: 13, color: Colors.orange[800]))),
                    ]),
                    const SizedBox(height: 6),
                  ],

                  const Divider(height: 24),

                  // Items header
                  const Text('Prodotti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Items list
                  if (order.content != null)
                    ...order.content!.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                            child: Text('${item.qty}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product?.name ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                if (item.extras != null && item.extras!.isNotEmpty)
                                  Text(item.extras!.map((e) => e.name ?? '').join(', '),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                if (item.sauces != null && item.sauces!.isNotEmpty)
                                  Text(item.sauces!.map((s) => s.name ?? '').join(', '),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                if (item.comment != null && item.comment!.isNotEmpty)
                                  Text('Nota: ${item.comment}',
                                      style: TextStyle(fontSize: 12, color: Colors.orange[700], fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                          Text('${item.price} \u20ac', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),

                  const Divider(height: 24),

                  // Totals
                  _totalRow('Subtotale', '${order.total_price} \u20ac'),
                  if (order.tax_price != null) _totalRow('Tasse', '${order.tax_price} \u20ac'),
                  if (order.shipping_price != null) _totalRow('Consegna', '${order.shipping_price} \u20ac'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Totale', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text('${order.total_price} \u20ac', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  // Payment method
                  if (order.payment != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(order.payment == '1' ? Icons.credit_card_rounded : Icons.money_rounded, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(order.payment == '1' ? 'Carta' : 'Contanti', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    ]),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _totalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.amber;
      case 'in progress': return Colors.blue;
      case 'to delivering': case 'on way': return Colors.cyan.shade900;
      case 'on delivering': return Colors.indigo;
      case 'delivered': return Colors.amber;
      case 'complete': return Colors.green;
      case 'cancelled': case 'interrupt': return Colors.red;
      default: return Colors.grey;
    }
  }

  // ═══════════════════════════════════════════
  //  CHIUSO SCREEN
  // ═══════════════════════════════════════════
  Widget _buildChiusoScreen() {
    final orderProvider = Provider.of<CashierOrderProvider>(context, listen: false);
    final branch = orderProvider.BranchStaff?[0].branch;
    final branchName = branch?.name ?? '';
    final todayTimes = _getTodayTimes();
    final openTime = todayTimes['open'] ?? '';
    final closeTime = todayTimes['close'] ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shop icon with ZzZ
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded, size: 70, color: Colors.white),
                      ),
                      const Positioned(
                        top: -8,
                        right: -8,
                        child: Text('zzZ',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70, fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.nightlight_round, size: 28, color: Colors.amber[200]),
                  const SizedBox(height: 20),
                  const Text('Chiuso',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  if (branchName.isNotEmpty)
                    Text(branchName,
                        style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (openTime.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text('Apre alle $openTime',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center),
                          if (closeTime.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Orario: $openTime - $closeTime',
                                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                                textAlign: TextAlign.center),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _openBranch,
                      icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                      label: const Text('Tocca per aprire',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Status helpers ───
  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Image.asset('images/icons/pending.png', height: 25, width: 25, color: Colors.deepOrange);
      case 'in progress':
        return Image.asset('images/icons/sync.png', height: 25, width: 25, color: Colors.blue);
      case 'to delivering':
      case 'on way':
        return Image.asset('images/icons/shopping-bagg.png', height: 25, width: 25, color: Colors.cyan[900]);
      case 'on delivering':
        return Image.asset('images/icons/scooterr.png', height: 25, width: 25, color: Colors.indigo);
      case 'delivered':
        return Image.asset('images/icons/checkk.png', height: 25, width: 25, color: Colors.amber);
      case 'complete':
        return Image.asset('images/icons/check.png', height: 25, width: 25, color: Colors.green);
      case 'cancelled':
      case 'interrupt':
        return Image.asset('images/icons/close.png', height: 25, width: 25, color: Colors.red);
      case 'User Not Found':
        return Image.asset('images/icons/unknown.png', height: 25, width: 25, color: Colors.orange);
      case 'SyS_cancelled':
        return Image.asset('images/icons/sys.png', height: 25, width: 25, color: Colors.deepPurple);
      default:
        return Container();
    }
  }

  Widget getStatusText(String status) {
    switch (status) {
      case 'pending':
        return Text('${AppLocalizations.of(context)!.translate("pending")}', style: TextStyle(color: Colors.amber, fontSize: MyApp2.fontSize14));
      case 'in progress':
        return Text('${AppLocalizations.of(context)!.translate("in_progress")}', style: TextStyle(color: Colors.blue, fontSize: MyApp2.fontSize14));
      case 'to delivering':
      case 'on way':
        return Text('${AppLocalizations.of(context)!.translate("to_delivering")}', style: TextStyle(color: Colors.cyan[900], fontSize: MyApp2.fontSize14));
      case 'on delivering':
        return Text('${AppLocalizations.of(context)!.translate("on_delivering")}', style: TextStyle(color: Colors.indigo, fontSize: MyApp2.fontSize14));
      case 'delivered':
        return Text('${AppLocalizations.of(context)!.translate("delivered")}', style: TextStyle(color: Colors.amber, fontSize: MyApp2.fontSize14));
      case 'complete':
        return Text('${AppLocalizations.of(context)!.translate("complete")}', style: TextStyle(color: Colors.green, fontSize: MyApp2.fontSize14));
      case 'cancelled':
      case 'interrupt':
        return Text('${AppLocalizations.of(context)!.translate("cancelled")}', style: TextStyle(color: Colors.red, fontSize: MyApp2.fontSize14));
      case 'User Not Found':
        return Text('${AppLocalizations.of(context)!.translate("user_not_found")}', style: TextStyle(color: Colors.orange, fontSize: MyApp2.fontSize14));
      case 'SyS_cancelled':
        return Text('${AppLocalizations.of(context)!.translate("SyS_cancelled")}', style: TextStyle(color: Colors.deepPurple, fontSize: MyApp2.fontSize14));
      default:
        return Text(status, style: TextStyle(color: Colors.black, fontSize: MyApp2.fontSize14));
    }
  }
}
