import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';

class AddNovelPage extends StatefulWidget {
  final AppDatabase db;
  const AddNovelPage({super.key, required this.db});

  @override
  State<AddNovelPage> createState() => _AddNovelPageState();
}

class _AddNovelPageState extends State<AddNovelPage> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  File? _pickedCover;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _pickedCover = File(result.files.single.path!));
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final author = _authorCtrl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入書名')));
      return;
    }

    setState(() => _saving = true);
    try {
      final novelId = await widget.db.novelDao.insertNovel(
        NovelsCompanion.insert(
          title: title,
          author: Value(author.isEmpty ? '' : author),
        ),
      );

      if (_pickedCover != null) {
        final relativePath = await widget.db.novelDao.saveCoverForNovel(
          sourceImage: _pickedCover!,
          novelId: novelId,
        );
        await widget.db.novelDao.updateNovel(
          NovelsCompanion(
            id: Value(novelId),
            coverPath: Value(relativePath),
          ),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverName = _pickedCover == null
        ? '尚未選擇'
        : _pickedCover!.path.split(Platform.pathSeparator).last;

    return Scaffold(
      appBar: AppBar(title: const Text('新增小說')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '書名 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _authorCtrl,
                  decoration: const InputDecoration(
                    labelText: '作者（可留空）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _pickCover,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('選擇封面'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        coverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('儲存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
