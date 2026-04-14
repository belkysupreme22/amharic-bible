import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/book.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bible_extras.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Books table (for Extra books not in assets)
    await db.execute('''
      CREATE TABLE books (
        abbv TEXT PRIMARY KEY,
        title TEXT,
        chapters INTEGER,
        testament TEXT
      )
    ''');

    // Chapters/Verses table
    await db.execute('''
      CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_abbv TEXT,
        chapter INTEGER,
        verse_num INTEGER,
        text TEXT,
        FOREIGN KEY (book_abbv) REFERENCES books (abbv)
      )
    ''');
  }

  // --- Book Methods ---

  Future<void> insertBook(Book book) async {
    final db = await database;
    await db.insert(
      'books',
      {
        'abbv': book.abbv,
        'title': book.title,
        'chapters': book.chapters,
        'testament': book.testament,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Book>> getExtraBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books');
    return List.generate(maps.length, (i) {
      return Book(
        title: maps[i]['title'],
        abbv: maps[i]['abbv'],
        chapters: maps[i]['chapters'],
        testament: maps[i]['testament'],
      );
    });
  }

  // --- Verse Methods ---

  Future<void> insertVerses(String abbv, int chapter, List<String> verses) async {
    final db = await database;
    final batch = db.batch();
    
    // Delete existing to avoid duplicates if re-downloaded
    batch.delete('verses', where: 'book_abbv = ? AND chapter = ?', whereArgs: [abbv, chapter]);

    for (int i = 0; i < verses.length; i++) {
      batch.insert('verses', {
        'book_abbv': abbv,
        'chapter': chapter,
        'verse_num': i + 1,
        'text': verses[i],
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>?> getChapterVerses(String abbv, int chapter) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'book_abbv = ? AND chapter = ?',
      whereArgs: [abbv, chapter],
      orderBy: 'verse_num ASC',
    );

    if (maps.isEmpty) return null;
    return maps.map((m) => m['text'] as String).toList();
  }

  Future<bool> isBookDownloaded(String abbv, int expectedChapters) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(DISTINCT chapter) as count FROM verses WHERE book_abbv = ?',
      [abbv],
    );
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count >= expectedChapters;
  }

  Future<void> deleteBook(String abbv) async {
    final db = await database;
    await db.delete('verses', where: 'book_abbv = ?', whereArgs: [abbv]);
    await db.delete('books', where: 'abbv = ?', whereArgs: [abbv]);
  }
}
