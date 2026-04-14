import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/search_result.dart';
import 'database_service.dart';
import 'local_bible_service.dart';

class BibleService {
  static const String baseUrl = 'https://openamharicbible.vercel.app/api/am';
  
  final DatabaseService _dbService = DatabaseService();
  final LocalBibleService _localService = LocalBibleService();

  static const Set<String> ntAbbreviations = {
    'ማቴ', 'ማር', 'ሉቃ', 'ዮሐ', 'ሐዋ', 'ሮሜ', '1 ቆሮ', '2 ቆሮ', 'ገላ', 'ኤፌሶ', 'ፊል', 'ቆላ', '1ተሰ', '2ተሰ', '1ጢሞ', '2ጢሞ', 'ቲቶ', 'ዕብ', 'ያዕ', '1ጴጥ', '2ጴጥ', '1ዮሐ', '2ዮሐ', '3ዮሐ', 'ይሁ', 'ዮራእ'
  };

  static String _determineTestament(Map<String, dynamic> json) {
    final title = json['title']?.toString() ?? '';
    final abbv = json['abbv']?.toString() ?? '';
    
    // Check abbreviation first
    if (ntAbbreviations.contains(abbv)) return 'NT';
    
    // Fallback to title matching for edge cases like 2ዮሐ
    if (title.contains('የማቴዎስ') || 
        title.contains('የማርቆስ') || 
        title.contains('የሉቃስ') || 
        title.contains('የዮሐንስ') || 
        title.contains('የሐዋርያት') || 
        title.contains('ወደ ሮሜ') || 
        title.contains('ቆሮንቶስ') || 
        title.contains('ገላትያ') || 
        title.contains('ኤፌሶን') || 
        title.contains('ፊልጵስዩስ') || 
        title.contains('ቆላስይስ') || 
        title.contains('ተሰሎንቄ') || 
        title.contains('ጢሞቴዎስ') || 
        title.contains('ቲቶ') || 
        title.contains('ፊልሞና') || 
        title.contains('ዕብራውያን') || 
        title.contains('ያዕቆብ') || 
        title.contains('የጴጥሮስ') || 
        title.contains('የይሁዳ') || 
        title.contains('ራእይ') ||
        title.contains('2ዮሐ')) {
      return 'NT';
    }
    
    return 'OT';
  }

  // Get all books with caching + local integration
  Future<List<Book>> getBooks() async {
    final prefs = await SharedPreferences.getInstance();
    List<Book> allBooks = [];
    
    // 1. Load from cache or API to get full list
    try {
      final response = await http.get(Uri.parse('$baseUrl/books')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await prefs.setString('cached_books', response.body);
        final List<dynamic> data = json.decode(response.body);
        allBooks = data.map((json) {
          final testament = _determineTestament(json);
          String abbv = json['abbv'] ?? '';
          if (json['title'] == 'ወደ ፊልሞና') abbv = 'ፊልሞ';
          if (json['title'] == '2ዮሐ' && abbv.isEmpty) abbv = '2ዮሐ';
          
          return Book.fromJson(json).copyWith(
            testament: testament,
            abbv: abbv,
          );
        }).toList();
      }
    } catch (e) {
      final cached = prefs.getString('cached_books');
      if (cached != null) {
        final List<dynamic> data = json.decode(cached);
        allBooks = data.map((json) {
          final testament = _determineTestament(json);
          String abbv = json['abbv'] ?? '';
          if (json['title'] == 'ወደ ፊልሞና') abbv = 'ፊልሞ';
          if (json['title'] == '2ዮሐ' && abbv.isEmpty) abbv = '2ዮሐ';
          
          return Book.fromJson(json).copyWith(
            testament: testament,
            abbv: abbv,
          );
        }).toList();
      }
    }

    // 2. Add extra books from DB that might not be in the standard list
    final extraBooks = await _dbService.getExtraBooks();
    for (var extra in extraBooks) {
      if (!allBooks.any((b) => b.abbv == extra.abbv)) {
        allBooks.add(extra);
      }
    }

    if (allBooks.isNotEmpty) return allBooks;
    throw Exception('Failed to load books and no cache available');
  }

  // Get chapters of a book
  Future<List<int>> getChapterNumbers(String abbv) async {
    List<int> chapterNumbers = [];
    
    // 1. Check assets
    if (LocalBibleService.isAssetBook(abbv)) {
      final bookData = await _localService.loadBookFromAssets(abbv);
      if (bookData != null) {
        final List<dynamic> chapters = bookData['chapters'] ?? [];
        chapterNumbers = chapters.map((c) => int.tryParse(c['chapter'].toString()) ?? 0).toList();
      }
    }

    // 2. Fallback to API if list is empty
    if (chapterNumbers.isEmpty) {
      final response = await http.get(Uri.parse('$baseUrl/books/$abbv/chapters'));
      if (response.statusCode == 200) {
        final List<dynamic> chapters = json.decode(response.body);
        chapterNumbers = chapters.map((c) => int.tryParse(c['chapter'].toString()) ?? 0).where((c) => c > 0).toList();
      }
    }

    if (chapterNumbers.isNotEmpty) {
      chapterNumbers.sort();
      return chapterNumbers;
    }
    
    throw Exception('Failed to load chapters');
  }

  // Get all verses in a chapter
  Future<List<String>> getChapterVerses(String abbv, int chapter) async {
    // 1. Check assets
    if (LocalBibleService.isAssetBook(abbv)) {
      final assetVerses = await _localService.getChapterFromAssets(abbv, chapter);
      if (assetVerses != null) return assetVerses;
    }

    // 2. Check DB
    final dbVerses = await _dbService.getChapterVerses(abbv, chapter);
    if (dbVerses != null) return dbVerses;

    // 3. Fallback to API
    final response = await http.get(Uri.parse('$baseUrl/books/$abbv/chapters/$chapter'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return List<String>.from(data['verses']);
    }
    throw Exception('Failed to load verses');
  }

  // Get a single verse
  Future<String> getVerse(String abbv, int chapter, int verse) async {
    final response = await http.get(Uri.parse('$baseUrl/books/$abbv/chapters/$chapter/$verse'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['text']?.toString() ?? data['verse']?.toString() ?? '';
    }
    throw Exception('Failed to load verse');
  }

  // Search
  Future<List<SearchResult>> search(String query, {String? bookAbbv, String? testament, int? limit}) async {
    final Map<String, String> params = {'q': query};
    if (bookAbbv != null && bookAbbv.isNotEmpty) params['book'] = bookAbbv;
    if (testament != null && testament.isNotEmpty) params['testament'] = testament;
    if (limit != null && limit > 0) params['limit'] = '$limit';

    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      return results.map((json) => SearchResult.fromJson(json)).toList();
    }
    throw Exception('Search failed');
  }

  // Random verse for Verse of the Day with caching
  Future<Map<String, dynamic>> getRandomVerse() async {
    final prefs = await SharedPreferences.getInstance();
    
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final savedDate = prefs.getString('cached_verse_date');
    final cachedVerseStr = prefs.getString('cached_verse');

    // If it's the same day and we already have a cached verse, return it instantly
    if (savedDate == todayStr && cachedVerseStr != null) {
      return json.decode(cachedVerseStr);
    }

    try {
      final books = await getBooks();
      final random = Random();
      final book = books[random.nextInt(books.length)];
      final chapters = await getChapterNumbers(book.abbv);
      final chapter = chapters[random.nextInt(chapters.length)];
      final verses = await getChapterVerses(book.abbv, chapter);
      final verseNum = random.nextInt(verses.length) + 1;
      final text = verses[verseNum - 1];

      final verseData = {
        'book': book.title,
        'abbv': book.abbv,
        'chapter': chapter,
        'verse': verseNum,
        'text': text,
      };

      // Save to cache for offline use and sticking to "Verse of the Day"
      await prefs.setString('cached_verse_date', todayStr);
      await prefs.setString('cached_verse', json.encode(verseData));

      return verseData;
    } catch (e) {
      // If network fails, return the last fetched verse (even from another day)
      if (cachedVerseStr != null) {
        return json.decode(cachedVerseStr);
      }
      rethrow;
    }
  }
}
