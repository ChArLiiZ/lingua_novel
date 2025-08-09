import 'package:flutter/material.dart';
import '../database/app_database.dart';

class ReaderPage extends StatelessWidget {
  final Novel novel;
  final Chapter chapter;
  const ReaderPage({super.key, required this.novel, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final String originalText = chapter.content;
    const String translatedText = "（AI 翻譯內容）";

    return Scaffold(
      appBar: AppBar(
        title: Text(chapter.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("原文", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(originalText, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text("翻譯", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(translatedText, style: const TextStyle(fontSize: 16, color: Colors.indigo)),
          ],
        ),
      ),
    );
  }
}
