import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Assistenza.dart';
import 'package:eboro/API/ContactUs.dart';
import 'package:eboro/Client/Contact%20Us/ContactDetails.dart';
import 'package:eboro/Client/Contact%20Us/WriteContact.dart';
import 'package:eboro/Helper/ContactsData.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({Key? key}) : super(key: key);

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  bool _loading = true;
  List<ContactsData> _tickets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AssistenzaAPI().getUserTickets();
    if (mounted) setState(() { _tickets = data; _loading = false; });
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
            'Ticket di supporto',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: myColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('Nuovo ticket', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => WriteContact()));
            _load();
          },
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: myColor))
            : RefreshIndicator(
                color: myColor,
                onRefresh: _load,
                child: _tickets.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('Nessun ticket', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                                const SizedBox(height: 6),
                                Text('Premi + per creare un nuovo ticket', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tickets.length,
                        itemBuilder: (context, i) => _buildTicketCard(_tickets[i]),
                      ),
              ),
      ),
    );
  }

  Widget _buildTicketCard(ContactsData t) {
    final isOpen = t.state == '1' || t.state == 'open';
    final hasReply = t.reply != null && t.reply!.isNotEmpty;
    final statusColor = hasReply ? Colors.green : (isOpen ? Colors.orange : Colors.grey);
    final statusLabel = hasReply ? 'Risposto' : (isOpen ? 'In attesa' : 'Chiuso');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // Set the static list so ContactDetails can find the item
        ContactUsAPI.contact = _tickets;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ContactDetails(id: t.id, subject: t.subject)),
        );
      },
      child: Container(
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
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      hasReply ? Icons.reply : (isOpen ? Icons.hourglass_top : Icons.check_circle_outline),
                      color: statusColor, size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.subject ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                              child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                            ),
                            const Spacer(),
                            if (t.created_at != null) Text(t.created_at!.split(' ').first, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Message preview
            if (t.message != null && t.message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  t.message!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Attached image
            if (t.file != null && t.file!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: t.file!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 120, color: Colors.grey.shade100,
                      child: Center(child: CircularProgressIndicator(color: myColor, strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            // Reply preview
            if (hasReply)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.reply, color: Colors.green.shade400, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.reply!,
                        style: TextStyle(fontSize: 12, color: Colors.green.shade700, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
