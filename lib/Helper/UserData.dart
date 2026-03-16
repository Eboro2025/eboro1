import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  final int? id;
  final String?name;
   String?mobile;
  final String?email;
  final String?image;
  final String?front_id_image;
  final String?back_id_image;
  final String?license_image;
  final String?license_expire;
  String?address;
  final String?verify_code;
  final String?type;
  String?lat;
  String?long;
  String?house;
  String?intercom;
  String?cap;
  String?whatsapp;
  final int? online;
  final String?created_at;
  String? codice_fiscale;
  final bool age_verified;

  // Delivery address lives as static fields (survives user = fromJson(...) calls)
  // Access via UserData.deliveryAddress, etc.
  static String? deliveryAddress;
  static String? deliveryLat;
  static String? deliveryLong;

  // Getters: use ONLY delivery address (user-selected in current session), never profile address
  String? get activeAddress => deliveryAddress;
  String? get activeLat => deliveryLat;
  String? get activeLong => deliveryLong;

  // Save delivery address to SharedPreferences
  static Future<void> saveDeliveryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    if (deliveryAddress != null) {
      await prefs.setString('delivery_address', deliveryAddress!);
      if (deliveryLat != null) await prefs.setString('delivery_lat', deliveryLat!);
      if (deliveryLong != null) await prefs.setString('delivery_long', deliveryLong!);
    }
  }

  // Load delivery address from SharedPreferences
  static Future<void> loadDeliveryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    deliveryAddress = prefs.getString('delivery_address');
    deliveryLat = prefs.getString('delivery_lat');
    deliveryLong = prefs.getString('delivery_long');
  }

  // Clear saved delivery address
  static Future<void> clearDeliveryAddress() async {
    deliveryAddress = null;
    deliveryLat = null;
    deliveryLong = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('delivery_address');
    await prefs.remove('delivery_lat');
    await prefs.remove('delivery_long');
  }

  // VIP Business fields
  final bool? is_vip_business;
  final String? referral_code;
  final double? commission_percent;
  final double? wallet_balance;

  // '0' => 'Client',
  // '2' => 'Seller',
  // '5' => 'Branch_Admin'
  // '1' => 'Admin',
  // '3' => 'Cashier',
  // '4' => 'Delivery',

  UserData({
    this.id,
    this.name,
    this.mobile,
    this.email,
    this.image,
    this.front_id_image,
    this.back_id_image,
    this.license_image,
    this.license_expire,
    this.address,
    this.verify_code,
    this.type,
    this.lat,
    this.long,
    this.house,
    this.intercom,
    this.cap,
    this.whatsapp,
    this.online,
    this.created_at,
    this.codice_fiscale,
    this.age_verified = false,
    this.is_vip_business,
    this.referral_code,
    this.commission_percent,
    this.wallet_balance,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      email: json['email'],
      image: json['image'],
      house: json['house'],
      intercom: json['intercom'],
      cap: json['cap'],
      whatsapp: json['whatsapp'],
      front_id_image: json['front_id_image'],
      back_id_image: json['back_id_image'],
      license_image: json['license_image'],
      license_expire: json['license_expire'],
      address: json['address'],
      verify_code: json['verify_code'],
      type: json['type'],
      lat: json['lat'],
      long: json['long'],
      online: json['online'],
      created_at: json['created_at'],
      codice_fiscale: json['codice_fiscale']?.toString(),
      age_verified: json['age_verified'] == true || json['age_verified'] == 1,
      is_vip_business: json['is_vip_business'] == true || json['is_vip_business'] == 1,
      referral_code: json['referral_code']?.toString(),
      commission_percent: double.tryParse(json['commission_percent']?.toString() ?? ''),
      wallet_balance: double.tryParse(json['wallet_balance']?.toString() ?? ''),
    );
  }
}
