import 'dart:math'; // Added for random image
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart'; // Added for sharing journals
import 'package:screenshot/screenshot.dart'; // Added for image share
import 'package:path_provider/path_provider.dart'; // Added for temp storage
import 'dart:io'; // Added for file handling

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
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadTodayJournal();
    _loadHistory();
  }

  Future<void> _loadTodayJournal() async {
    // User requested input to reset on open.
    // We intentionally do NOT load any saved text into the controller here.
    if (mounted) {
      setState(() {
        _controller.clear(); 
      });
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
    if (_controller.text.trim().isEmpty) return;
    
    setState(() {
      _isSaving = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _dateKey(DateTime.now());
    final noteKey = 'journal_note_$dateKey';
    final taskKey = 'daily_${dateKey}_journal';

    await prefs.setString(noteKey, _controller.text.trim());
    await prefs.setBool(taskKey, true);

    await _loadHistory(); // Refresh history

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _controller.clear(); // Reset after save too as it's a "fresh" start preference
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ጆርናሉ ተቀምጧል')),
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  void _showJournalDetail(String date, String note) {
    final theme = Theme.of(context);
    // User requested images with prefix 'reading'
    final images = [
      'images/reading.jpg',
      'images/reading2.png',
      'images/reading3.jpg',
      'images/reading4.jpg',
      'images/reading5.jpg',
    ];
    final randomImage = images[Random().nextInt(images.length)];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Stack(
          children: [
            // Shared Area (Screenshot)
            Screenshot(
              controller: _screenshotController,
              child: Stack(
                children: [
                  // Background Image with Gradient Overlay
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    child: Stack(
                      children: [
                        Image.asset(
                          randomImage,
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.85,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.85,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                theme.scaffoldBackgroundColor.withOpacity(0.9),
                                theme.scaffoldBackgroundColor,
                              ],
                              stops: const [0.0, 0.4, 0.8],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content for Screenshot
                  SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 48), // Padding for modal handle and buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'መንፈሳዊ ጆርናል',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                date,
                                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                note,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontFamily: 'Selam',
                                  fontSize: 18,
                                  height: 1.8,
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Watermark for share
                              Row(
                                children: [
                                  Icon(LucideIcons.bookOpen, size: 14, color: theme.colorScheme.primary.withOpacity(0.5)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'አማርኛ መጽሐፍ ቅዱስ ጓደኛ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                                      fontFamily: 'Loga',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Non-screenshot buttons (X and Share stay top right as UI, not in share image)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header with Share/Close buttons (Visible UI)
            Positioned(
              top: 32,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(), // Spacer
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.share2, color: Colors.white),
                        onPressed: () => _shareJournalImage(date, note),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareJournalImage(String date, String note) async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/journal_share.png').create();
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'መንፈሳዊ ጆርናል - $date\n\nበአማርኛ መጽሐፍ ቅዱስ ጓደኛ የተላከ',
        );
      }
    } catch (e) {
      // Fallback to text share if image capture fails
      Share.share('መንፈሳዊ ጆርናል ($date):\n\n$note\n\n- በአማርኛ መጽሐፍ ቅዱስ ጓደኛ የተላከ');
    }
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
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Selam',
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'እግዚአብሔር ዛሬ ምን እያስተማረዎት እንደሆነ ይጻፉ...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Selam',
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
          child: InkWell(
            onTap: () => _showJournalDetail(dateKey, item['note'] ?? ''),
            borderRadius: BorderRadius.circular(20),
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
                      const Spacer(),
                      Icon(LucideIcons.chevronRight, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['note'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
