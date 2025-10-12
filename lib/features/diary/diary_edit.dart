import 'package:flutter/material.dart';

import '../../domain/models/diary_entry.dart';
import '../../l10n/app_localizations.dart';

class DiaryEditDialog extends StatefulWidget {
  const DiaryEditDialog({super.key, this.entry});

  final DiaryEntry? entry;

  @override
  State<DiaryEditDialog> createState() => _DiaryEditDialogState();
}

class _DiaryEditDialogState extends State<DiaryEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(text: widget.entry?.content ?? '');
    _tagsController = TextEditingController(text: widget.entry?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.translate('diary')),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: strings.translate('entryTitle')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                minLines: 6,
                maxLines: 12,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: strings.translate('entryContent'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(labelText: '${strings.translate('tags')} (comma separated)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('cancel'))),
        FilledButton(
          onPressed: () {
            final entry = DiaryEntry(
              id: widget.entry?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
            Navigator.of(context).pop(entry);
          },
          child: Text(strings.translate('save')),
        ),
      ],
    );
  }
}
