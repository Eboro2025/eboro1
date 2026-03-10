class RateData {
  final int? id;
  final String?user_id;
  final String?value;
  final String?comment;
  final String?created_at;

  // of order

  RateData({
    this.id,
    this.user_id,
    this.value,
    this.comment,
    this.created_at,
  });

  factory RateData.fromJson(Map<String, dynamic> json) {
    return RateData(
      id: json['id'],
      user_id: json['user_id'].toString(),
      value: json['value'],
      comment: json['comment'],
      created_at: json['created_at'],
    );
  }
}
