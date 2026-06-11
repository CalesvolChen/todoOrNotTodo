import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:todo_app/core/audio/completion_sound.dart';
import 'package:todo_app/core/network/file_url.dart';
import 'package:todo_app/core/network/multipart_util.dart';
import 'package:todo_app/features/tasks/data/models/attachment.dart';
import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/data/task_repository.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';
import 'package:todo_app/features/tasks/presentation/widgets/audio_section.dart';
import 'package:todo_app/shared/widgets/app_back_button.dart';
import 'package:todo_app/shared/widgets/app_snackbar.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _stepController = TextEditingController();
  bool _uploadingImage = false;
  bool _dirty = false;
  bool _saving = false;
  String? _loadedTaskId;

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  void _refresh() {
    ref.invalidate(taskDetailProvider(widget.taskId));
    ref.invalidate(tasksControllerProvider);
  }

  void _bindTask(Task task) {
    if (_dirty) return;
    final note = task.note ?? '';
    if (_loadedTaskId == task.id &&
        _title.text == task.title &&
        _note.text == note) {
      return;
    }
    _loadedTaskId = task.id;
    _title.text = task.title;
    _note.text = note;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save(Task task) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repo.updateTask(
        task.id,
        title: _title.text.trim(),
        note: _note.text,
      );
      setState(() => _dirty = false);
      _refresh();
      context.showAppSnackBar('已保存', type: AppSnackBarType.success);
    } catch (_) {
      context.showAppSnackBar('保存失败', type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _onWillPop(Task task) async {
    if (!_dirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未保存的修改'),
        content: const Text('标题或备注已修改，是否保存？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('不保存'),
          ),
          FilledButton(
            onPressed: () async {
              await _save(task);
              if (ctx.mounted) Navigator.pop(ctx, !_dirty);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));

    return taskAsync.when(
      data: (task) {
        _bindTask(task);
        return PopScope(
          canPop: !_dirty,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (await _onWillPop(task) && context.mounted) {
              safeGoBack(context);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: AppBackButton(
                onPressed: () async {
                  if (await _onWillPop(task) && context.mounted) {
                    safeGoBack(context);
                  }
                },
              ),
              title: const Text('任务详情'),
              actions: [
                if (_dirty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Center(
                      child: Text(
                        '未保存',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: _saving || !_dirty ? null : () => _save(task),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
                IconButton(
                  icon: Icon(
                    task.important ? Icons.star : Icons.star_border,
                    color: task.important ? Colors.amber : null,
                  ),
                  tooltip: '标记重要',
                  onPressed: () async {
                    await _repo.setImportant(task.id, !task.important);
                    _refresh();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                  onPressed: () async {
                    await _repo.deleteTask(task.id);
                    _refresh();
                    if (context.mounted) context.go('/');
                  },
                ),
              ],
            ),
            body: _buildBody(task),
            bottomNavigationBar: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _dirty
                  ? SafeArea(
                      key: const ValueKey('save-bar'),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: FilledButton.icon(
                          onPressed: _saving ? null : () => _save(task),
                          icon: const Icon(Icons.save_outlined),
                          label: Text(_saving ? '保存中…' : '保存修改'),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-save-bar')),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: secondaryAppBar(context, title: '任务详情'),
        body: Center(child: Text('加载失败：$e')),
      ),
    );
  }

  Widget _buildBody(Task task) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Checkbox(
              value: task.completed,
              onChanged: (v) async {
                final completed = v ?? false;
                await _repo.toggleComplete(task.id, completed);
                if (completed) {
                  unawaited(CompletionSound.play());
                }
                _refresh();
              },
            ),
            const Text('已完成'),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: '标题'),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '备注',
            alignLabelWithHint: true,
          ),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        _MetaRow(
          label: '创建时间',
          value: _formatDateTime(task.createdAt),
        ),
        if (task.completed)
          _MetaRow(
            label: '完成时间',
            value: _formatDateTime(task.completedAt),
          ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('图片', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: '添加图片',
              onPressed: _uploadingImage ? null : () => _showImageSourceSheet(task),
            ),
          ],
        ),
        if (_uploadingImage)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        if (task.images.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('暂无图片', style: TextStyle(color: Colors.grey)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: task.images
                .map((a) => _AttachmentThumb(
                      attachment: a,
                      onDelete: () => _deleteAttachment(a),
                    ))
                .toList(),
          ),
        const Divider(height: 32),
        AudioSection(task: task, onChanged: _refresh),
        const Divider(height: 32),
        Row(
          children: [
            Text('步骤', style: Theme.of(context).textTheme.titleMedium),
            if (task.steps.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                task.stepProgressLabel ?? '',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
        ),
        if (task.steps.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('暂无步骤', style: TextStyle(color: Colors.grey)),
          )
        else
          ...task.steps.asMap().entries.map(
                (entry) => CheckboxListTile(
                  value: entry.value.completed,
                  onChanged: (v) async {
                    await _repo.toggleStep(
                      task.id,
                      entry.value.id,
                      v ?? false,
                    );
                    _refresh();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('${entry.key + 1}. ${entry.value.title}'),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: '删除步骤',
                    onPressed: () async {
                      await _repo.deleteStep(task.id, entry.value.id);
                      _refresh();
                    },
                  ),
                ),
              ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stepController,
                decoration: const InputDecoration(hintText: '添加步骤'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final t = _stepController.text.trim();
                if (t.isEmpty) return;
                await _repo.addStep(task.id, t);
                _stepController.clear();
                _refresh();
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showImageSourceSheet(Task task) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(task, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(task, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(Task task, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 2000);
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      await _repo.uploadAttachment(
        task.id,
        xFile: picked,
        contentType: guessImageMediaType(picked.mimeType, picked.name),
      );
      _refresh();
    } catch (_) {
      context.showAppSnackBar('图片上传失败', type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _deleteAttachment(Attachment a) async {
    await _repo.deleteAttachment(a.id);
    _refresh();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({required this.attachment, required this.onDelete});

  final Attachment attachment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            fileUrl(attachment.path),
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 90,
              height: 90,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
