import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/theme_notifier.dart';
import 'pages/home_page.dart';
import 'database/app_database.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();

  final themeNotifier = ThemeNotifier(db);
  await themeNotifier.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'LinguaNovel',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const HomePage(),
        );
      },
    );
  }
}
