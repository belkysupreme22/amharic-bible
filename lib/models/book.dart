class Book {
  final String title;
  final String abbv;
  final int chapters;

  Book({required this.title, required this.abbv, required this.chapters});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? '',
      abbv: json['abbv'] ?? '',
      chapters: json['chapters'] ?? 0,
    );
  }
}