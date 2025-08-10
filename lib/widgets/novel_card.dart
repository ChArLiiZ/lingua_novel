import 'dart:io';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class NovelCard extends StatelessWidget {
  final Novel novel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NovelCard({super.key, required this.novel, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    
    Widget cover = _placeholder();

    if ((novel.coverPath ?? '').isNotEmpty) {
      cover = FutureBuilder<String>(
        future: _getAbsoluteCoverPath(novel.coverPath!),
        builder: (context, snapshot) {
          if (snapshot.hasData && File(snapshot.data!).existsSync()) {
            return ClipRect(
              child: Align(
                alignment: Alignment.center,
                child: Image.file(
                  File(snapshot.data!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            );
          }
          return _placeholder();
        },
      );
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上半部封面
            Expanded(child: cover),

            // 下半部文字
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (novel.author.isEmpty) ? '未知' : novel.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<String> _getAbsoluteCoverPath(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'lingua_novel', relativePath);
  }

  static Widget _placeholder() {
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_outlined, size: 48),
    );
  }
}
