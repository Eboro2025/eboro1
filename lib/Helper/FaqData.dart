class FaqData {
  final int? id;
  final String? question;
  final String? answer;
  final String? category;

  FaqData({this.id, this.question, this.answer, this.category});

  factory FaqData.fromJson(Map<String, dynamic> json) {
    return FaqData(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      category: json['category'],
    );
  }
}
