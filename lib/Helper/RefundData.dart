class RefundData {
  final int? id;
  final int? orderId;
  final String? reason;
  final String? description;
  final String? status;
  final String? adminNotes;
  final String? image;
  final String? createdAt;
  final String? orderTotal;

  RefundData({
    this.id,
    this.orderId,
    this.reason,
    this.description,
    this.status,
    this.adminNotes,
    this.image,
    this.createdAt,
    this.orderTotal,
  });

  factory RefundData.fromJson(Map<String, dynamic> json) {
    return RefundData(
      id: json['id'],
      orderId: json['order_id'],
      reason: json['reason'],
      description: json['description'],
      status: json['status'],
      adminNotes: json['admin_notes'],
      image: json['image'],
      createdAt: json['created_at'],
      orderTotal: json['order_total']?.toString(),
    );
  }
}
