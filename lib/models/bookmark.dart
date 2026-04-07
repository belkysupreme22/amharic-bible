class Bookmark {
  final String reference; // e.g., "ሮሜ 1:1"
  final String text;
  final String abbv;
  final String chapter;
  final String verse;

  Bookmark({
    required this.reference,
    required this.text,
    required this.abbv,
    required this.chapter,
    required this.verse,
  });

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'text': text,
        'abbv': abbv,
        'chapter': chapter,
        'verse': verse,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        reference: json['reference'],
        text: json['text'],
        abbv: json['abbv'],
        chapter: json['chapter'],
        verse: json['verse'],
      );
}