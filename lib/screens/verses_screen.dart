import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/bible_service.dart';
import '../services/bookmark_service.dart';
import '../widgets/verse_card.dart';
import '../widgets/app_loading.dart';
import '../models/bookmark.dart';

class VersesScreen extends StatefulWidget {
  final String bookTitle;
  final String bookAbbv;
  final int chapter;
  final int? totalChapters;

  const VersesScreen({
    super.key,
    required this.bookTitle,
    required this.bookAbbv,
    required this.chapter,
    this.totalChapters,
  });

  @override
  State<VersesScreen> createState() => _VersesScreenState();
}

class _VersesScreenState extends State<VersesScreen> {
  final BibleService _bibleService = BibleService();
  final BookmarkService _bookmarkService = BookmarkService();
  late int _currentChapter;
  int? _totalChapters;
  List<String> _verses = [];
  List<_ProcessedVerse> _processedVerses = [];
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _totalChapters = widget.totalChapters;
    _loadVersesAndBookmarks();
    if (_totalChapters == null) {
      _loadTotalChapters();
    }
  }

  Future<void> _loadTotalChapters() async {
    try {
      final chapters = await _bibleService.getChapterNumbers(widget.bookAbbv);
      if (!mounted) return;
      setState(() {
        _totalChapters = chapters.length;
      });
    } catch (_) {
      // Silently fail, just won't show the total
    }
  }

  Future<void> _loadVersesAndBookmarks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final verses = await _bibleService.getChapterVerses(widget.bookAbbv, _currentChapter);
      final bookmarks = await _bookmarkService.getBookmarks();
      if (!mounted) return;
      setState(() {
        _verses = verses;
        _processedVerses = _processVerses(verses);
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

  List<_ProcessedVerse> _processVerses(List<String> verses) {
    if (verses.isEmpty) return [];

    List<_ProcessedVerse> processed = [];
    List<int> pendingNumbers = [];

    for (int i = 0; i < verses.length; i++) {
      String text = (verses[i]).trim();
      int verseNum = i + 1;

      if (text.isEmpty) {
        pendingNumbers.add(verseNum);
      } else {
        if (pendingNumbers.isNotEmpty) {
          processed.add(_ProcessedVerse(
            reference: "${pendingNumbers.first}-$verseNum",
            text: text,
            verseNumbers: [...pendingNumbers, verseNum],
          ));
          pendingNumbers = [];
        } else {
          processed.add(_ProcessedVerse(
            reference: "$verseNum",
            text: text,
            verseNumbers: [verseNum],
          ));
        }
      }
    }

    // Handle trailing empty verses by merging with the last valid verse
    if (pendingNumbers.isNotEmpty && processed.isNotEmpty) {
      var last = processed.removeLast();
      var allNumbers = [...last.verseNumbers, ...pendingNumbers];
      processed.add(_ProcessedVerse(
        reference: "${allNumbers.first}-${allNumbers.last}",
        text: last.text,
        verseNumbers: allNumbers,
      ));
    } else if (pendingNumbers.isNotEmpty) {
      // Entire chapter is empty (rare fallback)
      processed.add(_ProcessedVerse(
        reference: pendingNumbers.length > 1 ? "1-${pendingNumbers.length}" : "1",
        text: "",
        verseNumbers: pendingNumbers,
      ));
    }

    return processed;
  }

  Future<void> _toggleBookmark(String verseRef, String text, bool isBookmarked) async {
    final reference = '${widget.bookTitle} ${widget.chapter}:$verseRef';

    if (isBookmarked) {
      await _bookmarkService.removeBookmark(reference);
    } else {
      final bookmark = Bookmark(
        reference: reference,
        text: text,
        abbv: widget.bookAbbv,
        chapter: widget.chapter.toString(),
        verse: verseRef,
      );
      await _bookmarkService.addBookmark(bookmark);
    }

    final updatedBookmarks = await _bookmarkService.getBookmarks();
    setState(() {
      _bookmarks = updatedBookmarks;
    });
  }

  bool _isVerseBookmarked(String verseRef) {
    final reference = '${widget.bookTitle} ${widget.chapter}:$verseRef';
    return _bookmarks.any((b) => b.reference == reference);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.bookTitle} $_currentChapter',
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
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: AppLoading())
              : _error != null
                  ? Center(child: Text(_error!))
                  : RefreshIndicator(
                      onRefresh: _loadVersesAndBookmarks,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 100), // Extra bottom padding for navigation bar
                        itemCount: _processedVerses.length,
                        itemBuilder: (context, index) {
                          final verse = _processedVerses[index];
                          final isBookmarked = _isVerseBookmarked(verse.reference);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: VerseCard(
                              reference: verse.reference,
                              text: verse.text,
                              isBookmarked: isBookmarked,
                              onBookmarkToggle: (newValue) => _toggleBookmark(verse.reference, verse.text, isBookmarked),
                              showActions: true,
                              isReadingMode: true,
                            ),
                          );
                        },
                      ),
                    ),
          
          // Chapter Navigation Bar
          if (!_isLoading && _error == null)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavButton(
                        icon: LucideIcons.chevronLeft,
                        onPressed: _currentChapter > 1
                            ? () {
                                setState(() => _currentChapter--);
                                _loadVersesAndBookmarks();
                              }
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ምዕራፍ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary.withOpacity(0.8),
                              letterSpacing: 1.2,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Loga',
                            ),
                          ),
                          Text(
                            '$_currentChapter / ${_totalChapters ?? "?"}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              fontFamily: 'Loga',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      _NavButton(
                        icon: LucideIcons.chevronRight,
                        onPressed: (_totalChapters == null || _currentChapter < _totalChapters!)
                            ? () {
                                setState(() => _currentChapter++);
                                _loadVersesAndBookmarks();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Move FAB up to avoid overlapping with navigation bar
        child: FloatingActionButton.small(
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(LucideIcons.type, color: Colors.black),
        ),
      ),
    );
  }
}

class _ProcessedVerse {
  final String reference;
  final String text;
  final List<int> verseNumbers;

  _ProcessedVerse({
    required this.reference,
    required this.text,
    required this.verseNumbers,
  });
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: enabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.2),
          size: 24,
        ),
      ),
    );
  }
}
