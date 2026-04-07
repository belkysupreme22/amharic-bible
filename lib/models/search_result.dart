class SearchResult {
  final String book;
  final String abbv;
  final String chapter;
  final String verse;
  final String text;

  SearchResult({
    required this.book,
    required this.abbv,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      book: json['book'] ?? '',
      abbv: json['abbv'] ?? '',
      chapter: json['chapter']?.toString() ?? '',
      verse: json['verse']?.toString() ?? '',
      text: json['text'] ?? '',
    );
  }
}