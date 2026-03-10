import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Auth/EditProfile.dart';
import 'package:eboro/Client/MyCart.dart';
import 'package:eboro/Client/MyFavorit.dart';
import 'package:eboro/Client/MyOrders.dart';
import 'package:eboro/Client/AssistenzaPage.dart';
import 'package:eboro/Client/Contact Us/WriteContact.dart';
import 'package:eboro/All/language.dart';
import 'package:eboro/All/PrivacyPage.dart';
import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/Vip/VipBusinessScreen.dart';
import 'package:eboro/API/Categories.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../RealTime/Provider/CartTextProvider.dart';

class MyProfile extends StatefulWidget {
  @override
  Profile createState() => Profile();
}

class Profile extends State<MyProfile> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    try {
      await Auth2.getUserDetails(context);
    } catch (e) {
      // print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (mounted) {
      // print(Auth2.user?.lat ?? 'No lat');
      // print(Auth2.user?.long ?? 'No long');
    }
  }

  @override
  void dispose() {
    // Pulizia quando il widget viene distrutto
    super.dispose();
  }

  String password = "••••••••••";

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: _isLoading || Auth2.user == null
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(myColor),
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Page content
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 16 + MediaQuery.of(context).padding.top),
                        // Overlapping profile picture
                        Transform.translate(
                          offset: Offset(0, -50),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.grey.shade200,
                                    child: Auth2.user!.image != null &&
                                            Auth2.user!.image!.isNotEmpty &&
                                            Auth2.user!.image!.trim().isNotEmpty
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: Auth2.user!.image!,
                                              fit: BoxFit.cover,
                                              width: 110,
                                              height: 110,
                                              placeholder: (context, url) =>
                                                  Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: myColor,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) => Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey.shade400,
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                Auth2.user!.name ?? '',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                Auth2.user!.email ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Info cards
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildProfileDetailsCard(context),
                              SizedBox(height: 20),

                              _buildSectionTitle(
                                AppLocalizations.of(context)!
                                    .translate("myprofile"),
                              ),
                              SizedBox(height: 8),
                              _buildMenuCard(context),
                              SizedBox(height: 30),
                            ],
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    int maxLines = 1,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(
            AppLocalizations.of(context)!.translate("myprofile"),
            style: TextStyle(
              fontSize: 14,
              color: myColor2,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: Icon(Icons.person_outline, color: myColor),
          children: [
            _buildInfoRow(
              icon: Icons.phone_rounded,
              title: AppLocalizations.of(context)!
                  .translate("mobilenumber"),
              value: Auth2.user!.mobile ?? '',
              iconColor: Colors.green,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              title: AppLocalizations.of(context)!.translate("address"),
              value: Auth2.user!.address ?? '',
              iconColor: Colors.red,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.lock_rounded,
              title: AppLocalizations.of(context)!.translate("password"),
              value: password,
              iconColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    int maxLines = 1,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    final cart = Provider.of<CartTextProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.edit,
            label: AppLocalizations.of(context)!.translate("editmyprofile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfile()),
              );
            },
          ),
          if (Auth2.user!.email != "info@eboro.com") ...[
            _buildMenuItem(
              icon: Icons.favorite_border,
              label: AppLocalizations.of(context)!.translate("myfavorite"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyFavorite()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.shopping_cart_outlined,
              label: AppLocalizations.of(context)!.translate("mycart"),
              onTap: () async {
                await cart.updateCart();
                if (cart.cart != null && cart.cart!.total_price != null && cart.cart!.total_price! > 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyCart()),
                  );
                } else {
                  Auth2.show("Cart is empty");
                }
              },
            ),
            _buildMenuItem(
              icon: Icons.shopping_bag_outlined,
              label: AppLocalizations.of(context)!.translate("myorders"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyOrders()),
                );
              },
            ),
          ],
          if (Auth2.user?.is_vip_business == true)
            _buildMenuItem(
              icon: Icons.handshake,
              label: 'VIP Business',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VipBusinessScreen()),
                );
              },
            ),
          _buildMenuItem(
            icon: Icons.language,
            label: AppLocalizations.of(context)!.translate("language"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Language()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.person_add_outlined,
            label: 'Invita un amico',
            onTap: () {
              Share.share('Scarica Eboro e ordina i tuoi piatti preferiti! https://play.google.com/store/apps/details?id=com.codiano.eboro');
            },
          ),
          _buildMenuItem(
            icon: Icons.support_agent,
            label: 'Assistenza',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssistenzaPage()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPage()),
              );
            },
          ),
          if (Auth2.user!.email != "info@eboro.com") ...[
            Divider(height: 1),
            _buildMenuItem(
              icon: Icons.restore_from_trash_rounded,
              label: AppLocalizations.of(context)!.translate("delete"),
              onTap: () {
                _showDeleteBottomSheet(context);
              },
            ),
          ],
          Divider(height: 1),
          _buildMenuItem(
            icon: Icons.logout,
            label: AppLocalizations.of(context)!.translate("logout"),
            onTap: () {
              Auth2.deleteToken(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: myColor),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: myColor2,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  void _showDeleteBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.restore_from_trash_rounded),
              title: const Text('Delete Account'),
              onTap: () {
                Categories2.delete_user(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
