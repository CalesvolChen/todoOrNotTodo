import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:todo_app/features/auth/presentation/view_models/auth_controller.dart';
import 'package:todo_app/shared/widgets/app_back_button.dart';
import 'package:todo_app/shared/widgets/app_error_dialog.dart';
import 'package:todo_app/shared/widgets/app_snackbar.dart';
import 'package:todo_app/shared/widgets/user_avatar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _uploading = false;

  Future<void> _editDisplayName(String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改显示名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '显示名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    final ok = await runWithAppErrorDialog(
      context,
      () => ref.read(authControllerProvider.notifier).updateDisplayName(name),
    );
    if (ok && mounted) {
      context.showAppSnackBar('显示名已更新', type: AppSnackBarType.success);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    final ok = await runWithAppErrorDialog(
      context,
      () => ref.read(authControllerProvider.notifier).updateAvatar(picked),
    );
    if (ok && mounted) {
      context.showAppSnackBar('头像已更新', type: AppSnackBarType.success);
    }
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: secondaryAppBar(context, title: '设置'),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                UserAvatar(
                  key: ValueKey(user?.avatar),
                  avatar: user?.avatar,
                  name: user?.displayName ?? '用户',
                  radius: 44,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _uploading ? null : _pickAvatar,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: _uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('昵称'),
            subtitle: Text(user?.username ?? '-'),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('显示名'),
            subtitle: Text(user?.displayName ?? '-'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editDisplayName(user?.name),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () {
              ref.read(authControllerProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
