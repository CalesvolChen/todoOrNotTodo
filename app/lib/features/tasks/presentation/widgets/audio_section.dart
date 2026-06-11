import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:todo_app/core/network/file_url.dart';
import 'package:todo_app/features/tasks/data/models/attachment.dart';
import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/data/task_repository.dart';

class AudioSection extends ConsumerStatefulWidget {
  const AudioSection({super.key, required this.task, required this.onChanged});

  final Task task;
  final VoidCallback onChanged;

  @override
  ConsumerState<AudioSection> createState() => _AudioSectionState();
}

class _AudioSectionState extends ConsumerState<AudioSection> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _recording = false;
  bool _uploading = false;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  Future<void> _toggleRecord() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null) return;
      setState(() => _uploading = true);
      try {
        await _repo.uploadAttachment(
          widget.task.id,
          filePath: path,
          contentType: DioMediaType('audio', 'mp4'),
        );
        widget.onChanged();
      } catch (_) {
        messenger.showSnackBar(const SnackBar(content: Text('语音上传失败')));
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    } else {
      if (!await _recorder.hasPermission()) {
        messenger.showSnackBar(const SnackBar(content: Text('未获得麦克风权限')));
        return;
      }
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: filePath);
      setState(() => _recording = true);
    }
  }

  Future<void> _togglePlay(Attachment a) async {
    if (_playingId == a.id) {
      await _player.stop();
      setState(() => _playingId = null);
    } else {
      await _player.stop();
      await _player.play(UrlSource(fileUrl(a.path)));
      setState(() => _playingId = a.id);
    }
  }

  Future<void> _delete(Attachment a) async {
    if (_playingId == a.id) {
      await _player.stop();
      _playingId = null;
    }
    await _repo.deleteAttachment(a.id);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final audios = widget.task.audios;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('语音', style: Theme.of(context).textTheme.titleMedium),
            FilledButton.tonalIcon(
              onPressed: _uploading ? null : _toggleRecord,
              icon: Icon(_recording ? Icons.stop : Icons.mic),
              label: Text(_recording ? '停止' : '录音'),
            ),
          ],
        ),
        if (_uploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        if (audios.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('暂无语音', style: TextStyle(color: Colors.grey)),
          )
        else
          ...audios.asMap().entries.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconButton(
                    icon: Icon(
                      _playingId == e.value.id
                          ? Icons.stop_circle
                          : Icons.play_circle,
                    ),
                    onPressed: () => _togglePlay(e.value),
                  ),
                  title: Text('语音 ${e.key + 1}'),
                  subtitle: Text('${(e.value.size / 1024).toStringAsFixed(0)} KB'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(e.value),
                  ),
                ),
              ),
      ],
    );
  }
}
