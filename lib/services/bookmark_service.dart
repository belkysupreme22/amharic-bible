import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';

class BookmarkService {
  static const String _key = 'bookmarks';

  // Save a bookmark
  Future<void> addBookmark(Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarksJson = prefs.getStringList(_key) ?? [];
    bookmarksJson.add(json.encode(bookmark.toJson()));
    await prefs.setStringList(_key, bookmarksJson);
  }

  // Get all bookmarks
  Future<List<Bookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarksJson = prefs.getStringList(_key) ?? [];
    return bookmarksJson.map((jsonStr) => Bookmark.fromJson(json.decode(jsonStr))).toList();
  }

  // Remove a bookmark by reference
  Future<void> removeBookmark(String reference) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarksJson = prefs.getStringList(_key) ?? [];
    bookmarksJson.removeWhere((jsonStr) {
      final map = json.decode(jsonStr);
      return map['reference'] == reference;
    });
    await prefs.setStringList(_key, bookmarksJson);
  }

  // Clear all bookmarks
  Future<void> clearAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}