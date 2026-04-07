import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/search_result.dart';
import '../services/bible_service.dart';
import '../widgets/app_loading.dart';
import '../utils/theme_provider.dart';
import 'spiritual_journal_screen.dart';
import 'verses_screen.dart';
import 'devotional_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final BibleService _bibleService = BibleService();
  
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _todayVerse;
  
  bool _journalDone = false;
  bool _verseDone = false;
  bool _devotionalDone = false;
  bool _prayerDone = false;
  int _streakDays = 0;
  List<double> _weekRatios = List<double>.filled(7, 0);
  List<DateTime> _weekDates = List<DateTime>.filled(7, DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final verse = await _bibleService.getRandomVerse();
      await _loadDailyState();

      if (!mounted) return;
      setState(() {
        _todayVerse = verse;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'ዕቅዱን መጫን አልተቻለም።';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDailyState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = _dateKey(now);

    _journalDone = prefs.getBool('daily_${todayKey}_journal') ?? false;
    _verseDone = prefs.getBool('daily_${todayKey}_verse') ?? false;
    _devotionalDone = prefs.getBool('daily_${todayKey}_devotional') ?? false;
    _prayerDone = prefs.getBool('daily_${todayKey}_prayer') ?? false;

    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekDates = List<DateTime>.generate(7, (index) => monday.add(Duration(days: index)));
    _weekRatios = _weekDates.map((day) {
      final key = _dateKey(day);
      return _taskCompletionRatio(
        prefs.getBool('daily_${key}_journal') ?? false,
        prefs.getBool('daily_${key}_verse') ?? false,
        prefs.getBool('daily_${key}_devotional') ?? false,
        prefs.getBool('daily_${key}_prayer') ?? false,
      );
    }).toList();

    _streakDays = _calculateStreak(prefs, now);
  }

  int _calculateStreak(SharedPreferences prefs, DateTime now) {
    var streak = 0;
    for (var offset = 0; offset < 365; offset++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: offset));
      final key = _dateKey(day);
      final ratio = _taskCompletionRatio(
        prefs.getBool('daily_${key}_journal') ?? false,
        prefs.getBool('daily_${key}_verse') ?? false,
        prefs.getBool('daily_${key}_devotional') ?? false,
        prefs.getBool('daily_${key}_prayer') ?? false,
      );
      if (ratio >= 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  double _taskCompletionRatio(bool journal, bool verse, bool devotional, bool prayer) {
    final done = (journal ? 1 : 0) + (verse ? 1 : 0) + (devotional ? 1 : 0) + (prayer ? 1 : 0);
    return done / 4;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int get _completedTaskCount =>
      (_journalDone ? 1 : 0) + (_verseDone ? 1 : 0) + (_devotionalDone ? 1 : 0) + (_prayerDone ? 1 : 0);
  double get _todayProgress => _completedTaskCount / 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('የዕለት ዕቅድ', style: theme.textTheme.displaySmall?.copyWith(fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Icon(LucideIcons.flame, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 4),
                Text('$_streakDays', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoading())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    _ProgressHeader(progress: _todayProgress, count: _completedTaskCount),
                    const SizedBox(height: 30),
                    _WeekProgressDots(dates: _weekDates, ratios: _weekRatios),
                    const SizedBox(height: 30),
                    Text(
                      'የዛሬ ተግባራት',
                      style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 15),
                    _TaskTile(
                      title: 'የዕለቱ ጥቅስ',
                      subtitle: 'የዛሬውን ቃል ያንብቡ',
                      isDone: _verseDone,
                      icon: LucideIcons.bookOpen,
                      onTap: () {
                        if (_todayVerse != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VersesScreen(
                                bookTitle: _todayVerse!['book'],
                                bookAbbv: _todayVerse!['abbv'],
                                chapter: _todayVerse!['chapter'],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _TaskTile(
                      title: 'መንፈሳዊ ጆርናል',
                      subtitle: 'ሀሳብዎን ያካፍሉ',
                      isDone: _journalDone,
                      icon: LucideIcons.penTool,
                      onTap: () async {
                        final ref = _todayVerse != null
                            ? '${_todayVerse!['book']} ${_todayVerse!['chapter']}:${_todayVerse!['verse']}'
                            : 'የዕለቱ ቃል';
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SpiritualJournalScreen(verseReference: ref)),
                        );
                        if (result == true) {
                          _loadDailyState();
                        }
                      },
                    ),
                    _TaskTile(
                      title: 'ጸሎት',
                      subtitle: 'ለጥቂት ደቂቃዎች ይጸልዩ',
                      isDone: _prayerDone,
                      icon: LucideIcons.heart,
                      onTap: () {},
                    ),
                  ],
                ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final double progress;
  final int count;

  const _ProgressHeader({required this.progress, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'የዛሬ ሂደት',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count ከ 4 ተግባራት',
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekProgressDots extends StatelessWidget {
  final List<DateTime> dates;
  final List<double> ratios;

  const _WeekProgressDots({required this.dates, required this.ratios});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['ሰ', 'ማ', 'ረ', 'ሐ', 'ዓ', 'ቅ', 'እ'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isToday = DateTime.now().day == dates[index].day && DateTime.now().month == dates[index].month;
        final isDone = ratios[index] >= 1;

        return Column(
          children: [
            Text(
              days[index],
              style: TextStyle(
                fontSize: 12,
                color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? theme.colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: isDone ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: isDone
                  ? const Icon(LucideIcons.check, color: Colors.black, size: 16)
                  : Text(
                      '${dates[index].day}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final IconData icon;
  final VoidCallback onTap;

  const _TaskTile({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
        trailing: Icon(
          isDone ? LucideIcons.checkCircle : LucideIcons.circle,
          color: isDone ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
    );
  }
}
