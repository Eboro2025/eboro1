import 'package:flutter/material.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/main.dart';
import 'package:eboro/Client/EditHouseInfo.dart';

/// صفحة تأكيد بيانات التوصيل قبل الدفع
class ConfirmDeliveryPage extends StatefulWidget {
  final double total;
  final String paymentMethod;

  const ConfirmDeliveryPage({
    Key? key,
    required this.total,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<ConfirmDeliveryPage> createState() => _ConfirmDeliveryPageState();
}

class _ConfirmDeliveryPageState extends State<ConfirmDeliveryPage> {
  @override
  Widget build(BuildContext context) {
    final user = Auth2.user;

    final house = user?.house?.trim() ?? "";
    final intercom = user?.intercom?.trim() ?? "";
    final phone = user?.mobile?.trim() ?? "";
    final whatsapp = user?.whatsapp?.trim() ?? "";
    final hasWhatsapp = whatsapp.isNotEmpty && whatsapp != "0";
    final address = user?.address ?? "";

    String paymentLabel;
    IconData paymentIcon;
    Color paymentColor;
    switch (widget.paymentMethod) {
      case '0':
        paymentLabel = 'Contanti';
        paymentIcon = Icons.payments_outlined;
        paymentColor = const Color(0xFF4CAF50);
        break;
      case '1':
        paymentLabel = 'Carta';
        paymentIcon = Icons.credit_card;
        paymentColor = const Color(0xFF1976D2);
        break;
      case '2':
        paymentLabel = 'PayPal';
        paymentIcon = Icons.account_balance_wallet;
        paymentColor = const Color(0xFF003087);
        break;
      case '3':
        paymentLabel = 'Apple Pay';
        paymentIcon = Icons.apple;
        paymentColor = Colors.black;
        break;
      case '4':
        paymentLabel = 'Google Pay';
        paymentIcon = Icons.g_mobiledata;
        paymentColor = const Color(0xFF4285F4);
        break;
      default:
        paymentLabel = 'Pagamento';
        paymentIcon = Icons.payment;
        paymentColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Conferma ordine",
          style: const TextStyle(
            fontSize: 17,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Top colored header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: myColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Controlla i tuoi dati prima di confermare",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Delivery address card
                  _buildCard(
                    icon: Icons.location_on_rounded,
                    title: "Indirizzo di consegna",
                    children: [
                      if (address.isNotEmpty)
                        _buildInfoRow(Icons.map_outlined, "Indirizzo", address, Colors.grey[700]!),
                      _buildInfoRow(
                        Icons.home_rounded,
                        "N° Civico",
                        house.isNotEmpty ? house : "—",
                        const Color(0xFF6C5CE7),
                        isMissing: house.isEmpty,
                      ),
                      _buildInfoRow(
                        Icons.doorbell_rounded,
                        "Citofono",
                        intercom.isNotEmpty ? intercom : "—",
                        const Color(0xFFE17055),
                        isMissing: intercom.isEmpty,
                      ),
                    ],
                    onEdit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditHouseInfo()),
                      );
                      await Auth2.getUserDetails(context);
                      if (mounted) setState(() {});
                    },
                  ),

                  const SizedBox(height: 12),

                  // Contact card
                  _buildCard(
                    icon: Icons.phone_android_rounded,
                    title: "Contatti",
                    children: [
                      _buildInfoRow(
                        Icons.phone_rounded,
                        "Telefono",
                        phone.isNotEmpty ? phone : "—",
                        const Color(0xFF0984E3),
                        isMissing: phone.isEmpty,
                      ),
                      _buildInfoRow(
                        Icons.message_rounded,
                        "WhatsApp",
                        hasWhatsapp ? whatsapp : "Non attivo",
                        const Color(0xFF25D366),
                        isOptional: true,
                        isMissing: false,
                      ),
                    ],
                    onEdit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditHouseInfo()),
                      );
                      await Auth2.getUserDetails(context);
                      if (mounted) setState(() {});
                    },
                  ),

                  const SizedBox(height: 12),

                  // Payment card
                  _buildCard(
                    icon: Icons.payment_rounded,
                    title: "Pagamento",
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: paymentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(paymentIcon, color: paymentColor, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              paymentLabel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: paymentColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${widget.total.toStringAsFixed(2)} €",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
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

          // Bottom button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColor,
                  elevation: 2,
                  shadowColor: myColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  // Return true to confirm
                  Navigator.pop(context, true);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      "Conferma e paga",
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: myColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: myColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 14, color: myColor),
                        const SizedBox(width: 4),
                        Text(
                          "Modifica",
                          style: TextStyle(fontSize: 12, color: myColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    bool isMissing = false,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isMissing ? Colors.red.shade400 : Colors.black87,
              ),
            ),
          ),
          if (!isMissing && !isOptional)
            const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF4CAF50)),
          if (isMissing && !isOptional)
            Icon(Icons.error_rounded, size: 16, color: Colors.red.shade400),
        ],
      ),
    );
  }
}
