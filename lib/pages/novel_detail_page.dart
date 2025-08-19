import 'dart:async';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import 'reader_page.dart';
import 'chapter_editor_page.dart';

class NovelDetailPage extends StatelessWidget {
  final Novel novel;
  final AppDatabase db;
  const NovelDetailPage({super.key, required this.novel, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(novel.title)),
      body: StreamBuilder<List<Chapter>>(
        stream: db.chapterDao.watchChaptersByNovel(novel.id),
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
              final c = chapters[i];
              return ListTile(
                title: Text(c.title, style: const TextStyle(fontSize: 16)),
                trailing: PopupMenuButton<String>(
                  tooltip: '',
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChapterEditorPage(
                            db: db,
                            novel: novel,
                            original: c,
                          ),
                        ),
                      );
                      if (!context.mounted) return;
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('刪除章節'),
                          content: Text('確定刪除「${c.title}」嗎？'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('刪除'),
                            ),
                          ],
                        ),
                      );
                      if (!context.mounted) return;
                      if (ok == true) {
                        await db.chapterDao.deleteChapter(c.id);
                        unawaited(db.novelDao.touchLastActivity(novel.id));
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('編輯')),
                    PopupMenuItem(value: 'delete', child: Text('刪除')),
                  ],
                ),
                onTap: () {
                  unawaited(db.novelDao.touchLastActivity(novel.id));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderPage(
                        novel: novel,
                        chapterId: c.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('新增章節'),
        onPressed: () async {
          final id = await db.chapterDao.insertBlankChapter(novel.id);
          unawaited(db.novelDao.touchLastActivity(novel.id));
          final created = await db.chapterDao.getChapterById(id);
          if (created == null) return;
          if (!context.mounted) return; 
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChapterEditorPage(
                db: db,
                novel: novel,
                original: created,
              ),
            ),
          );
        },
      ),
    );
  }
}
