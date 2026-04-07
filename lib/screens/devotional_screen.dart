import 'package:flutter/material.dart';

import '../models/search_result.dart';

class DevotionalScreen extends StatefulWidget {
  final Map<String, dynamic> verse;
  final List<SearchResult> highlights;

  const DevotionalScreen({
    super.key,
    required this.verse,
    required this.highlights,
  });

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101010) : const Color(0xFFF6F1E4);
    final card = isDark ? Colors.white.withOpacity(0.07) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);
    final primary = isDark ? Colors.white : const Color(0xFF222222);
    final secondary = isDark ? Colors.white70 : const Color(0xFF645F56);

    final reference = '${widget.verse['book']} ${widget.verse['chapter']}:${widget.verse['verse']}';
    final verseText = widget.verse['text'].toString();
    final themeWords = widget.highlights.map((e) => e.abbv).where((e) => e.isNotEmpty).take(3).join(', ');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primary,
        title: const Text('Personalized Devotional'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _sectionCard(
                    cardColor: card,
                    borderColor: border,
                    titleColor: secondary,
                    bodyColor: primary,
                    title: 'Anchor Verse',
                    body: '$reference\n\n$verseText',
                  ),
                  const SizedBox(height: 10),
                  _sectionCard(
                    cardColor: card,
                    borderColor: border,
                    titleColor: secondary,
                    bodyColor: primary,
                    title: 'Theme',
                    body: themeWords.isEmpty ? 'Patience, trust, and surrender.' : themeWords,
                  ),
                  const SizedBox(height: 10),
                  _sectionCard(
                    cardColor: card,
                    borderColor: border,
                    titleColor: secondary,
                    bodyColor: primary,
                    title: 'Reflection',
                    body: 'Where do you need to trust God\'s timing today? '
                        'Write one area where you will replace anxiety with prayer.',
                  ),
                  const SizedBox(height: 10),
                  _sectionCard(
                    cardColor: card,
                    borderColor: border,
                    titleColor: secondary,
                    bodyColor: primary,
                    title: 'Prayer',
                    body: 'Lord, help me to stay patient and faithful while You work in my life. '
                        'Give me peace, wisdom, and endurance today. Amen.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isCompleted = true;
                  });
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCB05),
                  foregroundColor: const Color(0xFF1A1A1A),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: Icon(_isCompleted ? Icons.check_rounded : Icons.done_all_rounded),
                label: Text(_isCompleted ? 'Completed' : 'Mark as completed'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color bodyColor,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(color: bodyColor, height: 1.45, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
