import 'package:flutter/material.dart';

// Reusable tile for displaying a chapter
class ChapterTile extends StatelessWidget {
  final int chapter;
  final VoidCallback onTap;

  const ChapterTile({
    super.key,
    required this.chapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('ቁምፊ $chapter'), // "Chapter" in Amharic
      trailing: const Icon(Icons.arrow_forward),
      onTap: onTap,
    );
  }
}