import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/chapters.dart';
import '../tables/novels.dart';

part 'chapter_dao.g.dart';

@DriftAccessor(tables: [Chapters, Novels])
class ChapterDao extends DatabaseAccessor<AppDatabase> with _$ChapterDaoMixin {
  ChapterDao(super.db);

  Stream<List<Chapter>> watchChaptersByNovel(int novelId) {
    return (select(chapters)
          ..where((t) => t.novelId.equals(novelId))
          ..orderBy([(c) => OrderingTerm(expression: c.sortIndex)]))
        .watch();
  }

  Future<Chapter?> getChapterById(int id) =>
      (select(chapters)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Chapter?> watchChapterById(int id) =>
      (select(chapters)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> nextSortIndex(int novelId) async {
    final last = await (select(chapters)
          ..where((t) => t.novelId.equals(novelId))
          ..orderBy([(c) => OrderingTerm(expression: c.sortIndex, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
    return (last?.sortIndex ?? -1) + 1;
  }

  Future<int> insertBlankChapter(int novelId) async {
    final idx = await nextSortIndex(novelId);
    return into(chapters).insert(
      ChaptersCompanion.insert(
        novelId: novelId,
        title: '未命名章節',
        content: '',
        sortIndex: idx,
      ),
    );
  }

  Future<int> insertChapter(ChaptersCompanion chapter) =>
      into(chapters).insert(chapter);

  Future<int> updateChapter(ChaptersCompanion chapter) {
    assert(chapter.id.present, 'updateChapter 需要提供 id（Value(id)）');
    final write = chapter.copyWith(updatedAt: Value(DateTime.now()));
    return (update(chapters)..where((t) => t.id.equals(chapter.id.value))).write(write);
  }

  Future<int> deleteChapter(int id) =>
      (delete(chapters)..where((t) => t.id.equals(id))).go();
}
