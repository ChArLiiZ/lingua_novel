import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_notifier.dart';
import '../database/app_database.dart';
import '../widgets/novel_card.dart';
import 'novel_detail_page.dart';
import 'add_novel_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AppDatabase db;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
  }

  @override
  void dispose() {
    db.close(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LinguaNovel 書櫃"),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6_rounded),
            onPressed: () => context.read<ThemeNotifier>().toggleTheme(),
            tooltip: '主題切換',
          )
        ],
      ),
      body: FutureBuilder<List<Novel>>(
      future: db.novelDao.getAllNovels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("讀取失敗: ${snapshot.error}"));
        }
        final novels = snapshot.data ?? const <Novel>[];
        if (novels.isEmpty) {
          return const Center(child: Text("目前沒有小說"));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260, 
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.70,  // 卡片比例
          ),
          itemCount: novels.length,
          itemBuilder: (_, i) {
            final novel = novels[i];
            return NovelCard(
              novel: novel,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NovelDetailPage(novel: novel, db: db),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("新增小說"),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => AddNovelPage(db: db)),
          );
          if (created == true) {
            setState(() {}); // 你目前用 FutureBuilder，手動刷新一次
            // 若改用 StreamBuilder（watchAllNovels），這行就可以省略
          }
        },
      ),
    );
  }
}
