import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Chat.dart';
import 'package:eboro/API/Order.dart';
import 'package:eboro/Client/OrderChat.dart';
import 'package:eboro/Helper/ChatData.dart';
import 'package:eboro/Helper/ContentData.dart';
import 'package:eboro/Helper/OrderData.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderSupportDetailPage extends StatefulWidget {
  final int orderId;
  const OrderSupportDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderSupportDetailPage> createState() => _OrderSupportDetailPageState();
}

class _OrderSupportDetailPageState extends State<OrderSupportDetailPage> {
  bool _loading = true;
  OrderData? _order;
  List<ChatData>? _chatMessages;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      List<OrderData>? orders;
      List<ChatData>? chatMsgs;

      // Run in parallel with timeouts so one failure doesn't block the other
      await Future.wait([
        Order2().getOrders(widget.orderId).timeout(const Duration(seconds: 10)).then((v) => orders = v).catchError((_) => null),
        Chat2().getChat(widget.orderId).timeout(const Duration(seconds: 10)).then((v) => chatMsgs = v).catchError((_) => null),
      ]);

      if (mounted) {
        setState(() {
          _order = (orders != null && orders!.isNotEmpty) ? orders!.first : null;
          _chatMessages = chatMsgs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: myColor))
            : _order == null
                ? _buildNotFound()
                : RefreshIndicator(
                    color: myColor,
                    onRefresh: _loadData,
                    child: CustomScrollView(
                      slivers: [
                        _buildAppBar(),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOrderHeader(),
                                const SizedBox(height: 14),
                                _buildStatusStepper(),
                                const SizedBox(height: 18),
                                _buildQuickActions(),
                                const SizedBox(height: 18),
                                _buildOrderDetailsCard(),
                                const SizedBox(height: 16),
                                _buildRestaurantCard(),
                                const SizedBox(height: 16),
                                _buildRiderCard(),
                                const SizedBox(height: 16),
                                _buildChatPreview(),
                                const SizedBox(height: 16),
                                _buildRefundSection(),
                                const SizedBox(height: 16),
                                if (_canCancelOrder(_order!)) ...[
                                  _buildCancelSection(),
                                  const SizedBox(height: 16),
                                ],
                                const SizedBox(height: 30),
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

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Ordine non trovato',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  APP BAR
  // ═══════════════════════════════════════════════════════════

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
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
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ordine #${widget.orderId}',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Assistenza Ordine',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  1. ORDER HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildOrderHeader() {
    final sc = _getStatusColor(_order!.status);
    final sl = _getStatusLabel(_order!.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ordine #${_order!.id}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              _statusBadge(sl, sc),
            ],
          ),
          const SizedBox(height: 10),
          _iconLabel(Icons.calendar_today, _order!.created_at ?? '-'),
          const SizedBox(height: 4),
          _iconLabel(Icons.payment, _paymentLabel(_order!.payment)),
          if (_order!.address != null && _order!.address!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _iconLabel(Icons.location_on_outlined, _order!.address!),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  2. STATUS STEPPER
  // ═══════════════════════════════════════════════════════════

  int _statusToStepIndex(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending': return 0;
      case 'in progress': return 1;
      case 'to delivering': return 2;
      case 'on way':
      case 'on delivering': return 3;
      case 'delivered':
      case 'complete': return 4;
      default: return 0;
    }
  }

  bool _isOrderFinished(OrderData o) {
    final s = (o.status ?? '').toLowerCase();
    return s == 'complete' || s == 'delivered' || s == 'cancelled' ||
        s == 'refund' || s == 'donerefund';
  }

  Widget _buildStatusStepper() {
    final steps = <_StepInfo>[
      _StepInfo(label: 'Ricevuto', timestamp: _order!.created_at),
      _StepInfo(label: 'Preparazione', timestamp: _order!.accepted_at),
      _StepInfo(label: 'Spedizione', timestamp: _order!.shipped_at),
      _StepInfo(label: 'Consegna', timestamp: _order!.delivering_at),
      _StepInfo(label: 'Consegnato', timestamp: _order!.delivered_at),
    ];

    int currentStep = _statusToStepIndex(_order!.status);

    // Within first 5 minutes of "in progress", show as step 0
    if (currentStep == 1) {
      final rawDate = _order!.ordar_at ?? _order!.created_at;
      if (rawDate != null && rawDate.isNotEmpty) {
        try {
          final created = safeDateParse(rawDate).getLocalTimeZone();
          final now = DateTime.now().getLocalTimeZone();
          if (now.difference(created).inMinutes < 5) {
            currentStep = 0;
          }
        } catch (_) {}
      }
    }

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final nextStep = index ~/ 2 + 1;
            final done = nextStep <= currentStep;
            return Expanded(
              child: Container(height: 2, color: done ? Colors.green : Colors.grey.shade300),
            );
          }

          final stepIdx = index ~/ 2;
          final step = steps[stepIdx];
          final isDone = stepIdx <= currentStep;
          final isActive = stepIdx == currentStep && !_isOrderFinished(_order!);
          final hasTs = step.timestamp != null && step.timestamp!.isNotEmpty;

          String timeStr = '';
          if (hasTs) {
            try {
              final dt = safeDateParse(step.timestamp!).toLocal();
              timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            } catch (_) {}
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Colors.green : (isActive ? Colors.orange : Colors.grey.shade300),
                ),
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 15)
                    : (isActive
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : null),
              ),
              const SizedBox(height: 4),
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isDone || isActive ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? Colors.green : (isActive ? Colors.orange : Colors.grey),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                hasTs && timeStr.isNotEmpty ? timeStr : '--:--',
                style: TextStyle(fontSize: 8, color: isDone ? Colors.black54 : Colors.grey.shade400),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  3. QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Azioni rapide', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionBtn(
                icon: Icons.delivery_dining,
                label: 'Corriere',
                color: Colors.blue,
                sub: _order!.delivery?.name ?? 'Non assegnato',
                onTap: () => _callNumber(_order!.delivery?.mobile),
              ),
              const SizedBox(width: 10),
              _actionBtn(
                icon: Icons.restaurant,
                label: 'Ristorante',
                color: Colors.green,
                sub: _order!.branch?.name ?? '-',
                onTap: () => _callNumber(_order!.branch?.hotline),
              ),
              const SizedBox(width: 10),
              _actionBtn(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                color: Colors.purple,
                sub: '${(_chatMessages?.length ?? 0)} msg',
                onTap: _openChat,
              ),
              if (_canRequestRefund(_order!)) ...[
                const SizedBox(width: 10),
                _actionBtn(
                  icon: Icons.currency_exchange,
                  label: 'Rimborso',
                  color: Colors.orange,
                  sub: 'Richiedi',
                  onTap: () => _showRefundDialog(context, _order!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center),
              Text(sub, style: TextStyle(fontSize: 9, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  4. ORDER DETAILS (products + prices)
  // ═══════════════════════════════════════════════════════════

  Widget _buildOrderDetailsCard() {
    final content = _order!.content ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.receipt, 'Dettagli Ordine'),
          const Divider(height: 20),

          // Products
          ...content.map((item) => _buildProductRow(item)),

          if (content.isNotEmpty) const Divider(height: 20),

          // Price breakdown
          _priceLine('Subtotale', '${_order!.total_price ?? "0"} \u20ac'),
          _priceLine('Tasse', '${_order!.tax_price ?? "0"} \u20ac'),
          _priceLine('Spedizione', '${_order!.shipping_price ?? "0"} \u20ac'),
          if (_order!.gratuity != null && _order!.gratuity! > 0)
            _priceLine('Mancia', '${_order!.gratuity} \u20ac'),
          const Divider(height: 16),
          _priceLine('Totale', '${_order!.total_price ?? "0"} \u20ac', bold: true),

          // Extra info
          if (_order!.Delivery_time != null) ...[
            const SizedBox(height: 10),
            _iconLabel(Icons.timer_outlined, 'Tempo preparazione: ${_order!.Delivery_time} min'),
          ],
          if (_order!.delivery_code != null && _order!.delivery_code!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _iconLabel(Icons.lock_outline, 'Codice consegna: ${_order!.delivery_code}'),
          ],
          if (_order!.comment != null && _order!.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _iconLabel(Icons.note_outlined, 'Nota: ${_order!.comment}'),
          ],
          if (_order!.options != null && _order!.options!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _iconLabel(Icons.settings_outlined, 'Opzioni: ${_order!.options}'),
          ],
        ],
      ),
    );
  }

  Widget _buildProductRow(ContentData item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: myColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text('${item.qty ?? 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: myColor)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product?.name ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (item.sauces != null && item.sauces!.isNotEmpty)
                  Text(item.sauces!.map((s) => s.name).join(', '),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                if (item.extras != null && item.extras!.isNotEmpty)
                  Text(item.extras!.map((e) => e.name).join(', '),
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade400)),
                if (item.comment != null && item.comment!.isNotEmpty)
                  Text(item.comment!, style: TextStyle(fontSize: 11, color: Colors.orange.shade400, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Text('${item.price ?? "0"} \u20ac', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _priceLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: bold ? Colors.black87 : Colors.grey.shade600)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? myColor : Colors.black87)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  5. RESTAURANT INFO
  // ═══════════════════════════════════════════════════════════

  Widget _buildRestaurantCard() {
    final branch = _order!.branch;
    if (branch == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.restaurant, 'Ristorante', color: Colors.green),
          const Divider(height: 16),
          _infoRow(Icons.store, branch.name ?? '-'),
          if (branch.hotline != null && branch.hotline!.isNotEmpty)
            _infoRow(Icons.phone, branch.hotline!, onTap: () => _callNumber(branch.hotline)),
          if (branch.address != null && branch.address!.isNotEmpty)
            _infoRow(Icons.location_on, branch.address!),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  6. RIDER INFO
  // ═══════════════════════════════════════════════════════════

  Widget _buildRiderCard() {
    final rider = _order!.delivery;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.delivery_dining, 'Corriere', color: Colors.blue),
          const Divider(height: 16),
          if (rider == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top, size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text('Nessun corriere assegnato',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            )
          else ...[
            _infoRow(Icons.person, rider.name ?? '-'),
            if (rider.mobile != null && rider.mobile!.isNotEmpty)
              _infoRow(Icons.phone, rider.mobile!, onTap: () => _callNumber(rider.mobile)),
          ],
          // Delivery proof image
          if (_order!.delivery_proof_image != null && _order!.delivery_proof_image!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Foto prova consegna',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: _order!.delivery_proof_image!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180,
                  color: Colors.grey.shade100,
                  child: Center(child: CircularProgressIndicator(color: myColor, strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  7. CHAT PREVIEW
  // ═══════════════════════════════════════════════════════════

  Widget _buildChatPreview() {
    final messages = _chatMessages ?? [];
    final preview = messages.length > 5 ? messages.sublist(messages.length - 5) : messages;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Chat Supporto',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              TextButton.icon(
                onPressed: _openChat,
                icon: Icon(Icons.open_in_new, size: 16, color: myColor),
                label: Text(
                  messages.isEmpty ? 'Inizia Chat' : 'Apri Chat',
                  style: TextStyle(color: myColor, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          if (messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_outlined, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Nessun messaggio. Inizia una conversazione con il supporto.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const Divider(height: 16),
            ...preview.map((msg) => _chatBubble(msg)),
          ],
        ],
      ),
    );
  }

  Widget _chatBubble(ChatData msg) {
    final isMe = msg.user?.id?.toString() == Auth2.user?.id?.toString();
    final name = msg.user?.name ?? '';
    String timeStr = '';
    if (msg.created_at != null) {
      try {
        final dt = safeDateParse(msg.created_at!).toLocal();
        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.support_agent, size: 16, color: Colors.grey.shade600),
            ),
          if (!isMe) const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? myColor.withOpacity(0.12) : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  if (msg.image != null && msg.image!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: msg.image!,
                        width: 140, height: 100,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                    if (msg.Message != null && msg.Message!.isNotEmpty) const SizedBox(height: 4),
                  ],
                  if (msg.Message != null && msg.Message!.isNotEmpty)
                    Text(msg.Message!, style: TextStyle(fontSize: 13, color: isMe ? myColor : Colors.black87)),
                  Text(timeStr, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
          if (isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: myColor.withOpacity(0.15),
              child: Icon(Icons.person, size: 16, color: myColor),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  8. REFUND SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildRefundSection() {
    final refund = _order!.refund_request;

    if (refund != null) {
      final status = refund['status'] ?? 'pending';
      final sc = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
      final sl = status == 'approved'
          ? 'Approvato'
          : (status == 'rejected' ? 'Rifiutato' : 'In attesa');

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.currency_exchange, color: sc, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Richiesta di rimborso', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                _statusBadge(sl, sc),
              ],
            ),
            const Divider(height: 16),
            if (refund['reason'] != null)
              _detailRow('Motivo', _reasonLabel(refund['reason'])),
            if (refund['description'] != null && refund['description'].toString().isNotEmpty)
              _detailRow('Descrizione', refund['description']),
            if (refund['admin_notes'] != null && refund['admin_notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sc.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Risposta admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sc)),
                    const SizedBox(height: 4),
                    Text(refund['admin_notes'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
                  ],
                ),
              ),
            ],
            if (refund['image'] != null && refund['image'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Foto prova', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: refund['image'],
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_canRequestRefund(_order!)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            _sectionHeader(Icons.currency_exchange, 'Rimborso', color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              'Hai un problema con questo ordine? Puoi richiedere un rimborso.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.currency_exchange, color: Colors.white, size: 18),
                label: Text('Richiesta di rimborso', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _showRefundDialog(context, _order!),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  // ═══════════════════════════════════════════════════════════
  //  9. CANCEL SECTION
  // ═══════════════════════════════════════════════════════════

  bool _canCancelOrder(OrderData o) {
    final status = (o.status ?? '').toLowerCase();
    if (status != 'pending' && status != 'in progress' && status != 'to delivering') return false;
    final rawDate = o.ordar_at ?? o.created_at;
    if (rawDate == null || rawDate.isEmpty) return false;
    try {
      final created = safeDateParse(rawDate).getLocalTimeZone();
      final now = DateTime.now().getLocalTimeZone();
      return now.difference(created).inMinutes <= 5;
    } catch (_) {
      return false;
    }
  }

  int _cancelMinutesLeft(OrderData o) {
    final rawDate = o.ordar_at ?? o.created_at;
    if (rawDate == null || rawDate.isEmpty) return 0;
    try {
      final created = safeDateParse(rawDate).getLocalTimeZone();
      final now = DateTime.now().getLocalTimeZone();
      final left = 5 - now.difference(created).inMinutes;
      return left > 0 ? left : 0;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildCancelSection() {
    final left = _cancelMinutesLeft(_order!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Annulla Ordine', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.red))),
              Text('$left min', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Puoi annullare l\'ordine entro $left minuti',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _confirmCancelOrder(context, _order!),
              child: Text('Annulla Ordine', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelOrder(BuildContext context, OrderData order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Annullare l\'ordine?'),
          ],
        ),
        content: Text(
          'Sei sicuro di voler annullare l\'ordine #${order.id}?\nHai ancora ${_cancelMinutesLeft(order)} minuti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Annulla Ordine', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Order2().editOrder('cancelled', order.id.toString(), 'User cancelled');
        if (!mounted) return;
        final orderProvider = Provider.of<UserOrderProvider>(context, listen: false);
        await orderProvider.updateOrder(force: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ordine annullato'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  REFUND DIALOG (from OrderInsideWidget)
  // ═══════════════════════════════════════════════════════════

  bool _canRequestRefund(OrderData o) {
    final status = (o.status ?? '').toLowerCase();
    if (status != 'delivered' && status != 'complete' && status != 'user not found') return false;
    if (o.refund_request != null) return false;
    return true;
  }

  Future<void> _showRefundDialog(BuildContext context, OrderData order) async {
    String? selectedReason;
    final descController = TextEditingController();
    File? selectedImage;
    bool loading = false;

    final reasons = <String, String>{
      'not_delivered': 'Non consegnato',
      'bad_quality': 'Qualita\' scadente',
      'incomplete': 'Ordine incompleto',
      'other': 'Altro',
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 80,
              );
              if (picked != null) {
                setModalState(() => selectedImage = File(picked.path));
              }
            }

            return Directionality(
              textDirection: TextDirection.ltr,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16, right: 16, top: 14,
                    bottom: MediaQuery.of(ctx2).viewInsets.bottom + 14,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44, height: 5,
                            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.orange.withOpacity(0.4)),
                              ),
                              child: const Icon(Icons.currency_exchange, color: Colors.orange, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Richiesta di rimborso', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                  Text('Ordine #${order.id}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            IconButton(onPressed: () => Navigator.pop(ctx2), icon: const Icon(Icons.close)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Motivo del rimborso', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: reasons.entries.map((e) {
                            final selected = selectedReason == e.key;
                            return InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => setModalState(() => selectedReason = e.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.orange.withOpacity(0.14) : Colors.grey.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: selected ? Colors.orange : Colors.grey.withOpacity(0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selected) ...[const Icon(Icons.check, size: 16, color: Colors.orange), const SizedBox(width: 6)],
                                    Text(e.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.orange : Colors.black54)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: descController,
                          minLines: 2, maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Descrivi il problema (opzionale)...',
                            filled: true, fillColor: Colors.grey.withOpacity(0.06),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Foto prova (opzionale)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (selectedImage != null)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(selectedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 6, right: 6,
                                child: GestureDetector(
                                  onTap: () => setModalState(() => selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: Text('Fotocamera'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => pickImage(ImageSource.camera),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library, size: 18),
                                  label: Text('Galleria'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => pickImage(ImageSource.gallery),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity, height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedReason != null ? Colors.orange : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: (selectedReason == null || loading) ? null : () async {
                              setModalState(() => loading = true);
                              try {
                                final result = await Order2().requestRefund(
                                  order.id.toString(), selectedReason!, descController.text.trim(), imageFile: selectedImage,
                                );
                                if (!ctx2.mounted) return;
                                Navigator.pop(ctx2);
                                if (result['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Richiesta di rimborso inviata con successo'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Provider.of<UserOrderProvider>(context, listen: false).updateOrder(force: true);
                                  _loadData();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result['message'] ?? 'Errore'), backgroundColor: Colors.red),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => loading = false);
                                if (ctx2.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('Invia Richiesta', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    descController.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════

  Future<void> _callNumber(String? number) async {
    if (number == null || number.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: number);
    await launchUrl(uri);
  }

  void _openChat() {
    final orderProvider = Provider.of<UserOrderProvider>(context, listen: false);
    orderProvider.updateChat(_order!.id!, context);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
    );
  }

  Widget _sectionHeader(IconData icon, String title, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? myColor, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _iconLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: myColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: myColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
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
      case 'pending': return 'In attesa';
      case 'in progress': return 'In preparazione';
      case 'to delivering': return 'Pronto';
      case 'on way':
      case 'on delivering': return 'In consegna';
      case 'delivered':
      case 'complete': return 'Consegnato';
      case 'cancelled':
      case 'sys_cancelled':
      case 'interrupt': return 'Annullato';
      case 'refund': return 'Rimborso';
      case 'donerefund': return 'Rimborsato';
      case 'user not found': return 'Utente non trovato';
      default: return status ?? '-';
    }
  }

  String _paymentLabel(String? payment) {
    switch (payment) {
      case '0': return 'Contanti';
      case '1': return 'Carta di credito';
      case '2': return 'PayPal';
      case '3': return 'Apple Pay';
      case '4': return 'Google Pay';
      default: return payment ?? '-';
    }
  }

  String _reasonLabel(String? reason) {
    final labels = {
      'not_delivered': 'Non consegnato',
      'bad_quality': 'Qualita\' scadente',
      'incomplete': 'Ordine incompleto',
      'other': 'Altro',
    };
    return labels[reason] ?? reason ?? '-';
  }
}

class _StepInfo {
  final String label;
  final String? timestamp;
  _StepInfo({required this.label, this.timestamp});
}
