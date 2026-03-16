import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:eboro/Helper/BannerData.dart';
import 'package:eboro/API/BannerApi.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/Providers/ClickProvider.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/main.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({Key? key}) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  List<BannerData> _banners = [];
  bool _loading = true;
  final PageController _pageController = PageController(viewportFraction: 0.88);
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (_banners.length <= 1) return;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _currentPage++;
      if (_currentPage >= _banners.length) {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await BannerApi.getActiveBanners();
      // print('📢 BannerSlider: ${banners.length} banners');
      if (!mounted) return;
      setState(() {
        _banners = banners;
        _loading = false;
      });
      if (banners.isNotEmpty) {
        _startAutoScroll();
      }
    } catch (e) {
      // print('❌ BannerSlider error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _onBannerTap(BannerData banner) async {
    if (banner.hasProviders) {
      final providerController = Provider.of<ProviderController>(context, listen: false);
      final allProviders = providerController.providers ?? [];
      final bannerProviderIds = banner.allProviderIds;

      final filteredProviders = allProviders.where((p) {
        return p.id != null && bannerProviderIds.contains(p.id) && !p.outOfDeliveryRange;
      }).toList();

      if (filteredProviders.length == 1) {
        // مطعم واحد → ننتقل مباشرة
        final provider = filteredProviders.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClickProvider(
              providerID: provider.id,
              name: provider.name ?? '',
            ),
          ),
        );
        return;
      } else if (filteredProviders.isNotEmpty) {
        // عدة مطاعم → نعرضهم كـ section في نفس الصفحة
        providerController.setBannerProviders(
          filteredProviders,
          title: banner.title ?? 'Dal Banner',
        );
        return;
      }
    }

    // لو البانر فيه رابط خارجي
    if (banner.link != null && banner.link!.isNotEmpty) {
      final uri = Uri.tryParse(banner.link!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Dialog لإدارة محلات البانر - اختيار أو إلغاء محلات
  void _showEditProvidersDialog(BannerData banner) {
    final providerController = Provider.of<ProviderController>(context, listen: false);
    final allProviders = providerController.providers ?? [];

    // تهيئة حالة كل محل بشكل صريح (checked / unchecked)
    final existingIds = banner.allProviderIds.toSet();
    final Map<int, bool> checkedState = {};
    for (var p in allProviders) {
      if (p.id != null) {
        checkedState[p.id!] = existingIds.contains(p.id);
      }
    }

    // print('🔧 EditBanner: banner=${banner.id}, existingIds=$existingIds, allProviders=${allProviders.length}');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final selectedCount = checkedState.values.where((v) => v).length;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.store, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Gestisci ristoranti - ${banner.title ?? "Banner"}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$selectedCount ristoranti selezionati',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allProviders.length,
                        itemBuilder: (_, index) {
                          final provider = allProviders[index];
                          if (provider.id == null) return const SizedBox.shrink();
                          final pid = provider.id!;
                          final isChecked = checkedState[pid] ?? false;

                          return CheckboxListTile(
                            value: isChecked,
                            activeColor: myColor,
                            secondary: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: fixImageUrl(provider.logo),
                                width: 40, height: 40,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 40, height: 40,
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.store, color: Colors.grey.shade400, size: 20),
                                ),
                              ),
                            ),
                            title: Text(
                              provider.name ?? '',
                              style: TextStyle(
                                fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                checkedState[pid] = val ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    // أزرار الحفظ والإلغاء
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Annulla'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                // جمع كل المحلات المختارة
                                final selectedIds = checkedState.entries
                                    .where((e) => e.value)
                                    .map((e) => e.key)
                                    .toList();

                                // print('💾 Saving banner ${banner.id} providers: $selectedIds');

                                Navigator.pop(ctx);
                                final success = await BannerApi.updateBannerProviders(
                                  banner.id!,
                                  selectedIds,
                                );
                                if (success) {
                                  // إعادة تحميل البانرات
                                  _loadBanners();
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Errore nel salvataggio'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: myColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Salva',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 140,
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              // إعادة تشغيل الـ auto-scroll عند السحب يدوياً
              _startAutoScroll();
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return _buildBannerCard(banner);
            },
          ),
        ),
        // نقاط المؤشر
        if (_banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildBannerCard(BannerData banner) {
    return GestureDetector(
      onTap: () => _onBannerTap(banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  memCacheHeight: 400,
                  memCacheWidth: 800,
                  maxHeightDiskCache: 500,
                  maxWidthDiskCache: 1000,
                  progressIndicatorBuilder: (context, url, progress) =>
                      Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progress.progress,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 32, color: Colors.grey),
                  ),
                ),
              ),

              // Offer/DailySpecial badge
              if (banner.badgeText != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: banner.hasDailySpecial
                          ? const Color(0xFF6C5CE7)
                          : banner.offerType == 'free_delivery' || banner.offerType == 'two_for_one_free_delivery'
                              ? const Color(0xFF00B894)
                              : const Color(0xFFE17055),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      banner.badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Gradient overlay for text readability
              if (banner.title != null && banner.title!.isNotEmpty)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

              // Title text on the left
              if (banner.title != null && banner.title!.isNotEmpty)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  right: null,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        if (banner.providerName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              banner.providerName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Scopri di più',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // زر تعديل المحلات - يظهر للأدمن فقط
              if (MyApp2.type == '1')
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showEditProvidersDialog(banner),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
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
