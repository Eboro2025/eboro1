
class ContactsData {
  final int? id;
  final String?name;
  final String?phone;
  final String?email;
  final String?message;
  final String?reply;
  final String?subject;
  final String?file;
  final String?state;
  final String?created_at;


  ContactsData({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.message,
    this.reply,
    this.subject,
    this.file,
    this.state,
    this.created_at,
  });

  factory ContactsData.fromJson(Map<String, dynamic> json) {
    return ContactsData(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      message: json['message'],
      reply: json['reply'],
      subject: json['subject'],
      file: json['file'],
      state: json['state'],
      created_at: json['created_at'],
    );
  }
}
