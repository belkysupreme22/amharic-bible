import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/bible_service.dart';
import '../services/bookmark_service.dart';
import '../widgets/verse_card.dart';
import '../widgets/app_loading.dart';
import '../utils/theme_provider.dart';
import '../models/bookmark.dart';

class VersesScreen extends StatefulWidget {
  final String bookTitle;
  final String bookAbbv;
  final int chapter;

  const VersesScreen({
    super.key,
    required this.bookTitle,
    required this.bookAbbv,
    required this.chapter,
  });

  @override
  State<VersesScreen> createState() => _VersesScreenState();
}

class _VersesScreenState extends State<VersesScreen> {
  final BibleService _bibleService = BibleService();
  final BookmarkService _bookmarkService = BookmarkService();
  List<String> _verses = [];
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVersesAndBookmarks();
  }

  Future<void> _loadVersesAndBookmarks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final verses = await _bibleService.getChapterVerses(widget.bookAbbv, widget.chapter);
      final bookmarks = await _bookmarkService.getBookmarks();
      if (!mounted) return;
      setState(() {
        _verses = verses;
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'ምዕራፎችን መጫን አልተቻለም።';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark(int verseNum, bool isBookmarked) async {
    final reference = '${widget.bookTitle} ${widget.chapter}:$verseNum';
    final text = _verses[verseNum - 1];

    if (isBookmarked) {
      await _bookmarkService.removeBookmark(reference);
    } else {
      final bookmark = Bookmark(
        reference: reference,
        text: text,
        abbv: widget.bookAbbv,
        chapter: widget.chapter.toString(),
        verse: verseNum.toString(),
      );
      await _bookmarkService.addBookmark(bookmark);
    }

    final updatedBookmarks = await _bookmarkService.getBookmarks();
    setState(() {
      _bookmarks = updatedBookmarks;
    });
  }

  bool _isVerseBookmarked(int verseNum) {
    final reference = '${widget.bookTitle} ${widget.chapter}:$verseNum';
    return _bookmarks.any((b) => b.reference == reference);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.bookTitle} ${widget.chapter}',
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, size: 20, color: theme.colorScheme.primary),
            onPressed: _loadVersesAndBookmarks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoading())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadVersesAndBookmarks,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 40),
                    itemCount: _verses.length,
                    itemBuilder: (context, index) {
                      final verseNum = index + 1;
                      final text = _verses[index];
                      final reference = '$verseNum';
                      final isBookmarked = _isVerseBookmarked(verseNum);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: VerseCard(
                          reference: reference,
                          text: text,
                          isBookmarked: isBookmarked,
                          onBookmarkToggle: (newValue) => _toggleBookmark(verseNum, isBookmarked),
                          showActions: true,
                          isReadingMode: true,
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          // Open a simple font size slider maybe? Or just use settings
          Navigator.pushNamed(context, '/settings'); // Assuming settings handles it
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(LucideIcons.type, color: Colors.black),
      ),
    );
  }
}
