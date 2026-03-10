import 'package:eboro/API/Assistenza.dart';
import 'package:eboro/Helper/RefundData.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class RefundListPage extends StatefulWidget {
  const RefundListPage({Key? key}) : super(key: key);

  @override
  State<RefundListPage> createState() => _RefundListPageState();
}

class _RefundListPageState extends State<RefundListPage> {
  bool _loading = true;
  List<RefundData> _refunds = [];

  Map<String, String> get _reasonLabels => {
    'not_delivered': 'Non consegnato',
    'bad_quality': 'Qualità scadente',
    'incomplete': 'Ordine incompleto',
    'other': 'Altro',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AssistenzaAPI().getUserRefundRequests();
    if (mounted) setState(() { _refunds = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: myColor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Richieste di rimborso',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          elevation: 0,
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: myColor))
            : RefreshIndicator(
                color: myColor,
                onRefresh: _load,
                child: _refunds.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.currency_exchange, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('Nessuna richiesta di rimborso', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _refunds.length,
                        itemBuilder: (context, i) => _buildRefundCard(_refunds[i]),
                      ),
              ),
      ),
    );
  }

  Widget _buildRefundCard(RefundData r) {
    final statusColor = r.status == 'approved' ? Colors.green : (r.status == 'rejected' ? Colors.red : Colors.orange);
    final statusLabel = r.status == 'approved'
        ? 'Approvato'
        : (r.status == 'rejected' ? 'Rifiutato' : 'In attesa');
    final statusIcon = r.status == 'approved' ? Icons.check_circle : (r.status == 'rejected' ? Icons.cancel : Icons.hourglass_top);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Ordine #${r.orderId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const Spacer(),
                          if (r.orderTotal != null)
                            Text('${r.orderTotal} \u20ac', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                            child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                          ),
                          const SizedBox(width: 10),
                          Text(_reasonLabels[r.reason] ?? r.reason ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Description
          if (r.description != null && r.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(r.description!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),

          // Admin notes
          if (r.adminNotes != null && r.adminNotes!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings, color: statusColor.withOpacity(0.6), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Note dell\'amministrazione', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                        const SizedBox(height: 2),
                        Text(r.adminNotes!, style: TextStyle(fontSize: 12, color: statusColor.withOpacity(0.8), height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Image proof
          if (r.image != null && r.image!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  r.image!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),

          // Date footer
          if (r.createdAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(r.createdAt!, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ),
        ],
      ),
    );
  }
}
