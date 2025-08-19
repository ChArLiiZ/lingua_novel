import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../theme/theme.dart';

class ThemeNotifier extends ChangeNotifier {
  final AppDatabase db;
  bool isDark = false;

  ThemeNotifier(this.db);

  ThemeData get themeData => isDark ? darkTheme : lightTheme;

  Future<void> loadTheme() async {
    final v = await db.settingsDao.getValue('themeMode');
    isDark = (v == 'dark');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDark = !isDark;
    await db.settingsDao.setValue('themeMode', isDark ? 'dark' : 'light');
    notifyListeners();
  }
}
