class ShippingData {
  final String?shipping;
  final String?Tax;
  final String?Time;
  final String?Duration;
  final String?Distance;
  final String?OrderMin;


  ShippingData({
    this.shipping,
    this.Tax,
    this.Time,
    this.Duration,
    this.Distance,
    this.OrderMin
  });

  factory ShippingData.fromJson(Map<String, dynamic> json) {
    return ShippingData(
      shipping: json['shipping']  != null ? json['shipping'].toString() : null,
      Tax: json['Tax']  != null ? json['Tax'].toString() : null,
      Time: json['Time']  != null ? json['Time'].toString() : null,
      Duration: json['Duration'] != null ? json['Duration'].toString() : null,
      Distance: json['Distance'] != null ? json['Distance'].toString() : null,
      OrderMin:json['OrderMin'] != null ? json['OrderMin'].toString() : null,
    );
  }
}
