import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/memory.dart';
import '../../providers/memories_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemoriesProvider>().loadInitial();
    });
  }

  Future<void> _uploadFromCamera() => _uploadImage(ImageSource.camera);
  Future<void> _uploadFromGallery() => _uploadImage(ImageSource.gallery);

  Future<void> _uploadImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    await _promptTitleAndUpload(file.path, 'photo');
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    await _promptTitleAndUpload(result.files.single.path!, 'document');
  }

  Future<void> _promptTitleAndUpload(String path, String memoryType) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this memory'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty || !mounted) return;
    final ok = await context.read<MemoriesProvider>().upload(
          title: title,
          filePath: path,
          memoryType: memoryType,
          takenAt: DateTime.now(),
        );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<MemoriesProvider>().errorMessage ?? 'Upload failed')),
      );
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _uploadFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _uploadFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('Upload a document'),
              onTap: () {
                Navigator.of(context).pop();
                _uploadDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoriesProvider>();

    Widget body;
    if (provider.isLoading && provider.memories.isEmpty) {
      body = const LoadingIndicator();
    } else if (provider.errorMessage != null && provider.memories.isEmpty) {
      body = ErrorView(
        message: provider.errorMessage!,
        onRetry: () => context.read<MemoriesProvider>().loadInitial(),
      );
    } else if (provider.memories.isEmpty) {
      body = const EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No memories yet',
        message: 'Save photos, screenshots, and documents you want to keep.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => context.read<MemoriesProvider>().loadInitial(),
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: provider.memories.length,
          itemBuilder: (context, index) {
            final memory = provider.memories[index];
            return _MemoryTile(
              memory: memory,
              onLongPress: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete memory?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await context.read<MemoriesProvider>().delete(memory.id);
                }
              },
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: provider.isUploading
            ? const SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add),
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.memory, this.onLongPress});

  final Memory memory;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: memory.isImage && memory.fileUrl != null
              ? CachedNetworkImage(
                  imageUrl: memory.fileUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image_outlined),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 32),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          memory.title,
                          style: Theme.of(context).textTheme.labelSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
