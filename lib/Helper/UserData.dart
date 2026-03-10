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

  // Delivery address (separate from profile address)
  String? deliveryAddress;
  String? deliveryLat;
  String? deliveryLong;

  // Getters: use delivery address if set, otherwise fall back to profile
  String? get activeAddress => deliveryAddress ?? address;
  String? get activeLat => deliveryLat ?? lat;
  String? get activeLong => deliveryLong ?? long;

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
      is_vip_business: json['is_vip_business'] == true || json['is_vip_business'] == 1,
      referral_code: json['referral_code']?.toString(),
      commission_percent: double.tryParse(json['commission_percent']?.toString() ?? ''),
      wallet_balance: double.tryParse(json['wallet_balance']?.toString() ?? ''),
    );
  }
}
