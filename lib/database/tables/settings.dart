import 'package:drift/drift.dart';

class Settings extends Table {
  TextColumn get key => text()(); // 設定名稱
  TextColumn get value => text()(); // 設定值
  @override
  Set<Column> get primaryKey => {key};
}
