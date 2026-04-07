import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/book.dart';
import '../services/bible_service.dart';
import '../widgets/app_loading.dart';
import 'chapters_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final BibleService _bibleService = BibleService();
  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final books = await _bibleService.getBooks();
      if (!mounted) return;
      setState(() {
        _allBooks = books;
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'መጽሐፍትን መጫን አልተቻለም።';
        _isLoading = false;
      });
    }
  }

  void _filterBooks(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredBooks = _allBooks;
      } else {
        _filteredBooks = _allBooks
            .where((book) =>
                book.title.toLowerCase().contains(query.toLowerCase()) ||
                book.abbv.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Split filtered books by testament
    final oldTestamentBooks = _filteredBooks.where((book) => _allBooks.indexOf(book) < 39).toList();
    final newTestamentBooks = _filteredBooks.where((book) => _allBooks.indexOf(book) >= 39).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('መጻሕፍት', style: theme.textTheme.displaySmall?.copyWith(fontSize: 24)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _loadBooks,
              icon: Icon(LucideIcons.refreshCw, color: theme.colorScheme.primary, size: 20),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                onChanged: _filterBooks,
                decoration: InputDecoration(
                  hintText: 'መጽሐፍ ይፈልጉ...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
            if (!_isLoading && _error == null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary,
                  ),
                  labelColor: theme.colorScheme.onPrimary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'ብሉይ ኪዳን'),
                    Tab(text: 'ሐዲስ ኪዳን'),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: AppLoading())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : TabBarView(
                          children: [
                            _buildBookList(oldTestamentBooks, theme, isOldTestament: true),
                            _buildBookList(newTestamentBooks, theme, isOldTestament: false),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(List<Book> books, ThemeData theme, {required bool isOldTestament}) {
    if (books.isEmpty) {
      return const Center(child: Text('ምንም መጽሐፍ አልተገኘም'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.05),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isOldTestament 
                  ? const Color(0xFFB69B60) 
                  : theme.colorScheme.primary).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOldTestament ? LucideIcons.book : LucideIcons.bookOpen,
                color: isOldTestament ? const Color(0xFFB69B60) : theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              book.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            subtitle: Text(
              '${book.chapters} ምዕራፎች • ${isOldTestament ? "ብሉይ ኪዳን" : "ሐዲስ ኪዳን"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            trailing: Icon(
              LucideIcons.chevronRight,
              color: theme.colorScheme.primary.withOpacity(0.5),
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChaptersScreen(
                    bookTitle: book.title,
                    bookAbbv: book.abbv,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

