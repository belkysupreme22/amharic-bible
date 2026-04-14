import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../utils/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/download_service.dart';
import '../models/book.dart';
import '../services/bible_service.dart';
import '../services/local_bible_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _reminderEnabled = false;
  
  final DownloadService _downloadService = DownloadService();
  final BibleService _bibleService = BibleService();
  List<Book> _extraBooks = [];
  Map<String, double> _downloadingProgress = {};
  Map<String, bool> _downloadedStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkExtraBooks();
  }

  Future<void> _checkExtraBooks() async {
    try {
      final allBooks = await _bibleService.getBooks();
      final extra = allBooks.where((b) => !LocalBibleService.isAssetBook(b.abbv)).toList();
      
      Map<String, bool> status = {};
      for (var b in extra) {
        status[b.abbv] = await _downloadService.isBookDownloaded(b.abbv, b.chapters);
      }

      setState(() {
        _extraBooks = extra;
        _downloadedStatus = status;
      });
    } catch (e) {
      debugPrint('Error checking extra books: $e');
    }
  }

  Future<void> _downloadBook(Book book) async {
    setState(() => _downloadingProgress[book.abbv] = 0.01);
    
    try {
      await for (double progress in _downloadService.downloadBook(book)) {
        setState(() => _downloadingProgress[book.abbv] = progress);
      }
      setState(() {
        _downloadingProgress.remove(book.abbv);
        _downloadedStatus[book.abbv] = true;
      });
      _showSnack('${book.title} ተጭኗል።');
    } catch (e) {
      setState(() => _downloadingProgress.remove(book.abbv));
      _showSnack('መጫን አልተቻለም። እባክዎ እንደገና ይሞክሩ።');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderTime = TimeOfDay(
        hour: prefs.getInt('reminder_hour') ?? 8,
        minute: prefs.getInt('reminder_minute') ?? 0,
      );
      _reminderEnabled = prefs.getBool('reminder_enabled') ?? false;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value) {
      await NotificationService().requestPermissions();
      // Assume permissions or at least the attempt was made
      await NotificationService().scheduleDailyReminder(_reminderTime);
      _showSnack('የዕለት ጥቅስ ማሳሰቢያ በርቷል');
    } else {
      await NotificationService().cancelReminder();
      _showSnack('ማሳሰቢያ ጠፍቷል');
    }

    await prefs.setBool('reminder_enabled', value);
    setState(() => _reminderEnabled = value);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: _reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', picked.hour);
    await prefs.setInt('reminder_minute', picked.minute);
    
    setState(() => _reminderTime = picked);
    if (_reminderEnabled) await NotificationService().scheduleDailyReminder(picked);
  }

  Future<void> _resetProgress() async {
    if (await _confirmAction('ሂደትን እንደገና ጀምር', 'የንባብ ሂደትን በሙሉ ማጥፋት ይፈልጋሉ?')) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('daily_')).toList();
      for (var key in keys) {
        await prefs.remove(key);
      }
      _showSnack('ሂደትዎ ተሰርዟል');
    }
  }

  Future<bool> _confirmAction(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ተመለስ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('አዎ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ቅንብሮች'), elevation: 0, backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'ገጽታ'),
          const SizedBox(height: 12),
          _ThemeSelector(),
          const SizedBox(height: 25),
          _SectionHeader(title: 'የንባብ ቅንብሮች'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('የፊደል መጠን', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(themeProvider.fontSize.toInt().toString(), style: TextStyle(color: theme.colorScheme.primary)),
                  ],
                ),
                Slider(
                  value: themeProvider.fontSize,
                  min: 14, max: 32, divisions: 18,
                  activeColor: theme.colorScheme.primary,
                  onChanged: themeProvider.setFontSize,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _SectionHeader(title: 'ማሳሰቢያ'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _reminderEnabled,
                  onChanged: _toggleReminder,
                  activeColor: theme.colorScheme.primary,
                  title: const Text('የዕለት ጥቅስ ማሳሰቢያ'),
                  secondary: Icon(LucideIcons.bell, color: _reminderEnabled ? theme.colorScheme.primary : Colors.grey),
                ),
                if (_reminderEnabled) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('የማሳሰቢያ ሰዓት'),
                    trailing: Text(_reminderTime.format(context), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    onTap: _pickReminderTime,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 25),
          _SectionHeader(title: 'ከመስመር ውጭ (Offline)'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(LucideIcons.hardDrive, color: Colors.green),
                  title: Text('መሠረታዊ 66 መጻሕፍት', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ከመተግበሪያው ጋር የተካተቱ (Built-in)'),
                  trailing: Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
                ),
                if (_extraBooks.isNotEmpty) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('ተጨማሪ መጻሕፍት', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  ..._extraBooks.map((book) {
                    final isDownloading = _downloadingProgress.containsKey(book.abbv);
                    final isDownloaded = _downloadedStatus[book.abbv] ?? false;
                    
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(book.title),
                          subtitle: Text('${book.chapters} ምዕራፎች'),
                          trailing: isDownloading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value: _downloadingProgress[book.abbv],
                                    strokeWidth: 3,
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    isDownloaded ? LucideIcons.trash2 : LucideIcons.downloadCloud,
                                    color: isDownloaded ? Colors.redAccent : theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    if (isDownloaded) {
                                      _downloadService.removeDownloadedBook(book.abbv);
                                      setState(() => _downloadedStatus[book.abbv] = false);
                                    } else {
                                      _downloadBook(book);
                                    }
                                  },
                                ),
                        ),
                        if (isDownloading)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: LinearProgressIndicator(
                              value: _downloadingProgress[book.abbv],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 25),
          _SectionHeader(title: 'ተጨማሪ'),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _ActionTile(
                  icon: LucideIcons.rotateCcw,
                  title: 'ሂደትን እንደገና ጀምር',
                  onTap: _resetProgress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: AppThemeVariant.values.map((variant) {
          final isSelected = themeProvider.variant == variant;
          
          Color bgColor;
          Color primaryColor;

          switch (variant) {
            case AppThemeVariant.midnightGold: 
              bgColor = const Color(0xFF100F0D); 
              primaryColor = const Color(0xFFFFC453);
              break;
            case AppThemeVariant.royalNavy: 
              bgColor = const Color(0xFF0B101A); 
              primaryColor = const Color(0xFFFFD166);
              break;
            case AppThemeVariant.deepOnyx: 
              bgColor = const Color(0xFF0D0D0D); 
              primaryColor = const Color(0xFFE5B96E);
              break;
            case AppThemeVariant.deepBurgundy: 
              bgColor = const Color(0xFF1A0D0D); 
              primaryColor = const Color(0xFFD4AF37);
              break;
          }

          return GestureDetector(
            onTap: () => themeProvider.setThemeVariant(variant),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 140,
              height: 90,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.white12,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
                ] : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox.shrink(),
                            if (isSelected)
                              Icon(LucideIcons.checkCircle2, color: primaryColor, size: 18),
                          ],
                        ),
                        // Removed theme name text for a cleaner UI
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: Colors.redAccent.withOpacity(0.7)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
    );
  }
}
