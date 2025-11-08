import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/zikr_state.dart';
import '../../../l10n/app_localizations.dart';
import '../dashboard_providers.dart';

class ZikrCounterCard extends ConsumerWidget {
  const ZikrCounterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(zikrControllerProvider);
    final strings = AppLocalizations.of(context);
    return stateAsync.when(
      data: (state) => _ZikrCardContents(state: state, strings: strings),
      loading: () => const _LoadingZikrCard(),
      error: (error, stack) => _ErrorCard(message: error.toString()),
    );
  }
}

class _ZikrCardContents extends ConsumerWidget {
  const _ZikrCardContents({required this.state, required this.strings});

  final ZikrState state;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = state.goal == 0 ? 0.0 : state.count / state.goal;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.phrase,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: strings.translate('settings'),
                  onPressed: () => _openSettings(context, ref, state),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              backgroundColor: theme.colorScheme.surfaceVariant,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${strings.translate('dashboardZikrCountLabel')} ${state.count}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                Text(
                  '${strings.translate('dashboardZikrGoalLabel')} ${state.goal}',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(zikrControllerProvider.notifier).reset(),
                  child: Text(strings.translate('dashboardZikrReset')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => ref.read(zikrControllerProvider.notifier).increment(),
                    icon: const Icon(Icons.plus_one),
                    label: Text(strings.translate('dashboardZikrAddOne')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.count > 0
                        ? () => ref.read(zikrControllerProvider.notifier).decrement()
                        : null,
                    icon: const Icon(Icons.remove),
                    label: Text(strings.translate('dashboardZikrRemove')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(zikrControllerProvider.notifier).increment(10),
                    icon: const Icon(Icons.exposure_plus_2),
                    label: Text(strings.translate('dashboardZikrAddTen')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context, WidgetRef ref, ZikrState state) async {
    final phraseController = TextEditingController(text: state.phrase);
    final goalController = TextEditingController(text: state.goal.toString());
    final result = await showDialog<_ZikrSettingsResult>(
      context: context,
      builder: (context) => _ZikrSettingsDialog(
        phraseController: phraseController,
        goalController: goalController,
        strings: strings,
      ),
    );
    if (result == null) return;
    ref
        .read(zikrControllerProvider.notifier)
        .updateSettings(phrase: result.phrase, goal: result.goal);
  }
}

class _ZikrSettingsResult {
  const _ZikrSettingsResult({required this.phrase, required this.goal});

  final String phrase;
  final int goal;
}

class _ZikrSettingsDialog extends StatelessWidget {
  const _ZikrSettingsDialog({
    required this.phraseController,
    required this.goalController,
    required this.strings,
  });

  final TextEditingController phraseController;
  final TextEditingController goalController;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(strings.translate('dashboardZikrCustomize')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: phraseController,
            decoration: InputDecoration(labelText: strings.translate('dashboardZikrPhrase')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: goalController,
            decoration: InputDecoration(labelText: strings.translate('dashboardZikrGoalLabel')),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.translate('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final phrase = phraseController.text.trim();
            final goal = int.tryParse(goalController.text.trim());
            if (goal == null || goal <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.translate('dashboardZikrInvalidGoal'))),
              );
              return;
            }
            Navigator.of(context).pop(_ZikrSettingsResult(phrase: phrase, goal: goal));
          },
          child: Text(strings.translate('save')),
        ),
      ],
    );
  }
}

class _LoadingZikrCard extends StatelessWidget {
  const _LoadingZikrCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message),
      ),
    );
  }
}
