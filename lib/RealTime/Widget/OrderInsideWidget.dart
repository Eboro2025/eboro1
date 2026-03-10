import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:eboro/Widget/OrderItem.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:google_maps_widget/google_maps_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../API/Auth.dart';
import '../../API/Order.dart';
import '../../Client/AssistenzaPage.dart';
import '../../Client/Assistenza/OrderSupportDetailPage.dart';
import '../../Helper/OrderData.dart';
import '../../Widget/Progress.dart';

class OrderInsideWidget extends StatefulWidget {
  final int? i;

  const OrderInsideWidget({
    Key? key,
    required this.i,
  }) : super(key: key);

  @override
  State<OrderInsideWidget> createState() => _OrderInsideWidgetState();
}

class _OrderInsideWidgetState extends State<OrderInsideWidget> {
  final mapsWidgetController = GlobalKey<GoogleMapsWidgetState>();

  String? orderTimeText = "";
  String? orderDistance = "";

  Timer? _countdownTimer;
  int? _remainingSeconds;

  // Prevent repeated restarts
  int? _lastOrderId;
  String? _lastCountdownMode; // 'prep' or 'eta'

  bool _notifiedRiderStarted = false;
  bool _notifiedNearCustomer = false;

  // Stream for the real driver location
  final StreamController<LatLng> _driverLocationController = StreamController<LatLng>.broadcast();

  String? _lastStatus;

  LatLng? _driverLatLng;
  LatLng? _destinationLatLng;

  bool get _isAr => (MyApp2.apiLang?.toString() ?? 'ar').toLowerCase().contains('ar');

  // ---------------- Helpers ---------------- //

  int _convertToMinutes(String timeText) {
    final normalized = timeText
        .toLowerCase()
        .replaceAll('mins', 'min')
        .replaceAll('minutes', 'min')
        .replaceAll('min.', 'min')
        .replaceAll('hrs', 'h')
        .replaceAll('hours', 'h');

    final hoursRegex = RegExp(r'(\d+)\s*h');
    final minutesRegex = RegExp(r'(\d+)\s*min');

    final hours = int.parse(hoursRegex.firstMatch(normalized)?.group(1) ?? '0');
    final minutes =
        int.parse(minutesRegex.firstMatch(normalized)?.group(1) ?? '0');

    int totalMinutes = (hours * 60) + minutes;
    if (totalMinutes < 0) totalMinutes = 0;
    return totalMinutes;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  double _distanceInMeters(LatLng a, LatLng b) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degToRad(b.latitude - a.latitude);
    final double dLon = _degToRad(b.longitude - a.longitude);

    final double lat1 = _degToRad(a.latitude);
    final double lat2 = _degToRad(b.latitude);

    final double h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);

    final double c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadius * c;
  }

  // ---------------- Countdown (MM:SS cashier style) ---------------- //

  void _startCountdownSeconds(int seconds, {required String mode}) {
    if (seconds <= 0) {
      _stopCountdown();
      return;
    }

    // Prevent restart if same mode and small difference (frequent ETA updates)
    if (_lastCountdownMode == mode &&
        _remainingSeconds != null &&
        (_remainingSeconds! - seconds).abs() < 15) {
      return;
    }

    _lastCountdownMode = mode;

    _countdownTimer?.cancel();
    _remainingSeconds = seconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds = max(0, (_remainingSeconds ?? 0) - 1);
        if (_remainingSeconds == 0) timer.cancel();
      });
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _remainingSeconds = null;
    _lastCountdownMode = null;
  }

  String get _mmss {
    final s = _remainingSeconds;
    if (s == null) return '--:--';
    if (s <= 0) return '00:00';
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  // Same cashier calculation (getLocalTimeZone):
  // (ordar_at + Delivery_time).toLocal() - now.toLocal()
  int? _prepDiffSeconds(OrderData o) {
    final prepMin = o.Delivery_time;
    if (prepMin == null || prepMin <= 0) return null;

    final rawDate = o.ordar_at;
    if (rawDate == null || rawDate.isEmpty) return null;

    try {
      final parsed = safeDateParse(rawDate);
      final end = parsed.add(Duration(minutes: prepMin)).getLocalTimeZone();
      final now = DateTime.now().getLocalTimeZone();
      final diff = end.difference(now).inSeconds;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return null;
    }
  }

  bool _isLate = false;
  int? _lateMinutes;

  // ---------------- Order Tracking Stepper ---------------- //

  bool _isOrderFinished(OrderData order) {
    final s = (order.status ?? '').toLowerCase();
    return s == 'complete' || s == 'delivered' || s == 'cancelled' ||
        s == 'refund' || s == 'donerefund';
  }

  // Map status to step index (0-4)
  int _statusToStepIndex(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending':
        return 0;
      case 'in progress':
        return 1;
      case 'to delivering':
        return 2;
      case 'on way':
      case 'on delivering':
        return 3;
      case 'delivered':
      case 'complete':
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildOrderStepper(OrderData order) {
    final steps = <_StepInfo>[
      _StepInfo(label: 'Ricevuto', timestamp: order.created_at),
      _StepInfo(label: 'Preparazione', timestamp: order.accepted_at),
      _StepInfo(label: 'Spedizione', timestamp: order.shipped_at),
      _StepInfo(label: 'Consegna', timestamp: order.delivering_at),
      _StepInfo(label: 'Consegnato', timestamp: order.delivered_at),
    ];

    // Derive current step from status (works even without timestamps)
    int currentStepFromStatus = _statusToStepIndex(order.status);

    // "Preparazione" step turns green after 5 minutes only -- chance for customer to cancel
    if (currentStepFromStatus == 1) {
      final rawDate = order.ordar_at ?? order.created_at;
      if (rawDate != null && rawDate.isNotEmpty) {
        try {
          final created = safeDateParse(rawDate).getLocalTimeZone();
          final now = DateTime.now().getLocalTimeZone();
          if (now.difference(created).inMinutes < 5) {
            currentStepFromStatus = 0; // still in consideration period
          }
        } catch (_) {}
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              final stepBefore = index ~/ 2;
              final nextStepIndex = stepBefore + 1;
              final nextDone = nextStepIndex <= currentStepFromStatus;
              return Expanded(
                child: Container(
                  height: 2,
                  color: nextDone ? Colors.green : Colors.grey.shade300,
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final step = steps[stepIndex];
            // Step is done if it has a timestamp OR if the current status implies it's passed
            final isDone = stepIndex <= currentStepFromStatus;
            final isActive = stepIndex == currentStepFromStatus && !_isOrderFinished(order);
            final hasTimestamp = step.timestamp != null && step.timestamp!.isNotEmpty;

            String timeStr = '';
            if (hasTimestamp) {
              try {
                final dt = safeDateParse(step.timestamp!).toLocal();
                timeStr =
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              } catch (_) {}
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? Colors.green
                        : (isActive ? Colors.orange : Colors.grey.shade300),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 15)
                      : (isActive
                          ? const Padding(
                              padding: EdgeInsets.all(5),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : null),
                ),
                const SizedBox(height: 4),
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        isDone || isActive ? FontWeight.bold : FontWeight.normal,
                    color: isDone
                        ? Colors.green
                        : (isActive ? Colors.orange : Colors.grey),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  hasTimestamp && timeStr.isNotEmpty ? timeStr : '--:--',
                  style: TextStyle(
                    fontSize: 8,
                    color: isDone ? Colors.black54 : Colors.grey.shade400,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------------- Cancel order ---------------- //

  /// Is there still time to cancel (5 minutes from order time)?
  bool _canCancelOrder(OrderData o) {
    final status = (o.status ?? '').toLowerCase();
    // Only if the order hasn't left the restaurant yet
    if (status != 'pending' && status != 'in progress' && status != 'to delivering') return false;

    final rawDate = o.ordar_at ?? o.created_at;
    if (rawDate == null || rawDate.isEmpty) return false;

    try {
      final created = safeDateParse(rawDate).getLocalTimeZone();
      final now = DateTime.now().getLocalTimeZone();
      final diff = now.difference(created).inMinutes;
      return diff <= 5;
    } catch (_) {
      return false;
    }
  }

  /// Minutes remaining to cancel
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

  Future<void> _confirmCancelOrder(BuildContext context, OrderData order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Cancel Order?'),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel order #${order.id}?\nYou have ${_cancelMinutesLeft(order)} minutes left to cancel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Progress.progressDialogue(context);
      try {
        await Order2().editOrder('cancelled', order.id.toString(), 'User cancelled');
        if (!mounted) return;
        Progress.dimesDialog(context);
        // Update orders
        final orderProvider = Provider.of<UserOrderProvider>(context, listen: false);
        await orderProvider.updateOrder(force: true);
        if (mounted) Navigator.of(context).pop(); // go back to list
      } catch (e) {
        if (mounted) {
          Progress.dimesDialog(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling order: $e')),
          );
        }
      }
    }
  }

  // ---------------- Refund request ---------------- //

  bool _canRequestRefund(OrderData o) {
    final status = (o.status ?? '').toLowerCase();
    if (status != 'delivered' && status != 'complete' && status != 'user not found') return false;
    // If there's a previous refund request, don't show the button
    if (o.refund_request != null) return false;
    return true;
  }

  Future<void> _showRefundDialog(BuildContext context, OrderData order) async {
    String? selectedReason;
    final descController = TextEditingController();
    File? selectedImage;
    bool loading = false;
    final isAr = _isAr;

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
                source: source,
                maxWidth: 1200,
                maxHeight: 1200,
                imageQuality: 80,
              );
              if (picked != null) {
                setModalState(() => selectedImage = File(picked.path));
              }
            }

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 14,
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
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(999),
                            ),
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
                                  Text(
                                    'Richiedi Rimborso',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    'Ordine #${order.id}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx2),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Motivo del rimborso',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                                  border: Border.all(
                                    color: selected ? Colors.orange : Colors.grey.withOpacity(0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selected) ...[
                                      const Icon(Icons.check, size: 16, color: Colors.orange),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      e.value,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: selected ? Colors.orange : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: descController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Descrivi il problema (opzionale)...',
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // PHOTO PROOF SECTION
                        Text(
                          'Foto prova (opzionale)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (selectedImage != null)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImage!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 6, right: 6,
                                child: GestureDetector(
                                  onTap: () => setModalState(() => selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => pickImage(ImageSource.gallery),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedReason != null ? Colors.orange : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: (selectedReason == null || loading)
                                ? null
                                : () async {
                                    setModalState(() => loading = true);
                                    try {
                                      final result = await Order2().requestRefund(
                                        order.id.toString(),
                                        selectedReason!,
                                        descController.text.trim(),
                                        imageFile: selectedImage,
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
                                        Provider.of<UserOrderProvider>(context, listen: false)
                                            .updateOrder(force: true);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(result['message'] ?? 'Errore'),
                                            backgroundColor: Colors.red,
                                          ),
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
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
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

  // ---------------- Assistenza sheet (call, chat, refund) ---------------- //

  void _showAssistenzaSheet(BuildContext context, OrderData selfOrder) {
    final String? restaurantPhone = selfOrder.branch?.hotline;
    final String? riderPhone = selfOrder.delivery?.mobile;
    final orderProvider = Provider.of<UserOrderProvider>(context, listen: false);
    final isAr = _isAr;

    Future<void> _call(String? number) async {
      if (number == null || number.isEmpty) return;
      final uri = Uri(scheme: 'tel', path: number);
      await launchUrl(uri);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 44, height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: myColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: myColor.withOpacity(0.4)),
                          ),
                          child: Icon(Icons.support_agent, color: myColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Assistenza',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),

                  // Call rider
                  ListTile(
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, color: Colors.blue, size: 20),
                    ),
                    title: Text("Chiama fattorino", style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(riderPhone ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      _call(riderPhone);
                    },
                  ),

                  // Call restaurant
                  ListTile(
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant, color: Colors.green, size: 20),
                    ),
                    title: Text("Chiama ristorante", style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(restaurantPhone ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      _call(restaurantPhone);
                    },
                  ),

                  // Chat with support
                  ListTile(
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: Colors.purple, size: 20),
                    ),
                    title: Text("Chat supporto", style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("Parla con il nostro team", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      orderProvider.updateChat(selfOrder.id!, context);
                    },
                  ),

                  // Refund request (only if eligible)
                  if (_canRequestRefund(selfOrder))
                    ListTile(
                      leading: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.currency_exchange, color: Colors.orange, size: 20),
                      ),
                      title: Text("Richiedi rimborso", style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("Ordine non conforme o non ricevuto", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showRefundDialog(context, selfOrder);
                      },
                    ),

                  // Order-specific support page
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: myColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.headset_mic_rounded, color: myColor, size: 20),
                    ),
                    title: Text(
                      "Supporto ordine completo",
                      style: TextStyle(fontWeight: FontWeight.w600, color: myColor),
                    ),
                    subtitle: Text(
                      "Tutte le info e azioni per quest'ordine",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: Icon(Icons.arrow_forward_rounded, color: myColor),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderSupportDetailPage(orderId: selfOrder.id!)),
                      );
                    },
                  ),
                  // General support center
                  ListTile(
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.support_agent, color: Colors.grey.shade600, size: 20),
                    ),
                    title: Text(
                      "Centro assistenza generale",
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                    ),
                    subtitle: Text(
                      "FAQ, ticket, rimborsi",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade400),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AssistenzaPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  // ---------------- Price row helper ---------------- //

  Widget _line(String left, String right, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Phase helpers ---------------- //

  int _phaseForStatus(String? status) {
    if (status == null) return 0;
    final s = status.toLowerCase();
    if (s == 'on delivering') return 1;
    if (s == 'delivered' || s == 'complete') return 2;
    return 0;
  }

  IconData _phaseIcon(int phase) {
    switch (phase) {
      case 1:
        return Icons.delivery_dining;
      case 2:
        return Icons.check_circle_outline;
      case 0:
      default:
        return Icons.restaurant;
    }
  }

  String _phaseTitle(int phase, {String? branchName}) {
    switch (phase) {
      case 1:
        return "Rider in arrivo";
      case 2:
        return "Ordine consegnato";
      case 0:
      default:
        return branchName ?? "Al ristorante";
    }
  }

  String _phaseSubtitle(int phase, {String? branchName}) {
    final name = branchName ?? 'il ristorante';
    switch (phase) {
      case 1:
        return "Il tuo ordine ha lasciato $name ed è in arrivo";
      case 2:
        return "Grazie! Buon appetito";
      case 0:
      default:
        return "$name sta preparando il tuo ordine";
    }
  }

  Color _statusColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s == 'delivered' || s == 'complete') return Colors.green;
    if (s == 'on delivering') return Colors.orange;
    if (s == 'cancelled' || s == 'refund' || s == 'donerefund')
      return Colors.red;
    return Colors.grey;
  }

  @override
  void dispose() {
    _stopCountdown();
    _driverLocationController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<UserOrderProvider>(context);
    final OrderData selfOrder = orderProvider.selectedOrder;

    final statusLower = (selfOrder.status ?? '').toLowerCase();

    // Reset for each new order
    if (_lastOrderId != selfOrder.id) {
      _lastOrderId = selfOrder.id;
      _stopCountdown();
      _notifiedRiderStarted = false;
      _notifiedNearCustomer = false;
      _lastStatus = null;
    }

    // finished states
    final finishedStates = <String>[
      'complete',
      'cancelled',
      'delivered',
      'refund',
      'donerefund',
    ];

    final finished = finishedStates.contains(statusLower);

    if (finished) {
      _stopCountdown();
    } else if (statusLower == 'pending') {
      // Timer doesn't start until the cashier accepts the order
      _stopCountdown();
    } else {
      // Countdown from Delivery_time after cashier accepts (in progress -> to delivering -> on delivering)
      final sec = _prepDiffSeconds(selfOrder);
      if (sec != null) {
        _remainingSeconds = sec;
        if (sec > 0 && (_countdownTimer == null || !_countdownTimer!.isActive)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _startCountdownSeconds(sec, mode: 'prep');
          });
        }
      }
    }

    // set drop location
    if (selfOrder.drop_lat != null && selfOrder.drop_long != null) {
      _destinationLatLng = LatLng(
        double.parse(selfOrder.drop_lat!),
        double.parse(selfOrder.drop_long!),
      );
    }

    // Update driver location on map
    if (selfOrder.delivery?.lat != null && selfOrder.delivery?.long != null) {
      final dLat = double.tryParse(selfOrder.delivery!.lat!);
      final dLng = double.tryParse(selfOrder.delivery!.long!);
      if (dLat != null && dLng != null && dLat != 0 && dLng != 0) {
        _driverLatLng = LatLng(dLat, dLng);
        if (!_driverLocationController.isClosed) {
          _driverLocationController.add(LatLng(dLat, dLng));
        }
      }
    }

    // notify start
    if (statusLower == 'on delivering' &&
        (_lastStatus ?? '').toLowerCase() != 'on delivering' &&
        !_notifiedRiderStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Il rider ha iniziato la consegna ed è in arrivo"),
          ),
        );
      });
      _notifiedRiderStarted = true;
    }

    // notify near customer (needs _driverLatLng update from map package if available)
    if (_driverLatLng != null &&
        _destinationLatLng != null &&
        !_notifiedNearCustomer &&
        statusLower == 'on delivering') {
      final distance = _distanceInMeters(_driverLatLng!, _destinationLatLng!);
      if (distance <= 50) {
        _notifiedNearCustomer = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Il rider è vicinissimo (meno di 50 m)")),
          );
        });
      }
    }

    final phase = _phaseForStatus(selfOrder.status);

    final canTrack = selfOrder.drop_lat != null && selfOrder.drop_long != null;

    // Track order only when the rider starts delivery
    final showTrackButton = canTrack && statusLower == 'on delivering';

    final statusColor = _statusColor(selfOrder.status);

    // reserve space for floating buttons
    final bottomSafeSpace = MediaQuery.of(context).padding.bottom + 96.0;

    // Auto-open rating after delivery completion (once)
    final wasLower = (_lastStatus ?? '').toLowerCase();
    final isDeliveredNow =
        (statusLower == 'delivered' || statusLower == 'complete');
    final orderId = selfOrder.id ?? 0;

    final shouldShowRate = isDeliveredNow &&
        wasLower != statusLower &&
        orderId != 0 &&
        !orderProvider.hasShownRate(orderId);

    if (shouldShowRate) {
      orderProvider.markRateShown(orderId);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (_) => RateDialog(
            orderId: orderId,
            onSubmit: (value, comment, reasons) async {
              await Provider.of<UserOrderProvider>(context, listen: false)
                  .submitOrderRate(
                orderId: orderId,
                value: value,
                comment: comment,
                reasons: reasons,
                context: context,
              );
            },
          ),
        );
      });
    }

    // Important: update last status
    _lastStatus = selfOrder.status;

    // ETA text displayed (same as cashier)
    String etaText() {
      if (finished) return '--:--';
      // If countdown is active, show MM:SS
      if (_remainingSeconds != null) return _mmss;
      return '--:--';
    }

    // Null protection for map
    final hasBranch =
        selfOrder.branch?.lat != null && selfOrder.branch?.long != null;
    final hasDrop = selfOrder.drop_lat != null && selfOrder.drop_long != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 16),

              // MAP
              Container(
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
                height: MyApp2.H! * 0.30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 6,
                      color: Colors.black12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (!hasBranch || !hasDrop)
                      ? const Center(child: Text("Map unavailable"))
                      : GoogleMapsWidget(
                          apiKey: "YOUR_GOOGLE_MAPS_API_KEY",
                          key: mapsWidgetController,
                          // Source = store always
                          sourceLatLng: LatLng(
                            double.parse(selfOrder.branch!.lat!),
                            double.parse(selfOrder.branch!.long!),
                          ),
                          // Destination = customer address
                          destinationLatLng: LatLng(
                            double.parse(selfOrder.drop_lat!),
                            double.parse(selfOrder.drop_long!),
                          ),
                          routeWidth: 3,
                          sourceMarkerIconInfo: const MarkerIconInfo(
                            assetPath: "images/icons/shop.png",
                          ),
                          destinationMarkerIconInfo: const MarkerIconInfo(
                            assetPath: "images/icons/home.png",
                          ),
                          driverMarkerIconInfo: const MarkerIconInfo(
                            assetPath: "images/icons/rider.png",
                            assetMarkerSize: Size.square(125),
                          ),
                          // Stream for the real driver location (updates whenever the order updates)
                          driverCoordinatesStream: _driverLocationController.stream,
                          liteModeEnabled: false,
                          updatePolylinesOnDriverLocUpdate: true,
                          totalTimeCallback: (time) {
                            final safeTime = time ?? '';
                            setState(() => orderTimeText = safeTime);

                            // After leaving the restaurant: ETA countdown from map
                            if (statusLower == 'on way' || statusLower == 'on delivering') {
                              final sec = _convertToMinutes(safeTime) * 60;
                              if (sec > 0) {
                                _startCountdownSeconds(sec, mode: 'eta');
                              }
                            }
                          },
                          totalDistanceCallback: (distance) {
                            setState(() => orderDistance = distance);
                          },
                        ),
                ),
              ),

              // STATUS CARD
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(color: statusColor),
                          ),
                          child: Icon(_phaseIcon(phase), color: statusColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _phaseTitle(phase, branchName: selfOrder.branch?.name),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _phaseSubtitle(phase, branchName: selfOrder.branch?.name),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Countdown MM:SS like the cashier
                        if (_remainingSeconds != null && !finished)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("ETA",
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.black45)),
                                Text(
                                  _mmss,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("ETA",
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              Text(
                                etaText(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (orderDistance != null &&
                                  orderDistance!.isNotEmpty)
                                Text(
                                  orderDistance!,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // DELIVERY CODE CARD
              if (selfOrder.delivery_code != null &&
                  selfOrder.delivery_code!.isNotEmpty &&
                  (statusLower == 'on way' ||
                   statusLower == 'on delivering' ||
                   statusLower == 'to delivering'))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(21),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: const Icon(Icons.lock_outline, color: Colors.amber, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Codice di consegna',
                                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(
                                  selfOrder.delivery_code!,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 8,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Mostra al fattorino',
                                style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // MAIN CONTENT
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ORDER TRACKING STEPPER
                      _buildOrderStepper(selfOrder),

                      // ORDER HEADER
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Order #${selfOrder.id}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: statusColor.withOpacity(0.55)),
                                ),
                                child: Text(
                                  (selfOrder.status ?? '').toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ADDRESS CHIP
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              avatar: const Icon(Icons.location_on,
                                  size: 18, color: Colors.red),
                              label: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.72,
                                ),
                                child: Text(
                                  selfOrder.address ?? "No address",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              backgroundColor: Colors.red.withOpacity(0.06),
                              side: BorderSide(
                                  color: Colors.red.withOpacity(0.25)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                      ),

                      // Cancel button (within 10 minutes only)
                      if (_canCancelOrder(selfOrder))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: Text(
                                'Cancel Order (${_cancelMinutesLeft(selfOrder)} min left)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _confirmCancelOrder(context, selfOrder),
                            ),
                          ),
                        ),

                      // REFUND STATUS CARD
                      if (selfOrder.refund_request != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: selfOrder.refund_request!['status'] == 'approved'
                                ? Colors.green.shade50
                                : selfOrder.refund_request!['status'] == 'rejected'
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    selfOrder.refund_request!['status'] == 'approved'
                                        ? Icons.check_circle
                                        : selfOrder.refund_request!['status'] == 'rejected'
                                            ? Icons.cancel
                                            : Icons.hourglass_top,
                                    color: selfOrder.refund_request!['status'] == 'approved'
                                        ? Colors.green
                                        : selfOrder.refund_request!['status'] == 'rejected'
                                            ? Colors.red
                                            : Colors.orange,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selfOrder.refund_request!['status'] == 'approved'
                                              ? 'Rimborso approvato'
                                              : selfOrder.refund_request!['status'] == 'rejected'
                                                  ? 'Rimborso rifiutato'
                                                  : 'Rimborso in attesa',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: selfOrder.refund_request!['status'] == 'approved'
                                                ? Colors.green.shade700
                                                : selfOrder.refund_request!['status'] == 'rejected'
                                                    ? Colors.red.shade700
                                                    : Colors.orange.shade700,
                                          ),
                                        ),
                                        if (selfOrder.refund_request!['admin_notes'] != null &&
                                            selfOrder.refund_request!['admin_notes'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              selfOrder.refund_request!['admin_notes'].toString(),
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 6),

                      // ITEMS + SUMMARY
                      SizedBox(
                        height: 220,
                        child: Row(
                          children: [
                            // Items
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Items",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Divider(height: 10),
                                      Expanded(
                                        child: OrderItem(selfOrder: selfOrder),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Summary
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Summary",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Divider(height: 10),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _line(
                                                "Subtotal",
                                                "${(double.parse(selfOrder.total_price.toString()) - (double.parse(selfOrder.tax_price.toString()) + double.parse(selfOrder.shipping_price.toString())) - double.parse(selfOrder.gratuity.toString())).toStringAsFixed(2)} €",
                                              ),
                                              _line("Delivery",
                                                  "${selfOrder.shipping_price} €"),
                                              _line("Tax",
                                                  "${selfOrder.tax_price} €"),
                                              _line("Tip",
                                                  "${selfOrder.gratuity} €"),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.blue
                                                  .withOpacity(0.25)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "Total",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "${selfOrder.total_price} €",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: bottomSafeSpace),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // BACK BTN
          Positioned(
            top: 40,
            left: 12,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 4,
              mini: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),

          // TRACK BTN (bottom left) - after sending only
          if (showTrackButton)
            Positioned(
              bottom: 24,
              left: 16,
              child: _BlinkingButton(
                enabled: true,
                onPressed: () async {
                  final url =
                      'https://www.google.com/maps/search/?api=1&query=${selfOrder.drop_lat},${selfOrder.drop_long}';
                  await launchUrl(Uri.parse(url));
                },
              ),
            ),

          // ASSISTENZA (bottom right)
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: "assistenza_btn",
              backgroundColor: myColor,
              elevation: 4,
              icon: const Icon(Icons.support_agent, color: Colors.white, size: 20),
              label: Text('Assistenza', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              onPressed: () => _showAssistenzaSheet(context, selfOrder),
            ),
          ),
        ],
      ),
    );
  }
}

// Blinking button
class _BlinkingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool enabled;

  const _BlinkingButton(
      {Key? key, required this.onPressed, this.enabled = true})
      : super(key: key);

  @override
  State<_BlinkingButton> createState() => _BlinkingButtonState();
}

class _BlinkingButtonState extends State<_BlinkingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fade = Tween<double>(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.navigation, size: 18),
        label: const Text('Segui ordine', style: TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.enabled ? Colors.blue : Colors.grey,
          foregroundColor: Colors.white,
          minimumSize: const Size(90, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
        ),
        onPressed: widget.enabled ? widget.onPressed : null,
      ),
    );
  }
}

/// RateDialog: as-is (no changes)
class RateDialog extends StatefulWidget {
  final int orderId;
  final Future<void> Function(int value, String comment, List<String> reasons)
      onSubmit;

  const RateDialog({
    Key? key,
    required this.orderId,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<RateDialog> {
  int _value = 5;
  bool _loading = false;

  late final bool isAr;
  late final List<String> _reasons;

  final TextEditingController _controller = TextEditingController();
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    isAr = (MyApp2.apiLang?.toString() ?? 'ar').toLowerCase().contains('ar');

    _reasons = const [
            "Consegna",
            "Prezzi",
            "Qualità",
            "Rider",
            "Ristorante",
            "Imballaggio",
            "Preparazione rapida",
            "Servizio",
          ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorFor(int v) {
    if (v >= 4) return Colors.green;
    if (v == 3) return Colors.orange;
    return Colors.red;
  }

  String _labelFor(int v) {
    if (v == 5) return "Eccellente";
    if (v == 4) return "Molto buono";
    if (v == 3) return "Buono";
    if (v == 2) return "Scarso";
    return "Pessimo";
  }

  Future<void> _showReasonInfo() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Perché scegliere un motivo?"),
        content: Text(
          "Scegliere un motivo ci aiuta a capire più velocemente cosa migliorare. Puoi selezionare uno o più motivi (non è obbligatorio).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _colorFor(_value);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text(
                        '$_value',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: c,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Valuta l’ordine",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _labelFor(_value),
                          style: TextStyle(
                            fontSize: 12,
                            color: c,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (i) {
                  final v = i + 1;
                  final selected = v == _value;
                  final cc = _colorFor(v);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _value = v),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? cc.withOpacity(0.14)
                                : Colors.grey.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  selected ? cc : Colors.grey.withOpacity(0.25),
                              width: selected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$v',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: selected ? cc : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Motivo (opzionale)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _showReasonInfo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.help_outline,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Text(
                              "Info",
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  "Seleziona uno o più motivi (non è obbligatorio).",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reasons.map((r) {
                  final isOn = _selected.contains(r);
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      setState(() {
                        if (isOn) {
                          _selected.remove(r);
                        } else {
                          _selected.add(r);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOn
                            ? c.withOpacity(0.14)
                            : Colors.grey.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isOn ? c : Colors.grey.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOn) ...[
                            Icon(Icons.check, size: 16, color: c),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            r,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isOn ? c : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Scrivi un commento (opzionale)…",
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          try {
                            await widget.onSubmit(
                              _value,
                              _controller.text.trim(),
                              _selected.toList(),
                            );
                            if (mounted) Navigator.pop(context, true);
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Invia valutazione",
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepInfo {
  final String label;
  final String? timestamp;

  _StepInfo({required this.label, this.timestamp});
}
