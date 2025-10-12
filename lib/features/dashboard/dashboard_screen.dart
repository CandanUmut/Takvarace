import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/models/deed.dart';
import '../../domain/services/parser_service.dart';
import '../../l10n/app_localizations.dart';
import '../common/navigation.dart';
import '../repentance/repentance_modal.dart';
import 'widgets/clean_timer.dart';
import 'widgets/quick_actions.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _freeTextController = TextEditingController();
  List<DeedEntry> _parsedEntries = [];
  List<String> _suggestions = [];

  @override
  void dispose() {
    _freeTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final weeklyScoreAsync = ref.watch(weeklyScoreProvider);
    final parserAsync = ref.watch(parserServiceProvider);
    final pointsConfigAsync = ref.watch(pointsConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.translate('dashboard'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(strings.translate('startDay'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          weeklyScoreAsync.when(
            data: (score) => Chip(label: Text('${strings.translate('weeklyScore')}: $score')),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
          const SizedBox(height: 16),
          const CleanTimer(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final points = await showDialog<int>(
                context: context,
                builder: (context) => const RepentanceModal(),
              );
              if (!mounted) return;
              if (points != null) {
                ref.invalidate(weeklyScoreProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${strings.translate('repentanceFlow')} +$points')),
                );
              }
            },
            icon: const Icon(Icons.healing),
            label: Text(strings.translate('completeRepentance')),
          ),
          const SizedBox(height: 24),
          pointsConfigAsync.when(
            data: (config) => QuickActions(
              pointsConfig: config,
              onAction: (entry) async {
                await ref.read(scoreServiceProvider).applyDeeds([entry]);
                ref.invalidate(weeklyScoreProvider);
                setState(() {});
              },
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
          const SizedBox(height: 24),
          Text(strings.translate('addEntry'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _freeTextController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: strings.translate('freeTextPlaceholder'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: parserAsync.hasValue
                    ? () => _parse(parserAsync.valueOrNull!, strings)
                    : null,
                child: Text(strings.translate('parse')),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _parsedEntries.isEmpty
                    ? null
                    : () async {
                        await ref.read(scoreServiceProvider).applyDeeds(_parsedEntries);
                        ref.invalidate(weeklyScoreProvider);
                        setState(() {
                          _parsedEntries = [];
                          _suggestions = [];
                          _freeTextController.clear();
                        });
                      },
                child: Text(strings.translate('save')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_parsedEntries.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.translate('parsedEntries'), style: Theme.of(context).textTheme.titleMedium),
                ..._parsedEntries.map((entry) => ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text('${entry.type.name} +${entry.points}'),
                      subtitle: entry.note != null ? Text(entry.note!) : null,
                    )),
              ],
            ),
          if (_suggestions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.translate('unknownEntries'), style: Theme.of(context).textTheme.titleMedium),
                ..._suggestions.map((suggestion) => ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text(suggestion),
                    )),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildNavigationBar(context, 0),
    );
  }

  void _parse(ParserService parser, AppLocalizations strings) {
    final text = _freeTextController.text.trim();
    if (text.isEmpty) return;
    final profile = ref.read(profileControllerProvider).value;
    final result = parser.parse(text, languageCode: profile?.languageCode ?? 'en');
    setState(() {
      _parsedEntries = result.entries;
      _suggestions = result.suggestions;
    });
    if (result.entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.translate('unknownEntries'))),
      );
    }
  }
}
