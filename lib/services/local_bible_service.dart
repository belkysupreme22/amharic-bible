import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book.dart';

class LocalBibleService {
  static const String assetPath = 'assets/bible';

  // The 66 standard books that are bundled as assets
  static const Set<String> assetBooks = {
    'ዘፍ', 'ዘጸ', 'ዘሌ', 'ዘኍ', 'ዘዳ', 'መ.ኢያ', 'መ.መሣ', 'መ.ሩት', 'መ.ሳሙ1', 'መ.ሳሙ2', 'መ.ነገ1', 'መ.ነገ2', 'መ.ዜና1', 'መ.ዜና2', 'መ.ዕዝ', 'መ.ነህ', 'መ.አስ', 'መ.ኢዮ', 'መ.ዳ', 'መ.ምሳ', 'መ.መክ', 'መኃ.መኃ.ዘሰ', 'ትን.ኢሳ', 'ትን.ኤር', 'ሰቆ.ኤር', 'ት.ሕዝ', 'ት.ዳን', 'ት.ሆሴ', 'ት.ኢዮ', 'ት.አሞ', 'ት.አብ', 'ት.ዮና', 'ት.ሚክ', 'ት.ናሆ', 'ት.ዕንባ', 'ት.ሶፎ', 'ት.ሐጌ', 'ት.ዘካር', 'ት.ሚል',
    'ማቴ', 'ማር', 'ሉቃ', 'ዮሐ', 'ሐዋ', 'ሮሜ', '1 ቆሮ', '2 ቆሮ', 'ገላ', 'ኤፌሶ', 'ፊል', 'ቆላ', '1ተሰ', '2ተሰ', '1ጢሞ', '2ጢሞ', 'ቲቶ', 'ፊልሞ', 'ዕብ', 'ያዕ', '1ጴጥ', '2ጴጥ', '1ዮሐ', '2ዮሐ', '3ዮሐ', 'ይሁ', 'ዮራእ'
  };

  static bool isAssetBook(String abbv) => assetBooks.contains(abbv);

  // Load a book from assets
  Future<Map<String, dynamic>?> loadBookFromAssets(String abbv) async {
    try {
      final String jsonString = await rootBundle.loadString('$assetPath/$abbv.json');
      return json.decode(jsonString);
    } catch (e) {
      print('Error loading asset book $abbv: $e');
      return null;
    }
  }

  // Get verses for a specific chapter from assets
  Future<List<String>?> getChapterFromAssets(String abbv, int chapter) async {
    final bookData = await loadBookFromAssets(abbv);
    if (bookData == null) return null;

    final List<dynamic> chapters = bookData['chapters'] ?? [];
    final chapterData = chapters.firstWhere(
      (c) => c['chapter'] == chapter,
      orElse: () => null,
    );

    if (chapterData != null) {
      return List<String>.from(chapterData['verses']);
    }
    return null;
  }
}
