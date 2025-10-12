import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/models/diary_entry.dart';
import '../../l10n/app_localizations.dart';
import '../common/navigation.dart';
import 'diary_edit.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final diaryAsync = ref.watch(diaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('diary')),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              final payload = await ref.read(localRepositoryProvider).exportDiary();
              await Clipboard.setData(ClipboardData(text: payload));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.translate('exportDiary'))),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () async {
              final controller = TextEditingController();
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(strings.translate('importDiary')),
                  content: TextField(
                    controller: controller,
                    maxLines: 8,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('cancel'))),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                      child: Text(strings.translate('importDiary')),
                    ),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty) {
                await ref.read(localRepositoryProvider).importDiaryPayload(result);
                ref.invalidate(diaryProvider);
              }
            },
          ),
        ],
      ),
      body: diaryAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(child: Text(strings.translate('diaryEmpty')));
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                child: ListTile(
                  title: Text(entry.title.isEmpty ? strings.translate('diary') : entry.title),
                  subtitle: Text(entry.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(entry.tags.join(', ')),
                  onTap: () async {
                    final updated = await showDialog<DiaryEntry>(
                      context: context,
                      builder: (context) => DiaryEditDialog(entry: entry),
                    );
                    if (updated != null) {
                      final list = [...entries];
                      list[index] = updated;
                      await ref.read(localRepositoryProvider).saveDiary(list);
                      ref.invalidate(diaryProvider);
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final entry = await showDialog<DiaryEntry>(
            context: context,
            builder: (context) => const DiaryEditDialog(),
          );
          if (entry != null) {
            final entries = await ref.read(localRepositoryProvider).loadDiary();
            entries.insert(0, entry);
            await ref.read(localRepositoryProvider).saveDiary(entries);
            ref.invalidate(diaryProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: buildNavigationBar(context, 1),
    );
  }
}
