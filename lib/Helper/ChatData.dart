import 'package:eboro/Helper/UserData.dart';

class ChatData {
  final String?created_at;
  final String?Message;
  final String?image;
  final UserData? user;


  ChatData({
    this.created_at,
    this.Message,
    this.image,
    this.user,
  });

  factory ChatData.fromJson(Map<String, dynamic> json) {
    return ChatData(
      created_at: json['created_at'],
      Message: json['Message'],
      image: json['image'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
    );
  }
}
