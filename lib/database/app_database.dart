import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'tables/novels.dart';
import 'tables/chapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:logger/logger.dart';

part 'app_database.g.dart';

final logger = Logger();

@DriftDatabase(tables: [Novels, Chapters])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
  
  late final NovelDao novelDao = NovelDao(this);
  late final ChapterDao chapterDao = ChapterDao(this);
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onCreate: (m) async => m.createAll(),
  );

  }



/// ========== Novel DAO ==========
@DriftAccessor(tables: [Novels])
class NovelDao extends DatabaseAccessor<AppDatabase> with _$NovelDaoMixin {
  NovelDao(super.db);

  /// 新增小說:回傳新插入資料的 id
  Future<int> insertNovel(NovelsCompanion novel) => into(novels).insert(novel);

  /// 取得全部小說
  Future<List<Novel>> getAllNovels() => select(novels).get();

  /// 取得所有小說（依最後活動時間排序）
  Stream<List<Novel>> getNovelsSorted() {
    return (select(novels)
          ..orderBy([
            (t) => OrderingTerm(expression: t.lastActivityAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 修改小說的最後活動時間
  /// 用於紀錄最近一次閱讀或操作的時間
  Future<void> touchLastActivity(int id) async {
    await (update(novels)..where((t) => t.id.equals(id))).write(
      NovelsCompanion(lastActivityAt: Value(DateTime.now())),
    );
    logger.i('更新小說 $id 的最後活動時間');
  }

  /// 依 id 取得單一小說
  Future<Novel?> getNovelById(int id) =>
      (select(novels)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 刪除小說 + 封面檔案:回傳刪除的小說id
  Future<int> deleteNovel(int id) async {
    final novel = await getNovelById(id);

    // 如果有封面路徑就刪檔
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

    // 刪除小說
    return (delete(novels)..where((t) => t.id.equals(id))).go();
  }

  /// 更新小說：回傳影響筆數
  Future<int> updateNovel(NovelsCompanion novel) {
    assert(novel.id.present, 'updateNovel 需要提供 id（Value(id)）');
    touchLastActivity(novel.id.value);
    return (update(novels)..where((t) => t.id.equals(novel.id.value))).write(novel);
  }

  // 儲存小說封面圖片:回傳要寫入 DB 的相對路徑
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

    // 取副檔名
    final ext = p.extension(sourceImage.path).toLowerCase();
    final fileName = '$novelId$ext'; 
    final destPath = p.join(coverDir.path, fileName);

    // 覆蓋舊檔
    await sourceImage.copy(destPath);

    // 回傳相對路徑（寫進 DB）
    return p.join('covers', fileName).replaceAll('\\', '/'); // Windows 保險轉斜線
  }
}

/// ========== Chapter DAO ==========
@DriftAccessor(tables: [Chapters, Novels])
class ChapterDao extends DatabaseAccessor<AppDatabase> with _$ChapterDaoMixin {
  ChapterDao(super.db);

  /// 新增章節：回傳新插入資料的 id
  Future<int> insertChapter(ChaptersCompanion chapter) =>
      into(chapters).insert(chapter);

  /// 取得某本小說的所有章節（依 order 排序）
  Future<List<Chapter>> getChaptersByNovel(int novelId) =>
      (select(chapters)
            ..where((t) => t.novelId.equals(novelId))
            ..orderBy([(c) => OrderingTerm(expression: c.order)]))
          .get();

  /// 依 id 取得單一章節
  Future<Chapter?> getChapterById(int id) =>
      (select(chapters)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 刪除章節
  Future<int> deleteChapter(int id) =>
      (delete(chapters)..where((t) => t.id.equals(id))).go();


  Future<int> updateChapter(ChaptersCompanion chapter) {
    assert(chapter.id.present, 'updateChapter 需要提供 id（Value(id)）');
    return (update(chapters)..where((t) => t.id.equals(chapter.id.value))).write(chapter);
  }
}

/// DB 初始化
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFolder = Directory(p.join(dir.path, 'lingua_novel'));

    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }

    final file = File(p.join(dbFolder.path, 'lingua_novel.sqlite'));
    logger.i('DB Path: ${file.path}');
    return NativeDatabase(file);
  });
}
