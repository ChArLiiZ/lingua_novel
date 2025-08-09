import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/theme_notifier.dart';
import 'pages/home_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LinguaNovel',
        theme: theme.themeData,
        home: const HomePage(),
      ),
    );
  }
}
