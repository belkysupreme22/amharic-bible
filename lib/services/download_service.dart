import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'database_service.dart';
import 'bible_service.dart';

class DownloadService {
  final DatabaseService _dbService = DatabaseService();
  final BibleService _bibleService = BibleService();

  // Stream to report progress (0.0 to 1.0)
  Stream<double> downloadBook(Book book) async* {
    final String abbv = book.abbv;
    final int chapters = book.chapters;

    await _dbService.insertBook(book);

    for (int i = 1; i <= chapters; i++) {
      try {
        final verses = await _bibleService.getChapterVerses(abbv, i);
        await _dbService.insertVerses(abbv, i, verses);
        yield i / chapters;
      } catch (e) {
        print('Error downloading $abbv chapter $i: $e');
        rethrow;
      }
    }
  }

  Future<bool> isBookDownloaded(String abbv, int chapters) async {
    return await _dbService.isBookDownloaded(abbv, chapters);
  }

  Future<void> removeDownloadedBook(String abbv) async {
    await _dbService.deleteBook(abbv);
  }
}
