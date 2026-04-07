import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SpiritualJournalScreen extends StatefulWidget {
  final String verseReference;

  const SpiritualJournalScreen({
    super.key,
    required this.verseReference,
  });

  @override
  State<SpiritualJournalScreen> createState() => _SpiritualJournalScreenState();
}

class _SpiritualJournalScreenState extends State<SpiritualJournalScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadTodayJournal();
    _loadHistory();
  }

  Future<void> _loadTodayJournal() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'journal_note_${_dateKey(DateTime.now())}';
    final saved = prefs.getString(key) ?? '';
    _controller.text = saved;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('journal_note_')).toList();
    
    // Sort keys descending (newest first)
    keys.sort((a, b) => b.compareTo(a));

    final historyList = <Map<String, String>>[];
    for (var key in keys) {
      final dateStr = key.replaceFirst('journal_note_', '');
      final note = prefs.getString(key) ?? '';
      if (note.trim().isNotEmpty) {
        historyList.add({'date': dateStr, 'note': note});
      }
    }

    if (mounted) {
      setState(() {
        _history = historyList;
      });
    }
  }

  Future<void> _saveJournal() async {
    setState(() {
      _isSaving = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _dateKey(DateTime.now());
    final noteKey = 'journal_note_$dateKey';
    final taskKey = 'daily_${dateKey}_journal';

    await prefs.setString(noteKey, _controller.text.trim());
    await prefs.setBool(taskKey, _controller.text.trim().isNotEmpty);

    await _loadHistory(); // Refresh history

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ጆርናሉ ተቀምጧል')),
    );
    // Remove pop so user can see it saved and view history
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('መንፈሳዊ ጆርናል', style: theme.textTheme.displaySmall?.copyWith(fontSize: 22)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            tabs: const [
              Tab(text: 'ዛሬ'),
              Tab(text: 'ታሪክ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTodayTab(theme),
            _buildHistoryTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.anchor, color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'የዛሬው ቃላዊ መልህቅ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.verseReference,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                decoration: InputDecoration(
                  hintText: 'እግዚአብሔር ዛሬ ምን እያስተማረዎት እንደሆነ ይጻፉ...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () async {
                await _saveJournal();
                if (mounted) Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(LucideIcons.save, size: 20),
              label: Text(
                'ጆርናሉን አስቀምጥ',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    if (_history.isEmpty) {
      return Center(
        child: Text(
          'ምንም ታሪክ የለም',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final dateKey = item['date'] ?? '';

        return Dismissible(
          key: Key(dateKey),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(LucideIcons.trash2, color: Colors.redAccent),
          ),
          onDismissed: (direction) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('journal_note_$dateKey');
            await prefs.remove('daily_${dateKey}_journal');
            
            setState(() {
              _history.removeAt(index);
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ጆርኑ ተሰርዟል')),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      dateKey,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['note'] ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
