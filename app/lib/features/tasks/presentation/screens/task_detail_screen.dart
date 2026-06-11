import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:todo_app/core/network/file_url.dart';
import 'package:todo_app/core/network/multipart_util.dart';
import 'package:todo_app/features/tasks/data/models/attachment.dart';
import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/data/task_repository.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';
import 'package:todo_app/features/tasks/presentation/widgets/audio_section.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  void _refresh(WidgetRef ref) {
    ref.invalidate(taskDetailProvider(taskId));
    ref.invalidate(tasksControllerProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));
    final repo = ref.read(taskRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          taskAsync.maybeWhen(
            data: (task) => IconButton(
              icon: Icon(
                task.important ? Icons.star : Icons.star_border,
                color: task.important ? Colors.amber : null,
              ),
              tooltip: '标记重要',
              onPressed: () async {
                await repo.setImportant(task.id, !task.important);
                _refresh(ref);
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          taskAsync.maybeWhen(
            data: (task) => IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: () async {
                await repo.deleteTask(task.id);
                _refresh(ref);
                if (context.mounted) context.go('/');
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: taskAsync.when(
        data: (task) => _TaskDetailBody(
          task: task,
          onChanged: () => _refresh(ref),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

class _TaskDetailBody extends ConsumerStatefulWidget {
  const _TaskDetailBody({required this.task, required this.onChanged});

  final Task task;
  final VoidCallback onChanged;

  @override
  ConsumerState<_TaskDetailBody> createState() => _TaskDetailBodyState();
}

class _TaskDetailBodyState extends ConsumerState<_TaskDetailBody> {
  late final TextEditingController _title =
      TextEditingController(text: widget.task.title);
  late final TextEditingController _note =
      TextEditingController(text: widget.task.note ?? '');
  final _stepController = TextEditingController();
  bool _uploadingImage = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _stepController.dispose();
    super.dispose();
  }

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  void _showImageSourceSheet() {
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
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 2000);
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      await _repo.uploadAttachment(
        widget.task.id,
        xFile: picked,
        contentType: guessImageMediaType(picked.mimeType, picked.name),
      );
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('图片上传失败')));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _deleteAttachment(Attachment a) async {
    await _repo.deleteAttachment(a.id);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Checkbox(
              value: task.completed,
              onChanged: (v) async {
                await _repo.toggleComplete(task.id, v ?? false);
                widget.onChanged();
              },
            ),
            const Text('已完成'),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: '标题'),
          onSubmitted: (v) async {
            await _repo.updateTask(task.id, title: v.trim());
            widget.onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '备注',
            alignLabelWithHint: true,
          ),
          onSubmitted: (v) async {
            await _repo.updateTask(task.id, note: v);
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('保存标题/备注'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _repo.updateTask(
                task.id,
                title: _title.text.trim(),
                note: _note.text,
              );
              widget.onChanged();
              messenger.showSnackBar(const SnackBar(content: Text('已保存')));
            },
          ),
        ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('图片', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: '添加图片',
              onPressed: _uploadingImage ? null : _showImageSourceSheet,
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
        AudioSection(task: task, onChanged: widget.onChanged),
        const Divider(height: 32),
        Text('步骤', style: Theme.of(context).textTheme.titleMedium),
        ...task.steps.map(
          (s) => ListTile(
            dense: true,
            leading: Icon(
              s.completed
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 20,
            ),
            title: Text(s.title),
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
                widget.onChanged();
              },
            ),
          ],
        ),
      ],
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
