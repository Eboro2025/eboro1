class AboutData {
  final String? phone;
  final String? email;
  final List<dynamic>? assist_phones;
  final String? facebook;
  final String? twitter;
  final String? linkedin;
  final String? youtube;

  AboutData({
    this.phone,
    this.assist_phones,
    this.email,
    this.facebook,
    this.twitter,
    this.linkedin,
    this.youtube,
  });

  factory AboutData.fromJson(Map<String, dynamic> json) {
    List<dynamic> assistPhonesList;
    try {
      if (json['assist_phones'] is List) {
        assistPhonesList = json['assist_phones'];
      } else if (json['assist_phones'] is String &&
          json['assist_phones'] != null &&
          json['assist_phones'].toString().isNotEmpty) {
        assistPhonesList = [json['assist_phones']];
      } else {
        assistPhonesList = [];
      }
    } catch (e) {
      // print('⚠️ Error parsing assist_phones: $e');
      assistPhonesList = [];
    }
    
    return AboutData(
      phone: json['phone']?.toString(),
      assist_phones: assistPhonesList,
      email: json['email']?.toString(),
      facebook: json['facebook']?.toString(),
      twitter: json['twitter'],
      linkedin: json['linkedin'],
      youtube: json['youtube'],
    );
  }
}
