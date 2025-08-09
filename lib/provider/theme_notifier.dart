import 'package:flutter/material.dart';
import '../theme/theme.dart';

class ThemeNotifier extends ChangeNotifier {
  bool isDark = false;
  ThemeData get themeData => isDark ? darkTheme : lightTheme;

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }
}
