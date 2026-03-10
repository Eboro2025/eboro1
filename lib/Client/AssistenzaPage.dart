import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Assistenza.dart';
import 'package:eboro/API/Chat.dart';
import 'package:eboro/API/Order.dart';
import 'package:eboro/Client/Assistenza/OrderSupportDetailPage.dart';
import 'package:eboro/Client/Assistenza/RefundListPage.dart';
import 'package:eboro/Client/Assistenza/TicketListPage.dart';
import 'package:eboro/Client/Contact%20Us/WriteContact.dart';
import 'package:eboro/Helper/ChatData.dart';
import 'package:eboro/Helper/ContactsData.dart';
import 'package:eboro/Helper/FaqData.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/Helper/RefundData.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AssistenzaPage extends StatefulWidget {
  const AssistenzaPage({Key? key}) : super(key: key);

  @override
  State<AssistenzaPage> createState() => _AssistenzaPageState();
}

class _AssistenzaPageState extends State<AssistenzaPage> {
  bool _loading = true;
  Map<String, List<FaqData>> _faqs = {};
  List<ContactsData> _tickets = [];
  List<RefundData> _refunds = [];
  Map<String, dynamic> _settings = {};
  List<OrderData> _orders = [];
  Map<int, List<ChatData>> _orderChats = {};

  bool get _isAr => (MyApp2.apiLang?.toString() ?? '').contains('2');

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<T> _safe<T>(Future<T> Function() fn, T fallback) async {
    try {
      return await fn().timeout(const Duration(seconds: 10));
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _loadAll() async {
    final api = AssistenzaAPI();

    // All calls run in parallel, each with 10s timeout + error catch
    final results = await Future.wait([
      _safe(() => api.getFaqs(), <String, List<FaqData>>{}),
      _safe(() => api.getUserTickets(), <ContactsData>[]),
      _safe(() => api.getUserRefundRequests(), <RefundData>[]),
      _safe(() => api.getSettings(), <String, dynamic>{}),
      _safe(() => Order2().getOrders().then((v) => v ?? <OrderData>[]), <OrderData>[]),
    ]);

    if (mounted) {
      setState(() {
        _faqs = results[0] as Map<String, List<FaqData>>;
        _tickets = results[1] as List<ContactsData>;
        _refunds = results[2] as List<RefundData>;
        _settings = results[3] as Map<String, dynamic>;
        _orders = results[4] as List<OrderData>;
        _loading = false;
      });
      _loadOrderChats();
    }
  }

  Future<void> _loadOrderChats() async {
    final recentOrders = _orders.take(5).where((o) => o.id != null).toList();
    if (recentOrders.isEmpty) return;

    final Map<int, List<ChatData>> chats = {};

    // Fetch all chats in parallel with timeout
    await Future.wait(recentOrders.map((o) async {
      try {
        final msgs = await Chat2().getChat(o.id).timeout(const Duration(seconds: 8));
        if (msgs != null && msgs.isNotEmpty) {
          chats[o.id!] = msgs;
        }
      } catch (_) {}
    }));

    if (mounted) {
      setState(() => _orderChats = chats);
    }
  }

  String _t(String it, String ar) => _isAr ? ar : it;

  Map<String, String> get _categoryLabels => {
    'ordini': _t('Ordini', 'Ordini'),
    'pagamenti': _t('Pagamenti', 'Pagamenti'),
    'consegna': _t('Consegna', 'Consegna'),
    'rimborsi': _t('Rimborsi', 'Rimborsi'),
    'account': _t('Account', 'Account'),
    'altro': _t('Altro', 'Altro'),
  };

  Map<String, String> get _reasonLabels => {
    'not_delivered': _t('Non consegnato', 'Non consegnato'),
    'bad_quality': _t('Qualità scadente', 'Qualità scadente'),
    'incomplete': _t('Ordine incompleto', 'Ordine incompleto'),
    'other': _t('Altro', 'Altro'),
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: myColor))
            : RefreshIndicator(
                color: myColor,
                onRefresh: _loadAll,
                child: CustomScrollView(
                  slivers: [
                    // Sliver AppBar with Hero
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      backgroundColor: myColor,
                      iconTheme: const IconThemeData(color: Colors.white),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [myColor, myColor.withOpacity(0.8), const Color(0xFF8B1A24)],
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 52, height: 52,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(Icons.support_agent, color: Colors.white, size: 30),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _t('Centro Assistenza', 'Centro Assistenza'),
                                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _t('Come possiamo aiutarti?', 'Come possiamo aiutarti?'),
                                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Actions
                            _buildQuickActions(),
                            const SizedBox(height: 24),

                            // Active Calls Section (active orders with rider/restaurant)
                            if (_activeOrders.isNotEmpty) ...[
                              _buildActiveCallsSection(),
                              const SizedBox(height: 24),
                            ],

                            // Active Chats Section
                            if (_orderChats.isNotEmpty) ...[
                              _buildActiveChatsSection(),
                              const SizedBox(height: 24),
                            ],

                            // My Orders Section
                            if (_orders.isNotEmpty) ...[
                              _buildOrdersSection(),
                              const SizedBox(height: 24),
                            ],

                            // My Tickets Section
                            if (_tickets.isNotEmpty) ...[
                              _buildTicketsSection(),
                              const SizedBox(height: 24),
                            ],

                            // My Refunds Section
                            if (_refunds.isNotEmpty) ...[
                              _buildRefundsSection(),
                              const SizedBox(height: 24),
                            ],

                            // FAQ Section
                            if (_faqs.isNotEmpty) ...[
                              _buildFaqSection(),
                              const SizedBox(height: 24),
                            ],

                            // Contact Info
                            _buildContactInfo(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Quick Actions Grid ───────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.chat_bubble_outline,
        label: _t('Contattaci', 'Contattaci'),
        color: Colors.purple,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WriteContact())),
      ),
      _QuickAction(
        icon: Icons.phone_outlined,
        label: _t('Chiama', 'Chiama'),
        color: Colors.green,
        onTap: _showPhoneSheet,
      ),
      _QuickAction(
        icon: Icons.assignment_outlined,
        label: _t('I Miei Ticket', 'I Miei Ticket'),
        color: Colors.blue,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketListPage())),
      ),
      _QuickAction(
        icon: Icons.currency_exchange,
        label: _t('Rimborsi', 'Rimborsi'),
        color: Colors.orange,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefundListPage())),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: actions.map((a) => _buildActionCard(a)).toList(),
    );
  }

  Widget _buildActionCard(_QuickAction action) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              action.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Phone Sheet ──────────────────────────────────────────

  void _showPhoneSheet() {
    final phones = _settings['assist_phones'] as List? ?? [];
    final mainPhone = _settings['phone'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return Directionality(
          textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999))),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.phone, color: myColor),
                        const SizedBox(width: 10),
                        Text(_t('Numeri di Assistenza', 'Numeri di Assistenza'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  if (mainPhone.isNotEmpty)
                    ListTile(
                      leading: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.phone, color: Colors.green, size: 20),
                      ),
                      title: Text(mainPhone, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(_t('Numero principale', 'Numero principale'), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      onTap: () => _callNumber(mainPhone),
                    ),
                  ...phones.map((p) => ListTile(
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.phone_outlined, color: Colors.blue, size: 20),
                    ),
                    title: Text(p.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => _callNumber(p.toString()),
                  )),
                  if (mainPhone.isEmpty && phones.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_t('Nessun numero disponibile', 'Nessun numero disponibile'), style: TextStyle(color: Colors.grey.shade500)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    await launchUrl(uri);
  }

  // ─── Tickets Section ──────────────────────────────────────

  Widget _buildTicketsSection() {
    final preview = _tickets.take(3).toList();
    return _buildSection(
      title: _t('I Miei Ticket', 'I Miei Ticket'),
      icon: Icons.assignment_outlined,
      seeAllTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketListPage())),
      child: Column(
        children: preview.map((t) => _buildTicketItem(t)).toList(),
      ),
    );
  }

  Widget _buildTicketItem(ContactsData t) {
    final isOpen = t.state == '1' || t.state == 'open';
    final hasReply = t.reply != null && t.reply!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (hasReply ? Colors.green : (isOpen ? Colors.orange : Colors.grey)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasReply ? Icons.reply : (isOpen ? Icons.hourglass_top : Icons.check_circle_outline),
              color: hasReply ? Colors.green : (isOpen ? Colors.orange : Colors.grey),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.subject ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  hasReply ? _t('Risposto', 'Risposto') : (isOpen ? _t('In attesa', 'In attesa') : _t('Chiuso', 'Chiuso')),
                  style: TextStyle(fontSize: 12, color: hasReply ? Colors.green : (isOpen ? Colors.orange : Colors.grey)),
                ),
              ],
            ),
          ),
          if (t.created_at != null)
            Text(t.created_at!.split(' ').first, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ─── Refunds Section ──────────────────────────────────────

  Widget _buildRefundsSection() {
    final preview = _refunds.take(3).toList();
    return _buildSection(
      title: _t('Le Mie Richieste di Rimborso', 'Le Mie Richieste di Rimborso'),
      icon: Icons.currency_exchange,
      seeAllTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefundListPage())),
      child: Column(
        children: preview.map((r) => _buildRefundItem(r)).toList(),
      ),
    );
  }

  Widget _buildRefundItem(RefundData r) {
    final statusColor = r.status == 'approved' ? Colors.green : (r.status == 'rejected' ? Colors.red : Colors.orange);
    final statusLabel = r.status == 'approved' ? _t('Approvato', 'Approvato') : (r.status == 'rejected' ? _t('Rifiutato', 'Rifiutato') : _t('In attesa', 'In attesa'));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(
              r.status == 'approved' ? Icons.check_circle : (r.status == 'rejected' ? Icons.cancel : Icons.hourglass_top),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_t("Ordine", "Ordine")} #${r.orderId}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                      child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                    const SizedBox(width: 8),
                    Text(_reasonLabels[r.reason] ?? r.reason ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          if (r.orderTotal != null)
            Text('${r.orderTotal} \u20ac', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ─── Orders Section ──────────────────────────────────────

  Widget _buildOrdersSection() {
    final preview = _orders.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long, color: myColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_t('I Miei Ordini', 'I Miei Ordini'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...preview.map((order) => _buildOrderPreviewCard(order)),
      ],
    );
  }

  Widget _buildOrderPreviewCard(OrderData order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final dateStr = order.created_at?.split(' ').first ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderSupportDetailPage(orderId: order.id!)),
        );
        _loadAll();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.receipt_long, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_t("Ordine", "Ordine")} #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                      ),
                      const SizedBox(width: 8),
                      Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${order.total_price ?? "0"} \u20ac',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Active Orders Helper ──────────────────────────────
  List<OrderData> get _activeOrders {
    return _orders.where((o) {
      final s = (o.status ?? '').toLowerCase();
      return s == 'pending' || s == 'in progress' || s == 'to delivering' ||
          s == 'on way' || s == 'on delivering';
    }).toList();
  }

  // ─── Active Calls Section ──────────────────────────────

  Widget _buildActiveCallsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.phone_in_talk, color: Colors.green, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_t('Chiamate Rapide', 'Chiamate Rapide'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _t('Chiama il fattorino o il ristorante per i tuoi ordini attivi', 'Chiama il fattorino o il ristorante per i tuoi ordini attivi'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        ..._activeOrders.take(3).map((order) => _buildCallCard(order)),
      ],
    );
  }

  Widget _buildCallCard(OrderData order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final riderName = order.delivery?.name;
    final riderPhone = order.delivery?.mobile;
    final restName = order.branch?.name;
    final restPhone = order.branch?.hotline;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order info row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('#${order.id} · $statusLabel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
              const Spacer(),
              if (restName != null)
                Text(restName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
            ],
          ),
          const SizedBox(height: 10),
          // Call buttons row
          Row(
            children: [
              // Call Rider
              Expanded(
                child: _callButton(
                  icon: Icons.delivery_dining,
                  label: riderName ?? _t('Fattorino', 'Fattorino'),
                  phone: riderPhone,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              // Call Restaurant
              Expanded(
                child: _callButton(
                  icon: Icons.restaurant,
                  label: restName ?? _t('Ristorante', 'Ristorante'),
                  phone: restPhone,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _callButton({
    required IconData icon,
    required String label,
    required String? phone,
    required Color color,
  }) {
    final hasPhone = phone != null && phone.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: hasPhone ? () => _callNumber(phone) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: hasPhone ? color.withOpacity(0.06) : Colors.grey.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasPhone ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: (hasPhone ? color : Colors.grey).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: hasPhone ? color : Colors.grey, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: hasPhone ? Colors.black87 : Colors.grey),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    hasPhone ? phone : _t('Non disponibile', 'Non disponibile'),
                    style: TextStyle(fontSize: 10, color: hasPhone ? color : Colors.grey.shade400),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasPhone)
              Icon(Icons.phone, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  // ─── Active Chats Section ──────────────────────────────

  Widget _buildActiveChatsSection() {
    // Sort by most recent message
    final sortedEntries = _orderChats.entries.toList()
      ..sort((a, b) {
        final aTime = a.value.last.created_at ?? '';
        final bTime = b.value.last.created_at ?? '';
        return bTime.compareTo(aTime);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble, color: Colors.purple, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_t('Chat Attive', 'Chat Attive'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${sortedEntries.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.purple),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sortedEntries.take(5).map((entry) {
          final orderId = entry.key;
          final messages = entry.value;
          final order = _orders.firstWhere((o) => o.id == orderId, orElse: () => OrderData());
          return _buildChatCard(orderId, messages, order);
        }),
      ],
    );
  }

  Widget _buildChatCard(int orderId, List<ChatData> messages, OrderData order) {
    final lastMsg = messages.last;
    final senderName = lastMsg.user?.name ?? _t('Supporto', 'Supporto');
    final msgText = lastMsg.Message ?? '';
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    String timeStr = '';
    if (lastMsg.created_at != null) {
      try {
        final dt = safeDateParse(lastMsg.created_at!).toLocal();
        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final orderProvider = Provider.of<UserOrderProvider>(context, listen: false);
        orderProvider.updateChat(orderId, context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            // Chat avatar
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(Icons.chat_bubble_outline, color: Colors.purple, size: 22)),
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_t("Ordine", "Ordine")} #$orderId',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('$senderName: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                      if (lastMsg.image != null && lastMsg.image!.isNotEmpty) ...[
                        Icon(Icons.image, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          msgText.isNotEmpty ? msgText : _t('Foto', 'Foto'),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${messages.length} ${_t("msg", "msg")}',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.purple),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'in progress': return Colors.blue;
      case 'to delivering': return Colors.indigo;
      case 'on way':
      case 'on delivering': return Colors.purple;
      case 'delivered':
      case 'complete': return Colors.green;
      case 'cancelled':
      case 'sys_cancelled':
      case 'interrupt': return Colors.red;
      case 'refund':
      case 'donerefund': return Colors.amber;
      case 'user not found': return Colors.deepOrange;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending': return _t('In attesa', 'In attesa');
      case 'in progress': return _t('In preparazione', 'In preparazione');
      case 'to delivering': return _t('Pronto', 'Pronto');
      case 'on way':
      case 'on delivering': return _t('In consegna', 'In consegna');
      case 'delivered':
      case 'complete': return _t('Consegnato', 'Consegnato');
      case 'cancelled':
      case 'sys_cancelled':
      case 'interrupt': return _t('Annullato', 'Annullato');
      case 'refund': return _t('Rimborso', 'Rimborso');
      case 'donerefund': return _t('Rimborsato', 'Rimborsato');
      case 'user not found': return _t('Utente non trovato', 'Utente non trovato');
      default: return status ?? '-';
    }
  }

  // ─── FAQ Section ──────────────────────────────────────────

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline, color: myColor, size: 22),
            const SizedBox(width: 8),
            Text(_t('Domande Frequenti', 'Domande Frequenti'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: _faqs.entries.map((entry) {
                final catLabel = _categoryLabels[entry.key] ?? entry.key;
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(catLabel, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: myColor)),
                    trailing: Icon(Icons.keyboard_arrow_down, color: myColor),
                    children: entry.value.map((faq) {
                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 24),
                          title: Text(faq.question ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                              child: Text(
                                faq.answer ?? '',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Contact Info Footer ──────────────────────────────────

  Widget _buildContactInfo() {
    final email = _settings['email'] as String? ?? '';
    final phone = _settings['phone'] as String? ?? '';
    final facebook = _settings['facebook'] as String? ?? '';
    final twitter = _settings['twitter'] as String? ?? '';
    final linkedin = _settings['linkedin'] as String? ?? '';
    final youtube = _settings['youtube'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_support_outlined, color: myColor, size: 22),
            const SizedBox(width: 8),
            Text(_t('Contatti', 'Contatti'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (phone.isNotEmpty)
                _buildContactRow(Icons.phone, phone, () => _callNumber(phone)),
              if (email.isNotEmpty)
                _buildContactRow(Icons.email_outlined, email, () => launchUrl(Uri(scheme: 'mailto', path: email))),
              if (facebook.isNotEmpty || twitter.isNotEmpty || linkedin.isNotEmpty || youtube.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Text(_t('Seguici', 'Seguici'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (facebook.isNotEmpty) _buildSocialBtn(Icons.facebook, const Color(0xFF1877F2), facebook),
                    if (twitter.isNotEmpty) _buildSocialBtn(Icons.close, const Color(0xFF1DA1F2), twitter),
                    if (linkedin.isNotEmpty) _buildSocialBtn(Icons.work_outline, const Color(0xFF0A66C2), linkedin),
                    if (youtube.isNotEmpty) _buildSocialBtn(Icons.play_circle_outline, const Color(0xFFFF0000), youtube),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: myColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: myColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialBtn(IconData icon, Color color, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  // ─── Shared Section Builder ───────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required VoidCallback seeAllTap,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: myColor, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            TextButton(
              onPressed: seeAllTap,
              child: Text(_t('Vedi tutti', 'Vedi tutti'), style: TextStyle(color: myColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}
