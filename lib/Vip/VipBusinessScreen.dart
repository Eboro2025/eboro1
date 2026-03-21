import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/VipWallet.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class VipBusinessScreen extends StatefulWidget {
  const VipBusinessScreen({Key? key}) : super(key: key);

  @override
  _VipBusinessScreenState createState() => _VipBusinessScreenState();
}

class _VipBusinessScreenState extends State<VipBusinessScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  double _walletBalance = 0;
  String _referralCode = '';
  String _referralUrl = '';
  double _commissionPercent = 0;
  int _referralCount = 0;
  double _totalEarned = 0;
  List<dynamic> _recentTransactions = [];
  List<dynamic> _referrals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        VipWalletApi.getWallet(),
        VipWalletApi.getReferrals(),
        VipWalletApi.getQrcodeUrl(),
      ]);

      final walletData = results[0] as Map<String, dynamic>?;
      final referralsData = results[1] as List<dynamic>?;
      final qrData = results[2] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          if (walletData != null) {
            _walletBalance = double.tryParse(walletData['wallet_balance']?.toString() ?? '') ?? 0;
            _referralCode = walletData['referral_code']?.toString() ?? '';
            _commissionPercent = double.tryParse(walletData['commission_percent']?.toString() ?? '') ?? 0;
            _referralCount = int.tryParse(walletData['referral_count']?.toString() ?? '') ?? 0;
            _totalEarned = double.tryParse(walletData['total_earned']?.toString() ?? '') ?? 0;
            _recentTransactions = walletData['recent_transactions'] as List<dynamic>? ?? [];
          }
          if (referralsData != null) {
            _referrals = referralsData;
          }
          if (qrData != null) {
            _referralUrl = qrData['referral_url']?.toString() ?? '';
            if (_referralCode.isEmpty) {
              _referralCode = qrData['referral_code']?.toString() ?? '';
            }
          }
          _loading = false;
        });
      }
    } catch (e) {
      // Load data error
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        title: Text(
          'VIP Business',
          style: TextStyle(color: Colors.white, fontSize: MyApp2.fontSize20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildWalletCard(),
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: myColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: myColor,
                      labelStyle: TextStyle(
                        fontSize: MyApp2.fontSize14,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: [
                        Tab(text: AppLocalizations.of(context)?.translate('vip_qrcode') ?? 'QR Code'),
                        Tab(text: AppLocalizations.of(context)?.translate('vip_referrals') ?? 'Referral'),
                        Tab(text: AppLocalizations.of(context)?.translate('vip_transactions') ?? 'Movimenti'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildQrCodeTab(),
                        _buildReferralsTab(),
                        _buildTransactionsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)?.translate('vip_wallet_balance') ?? 'Saldo Wallet',
            style: TextStyle(color: Colors.white70, fontSize: MyApp2.fontSize14),
          ),
          const SizedBox(height: 8),
          Text(
            '${_walletBalance.toStringAsFixed(2)} \u20AC',
            style: TextStyle(
              color: const Color(0xFF4ade80),
              fontSize: MyApp2.fontSize26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                AppLocalizations.of(context)?.translate('vip_referral_count') ?? 'Clienti',
                _referralCount.toString(),
                Icons.people,
              ),
              _buildStatItem(
                AppLocalizations.of(context)?.translate('vip_commission') ?? 'Commissione',
                '${_commissionPercent.toStringAsFixed(1)}%',
                Icons.percent,
              ),
              _buildStatItem(
                AppLocalizations.of(context)?.translate('vip_total_earned') ?? 'Guadagnato',
                '${_totalEarned.toStringAsFixed(2)}\u20AC',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: MyApp2.fontSize16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white54, fontSize: MyApp2.fontSize12),
        ),
      ],
    );
  }

  Widget _buildQrCodeTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)?.translate('vip_your_qrcode') ?? 'Il tuo QR Code',
                  style: TextStyle(
                    fontSize: MyApp2.fontSize18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a1a1a),
                  ),
                ),
                const SizedBox(height: 16),
                if (_referralUrl.isNotEmpty)
                  QrImageView(
                    data: _referralUrl,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1a1a1a),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1a1a1a),
                    ),
                  )
                else
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _referralCode,
                    style: TextStyle(
                      fontSize: MyApp2.fontSize18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: myColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _referralUrl,
                    style: TextStyle(fontSize: MyApp2.fontSize12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _referralUrl));
                          Auth2.show(AppLocalizations.of(context)?.translate('vip_link_copied') ?? 'Link copiato!');
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(AppLocalizations.of(context)?.translate('vip_copy_link') ?? 'Copia Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final box = context.findRenderObject() as RenderBox?;
                          // ignore: deprecated_member_use
                          Share.share(
                            '${AppLocalizations.of(context)?.translate('vip_share_text') ?? 'Ordina su Eboro con il mio link!'}\n$_referralUrl',
                            sharePositionOrigin: box != null
                                ? box.localToGlobal(Offset.zero) & box.size
                                : Rect.fromLTWH(0, 0, 100, 100),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: Text(AppLocalizations.of(context)?.translate('vip_share') ?? 'Condividi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralsTab() {
    if (_referrals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.translate('vip_no_referrals') ?? 'Nessun referral ancora',
              style: TextStyle(color: Colors.grey, fontSize: MyApp2.fontSize16),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.translate('vip_share_qr') ?? 'Condividi il tuo QR Code per iniziare!',
              style: TextStyle(color: Colors.grey.shade400, fontSize: MyApp2.fontSize14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _referrals.length,
      itemBuilder: (context, index) {
        final ref = _referrals[index] as Map<String, dynamic>;
        final ordersCount = ref['orders_count'] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: myColor.withValues(alpha: 0.1),
                child: Text(
                  (ref['name']?.toString() ?? '?')[0].toUpperCase(),
                  style: TextStyle(color: myColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref['name']?.toString() ?? '-',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: MyApp2.fontSize16),
                    ),
                    Text(
                      ref['created_at']?.toString().substring(0, 10) ?? '',
                      style: TextStyle(color: Colors.grey, fontSize: MyApp2.fontSize12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$ordersCount ${AppLocalizations.of(context)?.translate('orders') ?? 'ordini'}',
                  style: TextStyle(
                    color: const Color(0xFF2E7D32),
                    fontSize: MyApp2.fontSize12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    if (_recentTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.translate('vip_no_transactions') ?? 'Nessun movimento',
              style: TextStyle(color: Colors.grey, fontSize: MyApp2.fontSize16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _recentTransactions.length,
      itemBuilder: (context, index) {
        final tx = _recentTransactions[index] as Map<String, dynamic>;
        final isCredit = tx['type'] == 'credit';
        final amount = double.tryParse(tx['amount']?.toString() ?? '') ?? 0;
        final balanceAfter = double.tryParse(tx['balance_after']?.toString() ?? '') ?? 0;
        final action = tx['action']?.toString() ?? '';
        final description = tx['description']?.toString() ?? '';
        final date = tx['created_at']?.toString() ?? '';

        String actionLabel;
        IconData actionIcon;
        switch (action) {
          case 'commission':
            actionLabel = AppLocalizations.of(context)?.translate('vip_action_commission') ?? 'Commissione';
            actionIcon = Icons.monetization_on;
            break;
          case 'order_payment':
            actionLabel = AppLocalizations.of(context)?.translate('vip_action_payment') ?? 'Pagamento';
            actionIcon = Icons.shopping_cart;
            break;
          case 'admin_adjustment':
            actionLabel = 'Admin';
            actionIcon = Icons.admin_panel_settings;
            break;
          case 'refund':
            actionLabel = AppLocalizations.of(context)?.translate('refund') ?? 'Rimborso';
            actionIcon = Icons.undo;
            break;
          default:
            actionLabel = action;
            actionIcon = Icons.swap_horiz;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  actionIcon,
                  color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actionLabel,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: MyApp2.fontSize14),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey, fontSize: MyApp2.fontSize12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      date.length >= 16 ? date.substring(0, 16).replaceAll('T', ' ') : date,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: MyApp2.fontSize12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : '-'}${amount.toStringAsFixed(2)} \u20AC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: MyApp2.fontSize14,
                      color: isCredit ? const Color(0xFF16a34a) : const Color(0xFFdc3545),
                    ),
                  ),
                  Text(
                    '${AppLocalizations.of(context)?.translate('vip_balance') ?? 'Saldo'}: ${balanceAfter.toStringAsFixed(2)} \u20AC',
                    style: TextStyle(color: Colors.grey, fontSize: MyApp2.fontSize12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
