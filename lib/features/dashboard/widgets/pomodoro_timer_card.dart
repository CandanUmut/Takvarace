import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../controllers/pomodoro_controller.dart';
import '../dashboard_providers.dart';

class PomodoroTimerCard extends ConsumerWidget {
  const PomodoroTimerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(pomodoroControllerProvider);
    final strings = AppLocalizations.of(context);
    return stateAsync.when(
      data: (state) => _PomodoroContents(state: state, strings: strings),
      loading: () => const _PomodoroLoadingCard(),
      error: (error, stack) => _PomodoroErrorCard(message: error.toString()),
    );
  }
}

class _PomodoroContents extends ConsumerWidget {
  const _PomodoroContents({required this.state, required this.strings});

  final PomodoroState state;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = state.totalForCurrentMode.inSeconds == 0
        ? 0.0
        : state.remaining.inSeconds / state.totalForCurrentMode.inSeconds;
    final minutes = state.remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = state.remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final controller = ref.read(pomodoroControllerProvider.notifier);

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
                    state.mode == PomodoroMode.focus
                        ? strings.translate('dashboardPomodoroFocus')
                        : strings.translate('dashboardPomodoroRest'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: strings.translate('dashboardPomodoroReset'),
                  onPressed: controller.reset,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0, 1),
                      strokeWidth: 12,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      color: state.mode == PomodoroMode.focus
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$minutes:$seconds', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        state.isRunning
                            ? strings.translate('dashboardPomodoroRunning')
                            : strings.translate('dashboardPomodoroReady'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: controller.toggle,
                  icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(state.isRunning
                      ? strings.translate('dashboardPomodoroPause')
                      : strings.translate('dashboardPomodoroStart')),
                ),
                OutlinedButton.icon(
                  onPressed: state.mode == PomodoroMode.focus
                      ? controller.startRest
                      : controller.startFocus,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(state.mode == PomodoroMode.focus
                      ? strings.translate('dashboardPomodoroSwitchToBreak')
                      : strings.translate('dashboardPomodoroBackToFocus')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              strings
                  .translate('dashboardPomodoroCompleted')
                  .replaceAll('{count}', '${state.completedSessions}'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _DurationSelector(
              title: strings.translate('dashboardPomodoroFocusLength'),
              value: state.focusDuration.inMinutes,
              options: const [15, 20, 25, 30, 45],
              onChanged: (value) => controller.updateDurations(focusMinutes: value),
              strings: strings,
            ),
            const SizedBox(height: 12),
            _DurationSelector(
              title: strings.translate('dashboardPomodoroBreakLength'),
              value: state.restDuration.inMinutes,
              options: const [3, 5, 10, 15],
              onChanged: (value) => controller.updateDurations(restMinutes: value),
              strings: strings,
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  const _DurationSelector({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.strings,
  });

  final String title;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options
              .map(
                (option) => ChoiceChip(
                  label: Text('$option ${strings.translate('minutes')}'),
                  selected: value == option,
                  onSelected: (_) => onChanged(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PomodoroLoadingCard extends StatelessWidget {
  const _PomodoroLoadingCard();

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

class _PomodoroErrorCard extends StatelessWidget {
  const _PomodoroErrorCard({required this.message});

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
