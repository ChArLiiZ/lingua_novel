import 'package:drift/drift.dart';
import 'novels.dart';

class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get novelId => integer().references(Novels, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get content => text()();                           // 原文
  TextColumn get translatedContent => text().nullable()();      // 翻譯後的內容
  IntColumn get sortIndex => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
