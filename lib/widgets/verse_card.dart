import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/theme_provider.dart';

class VerseCard extends StatefulWidget {
  final String reference;
  final String text;
  final String? highlightKeyword;
  final bool isBookmarked;
  final Function(bool) onBookmarkToggle;
  final bool showActions;
  final bool isReadingMode;

  const VerseCard({
    super.key,
    required this.reference,
    required this.text,
    this.highlightKeyword,
    this.isBookmarked = false,
    required this.onBookmarkToggle,
    this.showActions = true,
    this.isReadingMode = false,
  });

  @override
  State<VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<VerseCard> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareVerseImage() async {
    setState(() => _isSharing = true);
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/verse_share_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: '${widget.reference}\nAmharic Bible Companion',
        );
      }
    } catch (e) {
      debugPrint('Error sharing image: $e');
      // Fallback to text share
      Share.share('${widget.reference}\n${widget.text}');
    } finally {
      setState(() => _isSharing = false);
    }
  }

  void _showVerseBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF141311), // Very dark warm gray
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.reference,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'images/bk${math.Random().nextInt(6) + 1}.jpg',
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5),
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.5),
                                    ],
                                    radius: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1816),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.text,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Selam',
                              fontSize: themeProvider.fontSize,
                              height: 1.6,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -15,
                    right: 20,
                    child: FloatingActionButton.small(
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: Colors.redAccent,
                      elevation: 4,
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontSize = themeProvider.fontSize;

    final cardContent = GestureDetector(
      onTap: () => _showVerseBottomSheet(context),
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: _isSharing ? 0 : (widget.isReadingMode ? 0 : 8), 
          horizontal: _isSharing ? 0 : (widget.isReadingMode ? 0 : 20)
        ),
      decoration: BoxDecoration(
        color: _isSharing ? theme.colorScheme.surface : (widget.isReadingMode ? Colors.transparent : theme.colorScheme.surface),
        borderRadius: BorderRadius.circular(widget.isReadingMode ? 0 : 18),
        border: widget.isReadingMode 
          ? Border(bottom: BorderSide(color: theme.colorScheme.primary.withOpacity(0.05)))
          : Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
        boxShadow: (_isSharing || widget.isReadingMode) ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Wrap content so screenshot is tight
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.reference,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.showActions && !_isSharing) ...[
                  IconButton(
                    icon: Icon(
                      widget.isBookmarked ? LucideIcons.bookmark : LucideIcons.bookmark,
                      size: 20,
                      color: widget.isBookmarked 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    onPressed: () => widget.onBookmarkToggle(!widget.isBookmarked),
                    visualDensity: VisualDensity.compact,
                  ),
                  _isSharing 
                    ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(
                        icon: Icon(
                          LucideIcons.share2,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        onPressed: _shareVerseImage,
                        visualDensity: VisualDensity.compact,
                      ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'Selam',
                fontSize: fontSize,
                height: 1.6,
                color: theme.colorScheme.onSurface.withOpacity(0.9),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    ));

    return Screenshot(
      controller: _screenshotController,
      child: cardContent,
    );
  }
}