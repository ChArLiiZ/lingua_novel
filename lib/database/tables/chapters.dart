import 'package:drift/drift.dart';
import 'novels.dart';

class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get novelId => integer().references(Novels, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get content => text()();
  IntColumn get order => integer()();
}
