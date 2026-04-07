import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/search_result.dart';

class BibleService {
  static const String baseUrl = 'https://openamharicbible.vercel.app/api/am';

  // Get all books with caching
  Future<List<Book>> getBooks() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/books')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await prefs.setString('cached_books', response.body);
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      }
    } catch (e) {
      // Network failed, fall through to cache
    }

    final cached = prefs.getString('cached_books');
    if (cached != null) {
      final List<dynamic> data = json.decode(cached);
      return data.map((json) => Book.fromJson(json)).toList();
    }

    throw Exception('Failed to load books and no cache available');
  }

  // Get chapters of a book (returns list of chapter numbers with verse counts)
  Future<List<int>> getChapterNumbers(String abbv) async {
    final response = await http.get(Uri.parse('$baseUrl/books/$abbv/chapters'));
    if (response.statusCode == 200) {
      final List<dynamic> chapters = json.decode(response.body);
      return chapters.map((c) => int.tryParse(c['chapter'].toString()) ?? 0).where((c) => c > 0).toList();
    }
    throw Exception('Failed to load chapters');
  }

  // Get all verses in a chapter
  Future<List<String>> getChapterVerses(String abbv, int chapter) async {
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
