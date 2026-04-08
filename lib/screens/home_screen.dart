import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/bible_service.dart';
import '../widgets/app_loading.dart';
import 'spiritual_journal_screen.dart';
import 'search_screen.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math' as math; // Added for random image

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BibleService _bibleService = BibleService();
  Map<String, dynamic>? _verseData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRandomVerse();
  }

  Future<void> _loadRandomVerse() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _bibleService.getRandomVerse();
      if (!mounted) return;
      setState(() {
        _verseData = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load verse. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'የዕለቱ ቃል',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 22,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'images/hm1.jpg',
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.scaffoldBackgroundColor.withOpacity(0.8),
                          theme.scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: _isLoading 
                  ? const Center(child: AppLoading())
                  : _error != null
                    ? _ErrorCard(message: _error!, onRetry: _loadRandomVerse)
                    : _VerseCard(verseData: _verseData!),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ተጨማሪ ይዘቶች',
                    style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _FeatureCard(
                          title: 'መንፈሳዊ ጆርናል',
                          subtitle: 'የእለት ተእለት ጸሎትና ትዝታዎችን ይመዝግቡ',
                          icon: LucideIcons.penTool,
                          image: 'images/hm3.jpg',
                          onTap: () {
                            final ref = _verseData != null
                                ? '${_verseData!['book']} ${_verseData!['chapter']}:${_verseData!['verse']}'
                                : 'የዕለቱ ቃል';
                            Navigator.push(context, MaterialPageRoute(builder: (context) => SpiritualJournalScreen(verseReference: ref)));
                          },
                        ),
                        const SizedBox(width: 15),
                        _FeatureCard(
                          title: 'የንባብ እቅድ',
                          subtitle: 'መጽሐፍ ቅዱስን በሥርዓት ያንብቡ',
                          icon: LucideIcons.calendar,
                          image: 'images/hm4.jpg',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
                          },
                        ),
                        const SizedBox(width: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
        ],
      ),
    );
  }
}

class _VerseCard extends StatefulWidget {
  final Map<String, dynamic> verseData;

  const _VerseCard({required this.verseData});

  @override
  State<_VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<_VerseCard> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;
  late String _currentBkImage;

  @override
  void initState() {
    super.initState();
    _currentBkImage = [
      'images/bk1.jpg',
      'images/bk2.png',
      'images/bk3.jpg',
      'images/bk4.jpg',
      'images/bk5.jpg',
      'images/bk6.jpg',
    ][math.Random().nextInt(6)];
  }

  Future<void> _shareVerseImage() async {
    setState(() => _isSharing = true);
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/home_share_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await imagePath.writeAsBytes(image);

        final reference = '${widget.verseData['book']} ${widget.verseData['chapter']}:${widget.verseData['verse']}';
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: '$reference\nAmharic Bible Companion',
        );
      }
    } catch (e) {
      debugPrint('Error sharing image: $e');
      final reference = '${widget.verseData['book']} ${widget.verseData['chapter']}:${widget.verseData['verse']}';
      Share.share('$reference\n${widget.verseData['text']}');
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = '${widget.verseData['book']} ${widget.verseData['chapter']}:${widget.verseData['verse']}';

    return Screenshot(
      controller: _screenshotController,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isSharing ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Background Art
              Positioned.fill(
                child: Image.asset(
                  _currentBkImage,
                  fit: BoxFit.cover,
                ),
              ),

              // 2. Gradient Overlay (Subtle, no blur)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.surface.withOpacity(0.3),
                        theme.colorScheme.surface.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Icon(LucideIcons.quote, color: theme.colorScheme.primary, size: 16),
                        ),
                        const Spacer(),
                        if (!_isSharing) ...[
                          GestureDetector(
                            onTap: _shareVerseImage,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                              ),
                              child: Icon(LucideIcons.share2, size: 18, color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.verseData['text'],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Selam',
                        fontSize: 24,
                        height: 1.6,
                        color: theme.colorScheme.primary,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: Text(
                          reference,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String image;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 120,
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.darken,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onRetry, child: const Text('እንደገና ይሞክሩ')),
        ],
      ),
    );
  }
}
