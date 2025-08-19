import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import 'chapter_editor_page.dart';

class ReaderPage extends StatefulWidget {
  final Novel novel;
  final int chapterId;
  const ReaderPage({super.key, required this.novel, required this.chapterId});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  bool showTranslation = true; 

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();

    return StreamBuilder<Chapter?>(
      stream: db.chapterDao.watchChapterById(widget.chapterId),
      builder: (context, snapshot) {
        final chapter = snapshot.data;

        if (chapter == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(chapter.title),
            actions: [
              IconButton(
                tooltip: "切換原文/翻譯",
                icon: const Icon(Icons.translate),
                onPressed: () {
                  setState(() {
                    showTranslation = !showTranslation;
                  });
                },
              ),
              IconButton(
                tooltip: "翻譯本章節",
                icon: const Icon(Icons.bolt), 
                onPressed: () {
                  // TODO: 呼叫翻譯功能
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("翻譯功能尚未實作")),
                  );
                },
              ),
              IconButton(
                tooltip: "編輯章節",
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChapterEditorPage(
                        db: db,
                        novel: widget.novel,
                        original: chapter,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showTranslation ? "翻譯" : "原文",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      showTranslation
                          ? (chapter.translatedContent ?? "（尚未翻譯）")
                          : chapter.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
