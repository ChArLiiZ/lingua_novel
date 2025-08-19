import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import 'package:flutter/services.dart';

class ChapterEditorPage extends StatefulWidget {
  final AppDatabase db;
  final Novel novel;
  final Chapter original;
  const ChapterEditorPage({
    super.key,
    required this.db,
    required this.novel,
    required this.original,
  });

  @override
  State<ChapterEditorPage> createState() => _ChapterEditorPageState();
}

class _ChapterEditorPageState extends State<ChapterEditorPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  Timer? _debounce;
  bool _saving = false;
  String? _status; // 例如：已自動儲存 12:34:56 / 儲存失敗…

  String _lastSavedTitle = '';
  String _lastSavedContent = '';

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.original.title;
    _contentCtrl.text = widget.original.content;
    _lastSavedTitle = widget.original.title;
    _lastSavedContent = widget.original.content;
    _titleCtrl.addListener(_onChanged);
    _contentCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _save(auto: true);
    });
    setState(() {
      _status = '有未儲存的變更';
    });
  }

  bool get _hasChanges =>
      _titleCtrl.text != _lastSavedTitle || _contentCtrl.text != _lastSavedContent;

  Future<void> _save({bool auto = false}) async {
    if (!_hasChanges) {
      if (!auto) {
        setState(() => _status = '無變更');
      }
      return;
    }
    if (_saving) return;

    final title = _titleCtrl.text.trim().isEmpty ? '未命名章節' : _titleCtrl.text.trim();
    final content = _contentCtrl.text;

    if (!auto) setState(() => _saving = true);
    try {
      await widget.db.chapterDao.updateChapter(
        ChaptersCompanion(
          id: Value(widget.original.id),
          title: Value(title),
          content: Value(content),
        ),
      );
      unawaited(widget.db.novelDao.touchLastActivity(widget.novel.id));

      _lastSavedTitle = title;
      _lastSavedContent = content;

      final now = TimeOfDay.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      setState(() {
        _status = '已自動儲存 $hh:$mm';
      });
      if (!auto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已儲存')),
        );
      }
    } catch (e) {
      setState(() => _status = '儲存失敗：$e');
      if (!auto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗：$e')),
        );
      }
    } finally {
      if (!auto && mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _onWillPop() async {
    _debounce?.cancel();
    await _save(auto: true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(onInvoke: (e) => _save(auto: false)),
        },
        child: Focus(
          autofocus: true,
          child: WillPopScope(
            onWillPop: _onWillPop,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('編輯章節'),
                actions: [
                  if (_status != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: Text(
                          _status!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: _saving ? null : () => _save(auto: false),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('儲存'),
                  ),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: '章節標題',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TextField(
                            controller: _contentCtrl,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              labelText: '內容',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
