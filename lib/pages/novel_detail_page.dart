import 'package:flutter/material.dart';
import '../database/app_database.dart';
import 'reader_page.dart';

class NovelDetailPage extends StatelessWidget {
  final Novel novel; 
  final AppDatabase db;
  const NovelDetailPage({super.key, required this.novel, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(novel.title)),
      body: FutureBuilder<List<Chapter>>(
        future: db.chapterDao.getChaptersByNovel(novel.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chapters = snapshot.data!;
          if (chapters.isEmpty) {
            return const Center(child: Text("本書還沒有章節"));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: chapters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final chapter = chapters[i];
              return ListTile(
                title: Text(chapter.title, style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.menu_book_outlined),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderPage(
                        novel: novel,
                        chapter: chapter,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
