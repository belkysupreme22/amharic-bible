import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/bookmark_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/verse_card.dart';
import '../utils/theme_provider.dart';
import '../models/bookmark.dart';

class BookmarksScreen extends StatefulWidget {                         
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });
    final bookmarks = await _bookmarkService.getBookmarks();
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks;
      _isLoading = false;
    });
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    await _bookmarkService.removeBookmark(bookmark.reference);
    _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('ምልክቶች', style: theme.textTheme.displaySmall?.copyWith(fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, size: 20, color: theme.colorScheme.primary),
            onPressed: _loadBookmarks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoading())
          : _bookmarks.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBookmarks,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 120),
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = _bookmarks[index];
                      return Dismissible(
                        key: Key(bookmark.reference),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 30),
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(LucideIcons.trash2, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteBookmark(bookmark),
                        child: VerseCard(
                          reference: bookmark.reference,
                          text: bookmark.text,
                          isBookmarked: true,
                          onBookmarkToggle: (_) => _deleteBookmark(bookmark),
                          showActions: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bookmark, size: 60, color: theme.colorScheme.primary.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            'ምንም የተቀመጡ ምልክቶች የሉም',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ጥቅሶችን እዚህ ለማግኘት በምታነብበት ጊዜ ምልክት አድርግ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
