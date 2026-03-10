import 'package:eboro/RealTime/Provider/DeliveryOrderProvider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryOrderState extends StatefulWidget {
  @override
  DeliveryOrderState2 createState() => DeliveryOrderState2();
}

class DeliveryOrderState2 extends State<DeliveryOrderState> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // خليه listen: true عشان الـ UI يتحدّث مع تغيّر الحالة
    final deliveryOrder = Provider.of<DeliveryOrderProvider>(context);

    final status = deliveryOrder.selectedOrder?.status?.toString() ?? '';

    // لو مفيش أوردر مختار
    if (deliveryOrder.selectedOrder == null) {
      return const SizedBox.shrink();
    }

    // الحالات النهائية (كبير في النص)
    if (status == 'complete' ||
        status == 'cancelled' ||
        status == 'User Not Found' ||
        status == 'SyS_cancelled') {
      return _buildFinalStatus(context, status);
    }

    // الحالات اللي تمشي خطوة خطوة
    return _buildStepLine(context, status);
  }

  /// ------------------ 1) الـ STEPS LINE (pending → delivered) ------------------
  Widget _buildStepLine(BuildContext context, String status) {
    // ترتيب الحالات
    const List<String> flowStatuses = [
      'pending',
      'in progress',
      'to delivering',
      'on way',
      'on delivering',
      'delivered',
    ];

    // بيانات كل خطوة: أيكون + مفتاح ترجمة + صورة
    final List<_StepData> steps = [
      _StepData(
        statusKey: 'pending',
        image: 'images/icons/clipboard.png',
      ),
      _StepData(
        statusKey: 'in_progress',
        image: 'images/icons/chef.png',
      ),
      _StepData(
        statusKey: 'to_delivering',
        image: 'images/icons/shopping-bag.png',
      ),
      _StepData(
        statusKey: 'on_way',
        image: 'images/icons/backscooter.png',
      ),
      _StepData(
        statusKey: 'on_delivering',
        image: 'images/icons/scooter.png',
      ),
      _StepData(
        statusKey: 'delivered',
        image: 'images/icons/delivered.png',
      ),
    ];

    // نجيب index الحالة الحالية
    int currentIndex = flowStatuses.indexOf(status);
    if (currentIndex == -1) {
      // لو جت حالة غريبة، نرجّعها pending
      currentIndex = 0;
    }

    return Container(
      height: MediaQuery.of(context).size.height * .15,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            spreadRadius: 5,
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < steps.length; i++)
              _buildStepItem(
                context: context,
                data: steps[i],
                index: i,
                currentIndex: currentIndex,
              ),
          ],
        ),
      ),
    );
  }

  /// عنصر واحد في الخطوات (دائرة + صورة + نص)
  Widget _buildStepItem({
    required BuildContext context,
    required _StepData data,
    required int index,
    required int currentIndex,
  }) {
    // منطق الألوان:
    // - الخطوات اللي قبل الحالية: completed (أخضر)
    // - الحالية: active (لون أساسي)
    // - اللي بعد: رمادي
    Color borderColor;
    Color iconColor;
    Color textColor;

    if (index < currentIndex) {
      borderColor = Colors.green;
      iconColor = Colors.green;
      textColor = Colors.green;
    } else if (index == currentIndex) {
      borderColor = Colors.deepOrange;
      iconColor = Colors.deepOrange;
      textColor = Colors.deepOrange;
    } else {
      borderColor = Colors.grey;
      iconColor = Colors.grey;
      textColor = Colors.grey;
    }

    final String label =
        AppLocalizations.of(context)!.translate(data.statusKey) ??
            data.statusKey;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7.5),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: const BorderRadius.all(Radius.circular(500.0)),
          ),
          child: Image.asset(
            data.image,
            height: 30,
            width: 30,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// ------------------ 2) الحالات النهائية (complete / cancelled / ...) ------------------
  Widget _buildFinalStatus(BuildContext context, String status) {
    String image = 'images/icons/check.png';
    Color color = Colors.green;
    String key = 'complete';

    if (status == 'cancelled') {
      image = 'images/icons/close.png';
      color = Colors.red;
      key = 'cancelled';
    } else if (status == 'User Not Found') {
      image = 'images/icons/unknown.png';
      color = Colors.orange;
      key = 'user_not_found';
    } else if (status == 'SyS_cancelled') {
      image = 'images/icons/sys.png';
      color = Colors.deepPurple;
      key = 'SyS_cancelled';
    }

    final label = AppLocalizations.of(context)!.translate(key) ?? key;

    return Container(
      height: MediaQuery.of(context).size.height * .15,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            spreadRadius: 5,
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7.5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: color, width: 2.5),
                borderRadius: const BorderRadius.all(Radius.circular(500.0)),
              ),
              child: Image.asset(
                image,
                height: 40,
                width: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// كلاس بسيط يمسك بيانات كل خطوة
class _StepData {
  final String statusKey; // مفتاح الترجمة: "pending" / "in_progress" ...
  final String image; // مسار الصورة

  _StepData({
    required this.statusKey,
    required this.image,
  });
}
