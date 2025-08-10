import 'package:drift/drift.dart';

class Novels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastActivityAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get coverPath => text().nullable()();
}

