import 'package:flutter/material.dart';

// Reusable tile for displaying a book
class BookTile extends StatelessWidget {
  final String title;
  final String abbv;
  final VoidCallback onTap;

  const BookTile({
    super.key,
    required this.title,
    required this.abbv,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(abbv),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onTap,
    );
  }
}