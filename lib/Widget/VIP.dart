import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VIP extends StatefulWidget {
  @override
  VIP2 createState() => VIP2();
}

class VIP2 extends State<VIP> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProviderController>(context);

    // لو الليستة null نتعامل مع فاضية
    final List<ProviderData> allProviders = (provider.providers ?? []).toList();

    // ترتيب حسب الحالة (المفتوح الأول، المقفول الآخر)
    allProviders.sort((a, b) {
      final aOpen = a.state == '1' ? 0 : 1;
      final bOpen = b.state == '1' ? 0 : 1;
      return aOpen.compareTo(bOpen);
    });

    // فلترة VIP فقط والحالة مش "2"
    final List<ProviderData> vipList = allProviders
        .where((p) => p.vip == 1 && p.state != '2')
        .toList();

    if (vipList.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: MyApp2.W! * .36, // ارتفاع الصف ككل
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: vipList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final eprovider = vipList[index];

          return GestureDetector(
            onTap: () async {
              if (eprovider.state == '1') {
                // الفرع مفتوح
                await provider.updateProduct(eprovider, context, true);
              } else {
                Auth2.show("closed");
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ===== الكارت المستدير (زي الصورة) =====
                Container(
                  width: MyApp2.W! * .22,
                  height: MyApp2.W! * .22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: myColor.withOpacity(0.3), // إطار خفيف
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: CachedNetworkImage(
                      imageUrl: eprovider.logo.toString(),
                      useOldImageOnUrlChange: true,
                      fit: BoxFit.cover,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) =>
                              Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: downloadProgress.progress,
                                  ),
                                ),
                              ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.store,
                        color: myColor,
                      ),
                      imageBuilder: (context, imageProvider) => Container(
                        foregroundDecoration: eprovider.state == '0'
                            ? const BoxDecoration(
                                color: Colors.grey,
                                backgroundBlendMode: BlendMode.saturation,
                              )
                            : const BoxDecoration(),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ===== اسم المحل تحت الصورة =====
                SizedBox(
                  width: MyApp2.W! * .24,
                  child: Text(
                    eprovider.name.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: myColor,
                      fontSize: MyApp2.fontSize14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
