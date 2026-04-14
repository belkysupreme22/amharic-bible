class Book {
  final String title;
  final String abbv;
  final int chapters;
  final String testament; // 'OT' or 'NT'

  Book({
    required this.title,
    required this.abbv,
    required this.chapters,
    this.testament = 'OT',
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? '',
      abbv: json['abbv'] ?? '',
      chapters: json['chapters'] ?? 0,
      testament: json['testament'] ?? 'OT',
    );
  }

  Book copyWith({String? testament, String? abbv}) {
    return Book(
      title: title,
      abbv: abbv ?? this.abbv,
      chapters: chapters,
      testament: testament ?? this.testament,
    );
  }
}