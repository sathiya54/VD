import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../models/category.dart';
import '../../models/diary_entry.dart';
import '../../models/mood.dart';
import '../../models/tag.dart';
import '../../providers/diary_provider.dart';
import '../../widgets/mood_picker.dart';
import '../../widgets/primary_button.dart';

/// Create/edit screen for a diary entry.
///
/// NOTE: content uses a plain multiline TextField for simplicity/predictable
/// compilation without extra native setup. A real rich-text editor package
/// such as `flutter_quill` can replace this field later without touching the
/// surrounding form logic.
class DiaryEditorScreen extends StatefulWidget {
  const DiaryEditorScreen({super.key, this.existingEntry});

  final DiaryEntry? existingEntry;

  @override
  State<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends State<DiaryEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagInputController = TextEditingController();
  final _picker = ImagePicker();

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  Mood? _selectedMood;
  DiaryCategory? _selectedCategory;
  final List<String> _tagNames = [];
  bool _isFavorite = false;
  bool _isPrivate = false;
  String? _coverImagePath;
  bool _isSaving = false;

  Timer? _autosaveTimer;
  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      final e = widget.existingEntry!;
      _titleController.text = e.title;
      _contentController.text = e.content;
      _date = DateTime.tryParse(e.date) ?? DateTime.now();
      _selectedMood = e.mood;
      _selectedCategory = e.category;
      _tagNames.addAll(e.tags.map((t) => t.name));
      _isFavorite = e.isFavorite;
      _isPrivate = e.isPrivate;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferDraftRestore());
    }

    _titleController.addListener(_scheduleAutosave);
    _contentController.addListener(_scheduleAutosave);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _scheduleAutosave() {
    if (_isEditing) return; // Only autosave brand-new drafts.
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final draft = {
      'title': _titleController.text,
      'content': _contentController.text,
      'date': _date.toIso8601String(),
      'mood': _selectedMood?.name,
      'category': _selectedCategory?.name,
      'tags': _tagNames,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(AppConstants.draftStorageKey, jsonEncode(draft));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.draftStorageKey);
  }

  Future<void> _maybeOfferDraftRestore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.draftStorageKey);
    if (raw == null || !mounted) return;
    try {
      final draft = jsonDecode(raw) as Map<String, dynamic>;
      final hasContent = (draft['title'] as String? ?? '').isNotEmpty ||
          (draft['content'] as String? ?? '').isNotEmpty;
      if (!hasContent) return;

      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recover draft?'),
          content: const Text(
              'You have an unsaved diary entry from a previous session. Would you like to restore it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (shouldRestore == true && mounted) {
        setState(() {
          _titleController.text = draft['title'] as String? ?? '';
          _contentController.text = draft['content'] as String? ?? '';
          if (draft['date'] != null) {
            _date = DateTime.tryParse(draft['date'] as String) ?? _date;
          }
          _tagNames
            ..clear()
            ..addAll((draft['tags'] as List<dynamic>? ?? []).map((e) => e.toString()));
        });
      } else {
        await _clearDraft();
      }
    } catch (_) {
      await _clearDraft();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickCoverImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file != null) setState(() => _coverImagePath = file.path);
  }

  void _addTag(String raw) {
    final value = raw.trim();
    if (value.isEmpty || _tagNames.contains(value)) return;
    setState(() => _tagNames.add(value));
    _tagInputController.clear();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<DiaryProvider>();
    // Resolve tag names to ids where possible (new tag names are sent as-is;
    // a real backend would create-or-get tags server side).
    final tagIds = _tagNames
        .map((name) {
          final match = provider.tags.where((t) => t.name == name);
          return match.isNotEmpty ? match.first.id : null;
        })
        .whereType<int>()
        .toList();

    final entry = DiaryEntry(
      id: widget.existingEntry?.id ?? 0,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      date: DateFormat('yyyy-MM-dd').format(_date),
      time:
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00',
      mood: _selectedMood,
      category: _selectedCategory,
      tags: _tagNames.map((n) => DiaryTag(id: 0, name: n)).toList(),
      isFavorite: _isFavorite,
      isPrivate: _isPrivate,
    );

    final result = _isEditing
        ? await provider.updateEntry(widget.existingEntry!.id, entry,
            tagIds: tagIds, coverImagePath: _coverImagePath)
        : await provider.createEntry(entry, tagIds: tagIds, coverImagePath: _coverImagePath);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result != null) {
      await _clearDraft();
      Navigator.of(context).pop(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to save entry.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'New Entry'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  image: _coverImagePath != null
                      ? DecorationImage(
                          image: FileImage(File(_coverImagePath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: _coverImagePath == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 32),
                            SizedBox(height: 4),
                            Text('Add cover photo'),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'What\'s on your mind?',
                alignLabelWithHint: true,
              ),
              minLines: 8,
              maxLines: 16,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Write something first' : null,
            ),
            const SizedBox(height: 20),
            Text('Mood', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            MoodPicker(
              moods: provider.moods,
              selected: _selectedMood,
              onSelected: (m) => setState(() => _selectedMood = m),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(DateFormat('MMM d, yyyy').format(_date)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<DiaryCategory>(
              value: _selectedCategory,
              hint: const Text('Select a category'),
              items: provider.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: 20),
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._tagNames.map(
                  (tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tagNames.remove(tag)),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _tagInputController,
                    decoration: const InputDecoration(hintText: 'Add tag'),
                    onSubmitted: _addTag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Private entry'),
              subtitle: const Text('Only visible to you'),
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isEditing ? 'Save Changes' : 'Save Entry',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
