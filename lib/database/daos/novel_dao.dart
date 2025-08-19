import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_database.dart';
import '../tables/novels.dart';

part 'novel_dao.g.dart';

@DriftAccessor(tables: [Novels])
class NovelDao extends DatabaseAccessor<AppDatabase> with _$NovelDaoMixin {
  NovelDao(super.db);

  Future<int> insertNovel(NovelsCompanion novel) => into(novels).insert(novel);

  Future<List<Novel>> getAllNovels() => select(novels).get();


  // 改成 watch 版本且名稱對應
  Stream<List<Novel>> watchNovelsSorted() {
    return (select(novels)
          ..orderBy([
            (t) => OrderingTerm(expression: t.lastActivityAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> touchLastActivity(int id) async {
    await (update(novels)..where((t) => t.id.equals(id))).write(
      NovelsCompanion(lastActivityAt: Value(DateTime.now())),
    );
    logger.i('更新小說 $id 的最後活動時間');
  }

  Future<Novel?> getNovelById(int id) =>
      (select(novels)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> deleteNovel(int id) async {
    final novel = await getNovelById(id);

    // 刪封面檔（若有）
    if (novel?.coverPath != null && novel!.coverPath!.isNotEmpty) {
      final root = await getApplicationDocumentsDirectory();
      final absPath = p.join(root.path, 'lingua_novel', novel.coverPath!);
      final coverFile = File(absPath);
      if (await coverFile.exists()) {
        try {
          await coverFile.delete();
          logger.i('封面已刪除: $absPath');
        } catch (e) {
          logger.w('刪除封面失敗: $e');
        }
      }
    }

    return (delete(novels)..where((t) => t.id.equals(id))).go();
  }


  Future<int> updateNovel(NovelsCompanion novel) {
    assert(novel.id.present, 'updateNovel 需要提供 id（Value(id)）');

    final patch = NovelsCompanion(
      id: novel.id,
      title: novel.title,
      author: novel.author,
      coverPath: novel.coverPath,
      lastActivityAt: Value(DateTime.now()),
    );

    return (update(novels)..where((t) => t.id.equals(novel.id.value))).write(patch);
  }

  Future<String> saveCoverForNovel({
    required File sourceImage,
    required int novelId,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final appDir = Directory(p.join(root.path, 'lingua_novel'));
    final coverDir = Directory(p.join(appDir.path, 'covers'));
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }

    final ext = p.extension(sourceImage.path).toLowerCase();
    final fileName = '$novelId$ext';
    final destPath = p.join(coverDir.path, fileName);

    await sourceImage.copy(destPath);

    return p.join('covers', fileName).replaceAll('\\', '/');
  }
}
