import 'package:eboro/Helper/BranchData.dart';

class BranchStaffData {
  final int? id;
  final String?name;
  final String?mobile;
  final String?email;
  final String?image;
  final String?address;
  final String?type;
  final BranchData? branch;
  final String?created_at;

  BranchStaffData({
    this.id,
    this.name,
    this.mobile,
    this.email,
    this.image,
    this.address,
    this.type,
    this.branch,
    this.created_at,


  });

  factory BranchStaffData.fromJson(Map<String, dynamic> json) {
    return BranchStaffData(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      email: json['email'],
      image: json['image'],
      address: json['address'],
      type: json['type'],
      branch: json['branch'] != null ? BranchData.fromJson(json['branch']) : null,
      created_at: json['created_at'],
    );
  }
}
