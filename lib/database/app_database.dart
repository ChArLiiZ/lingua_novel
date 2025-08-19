import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

import 'tables/novels.dart';
import 'tables/chapters.dart';
import 'tables/settings.dart';


import 'daos/novel_dao.dart';
import 'daos/chapter_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

final logger = Logger();

@DriftDatabase(
  tables: [Novels, Chapters, Settings],
  daos: [NovelDao, ChapterDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (m) async => m.createAll(),
      );
}

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
