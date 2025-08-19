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

  bool selectionMode = false;
  final Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    db = context.read<AppDatabase>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _enterSelection(int id) {
    setState(() {
      selectionMode = true;
      selectedIds.add(id);
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
        if (selectedIds.isEmpty) selectionMode = false;
      } else {
        selectedIds.add(id);
      }
    });
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除確認'),
        content: Text('確定要刪除「$title」嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除')),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteMulti(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除確認'),
        content: Text('確定要刪除選取的 $count 本小說嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除')),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(List<Novel> novels) {
    if (!selectionMode) {
      return AppBar(
        title: const Text("LinguaNovel 書櫃"),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6_rounded),
            onPressed: () => context.read<ThemeNotifier>().toggleTheme(),
            tooltip: '主題切換',
          )
        ],
      );
    }
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() {
          selectionMode = false;
          selectedIds.clear();
        }),
      ),
      title: Text('已選取 ${selectedIds.length}'),
      actions: [
        IconButton(
          tooltip: '全選/全不選',
          icon: const Icon(Icons.select_all),
          onPressed: () {
            setState(() {
              if (selectedIds.length == novels.length) {
                selectedIds.clear();
                selectionMode = false;
              } else {
                selectedIds
                  ..clear()
                  ..addAll(novels.map((e) => e.id));
              }
            });
          },
        ),
        IconButton(
          tooltip: '刪除',
          icon: const Icon(Icons.delete),
          onPressed: () async {
            if (selectedIds.isEmpty) return;
            final ok = await _confirmDeleteMulti(context, selectedIds.length);
            if (ok == true) {
              for (final id in selectedIds) {
                await db.novelDao.deleteNovel(id);
              }
              setState(() {
                selectionMode = false;
                selectedIds.clear();
              });
            }
          }
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Novel>>(
      stream: db.novelDao.watchNovelsSorted(),
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        final loading = !snapshot.hasData;
        final novels = snapshot.data ?? const <Novel>[];

        return Scaffold(
          appBar: _buildAppBar(novels),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : hasError
                  ? Center(child: Text("讀取失敗: ${snapshot.error}"))
                  : novels.isEmpty
                      ? const Center(child: Text("目前沒有小說"))
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.70,
                          ),
                          itemCount: novels.length,
                          itemBuilder: (_, i) {
                            final novel = novels[i];
                            final selected = selectedIds.contains(novel.id);

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: NovelCard(
                                    novel: novel,
                                    onTap: () {
                                      if (selectionMode) {
                                        _toggleSelection(novel.id);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => NovelDetailPage(novel: novel, db: db)),
                                        );
                                      }
                                    },
                                    onLongPress: () => _enterSelection(novel.id),
                                  ),
                                ),
                                if (!selectionMode)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: PopupMenuButton<String>(
                                      tooltip: '',
                                      onSelected: (v) async {
                                        if (v == 'delete') {
                                          final ok = await _confirmDelete(context, novel.title);
                                          if (ok == true) {
                                            await db.novelDao.deleteNovel(novel.id);
                                          }
                                        } else if (v == 'edit') {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => AddNovelPage(original: novel)),
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('編輯')),
                                        PopupMenuItem(value: 'delete', child: Text('刪除')),
                                      ],
                                    ),
                                  ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: AnimatedScale(
                                    scale: selectionMode || selected ? 1 : 0,
                                    duration: const Duration(milliseconds: 120),
                                    child: Checkbox(
                                      value: selected,
                                      onChanged: (_) => _toggleSelection(novel.id),
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: .06),
                                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
                        ),
          floatingActionButton: (!selectionMode)
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text("新增小說"),
                  onPressed: () async {
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => AddNovelPage()),
                    );
                  },
                )
              : null,
        );
      },
    );
  }
}
