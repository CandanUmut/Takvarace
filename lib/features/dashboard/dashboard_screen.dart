import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/models/deed.dart';
import '../../domain/services/parser_service.dart';
import '../../l10n/app_localizations.dart';
import '../common/navigation.dart';
import '../repentance/repentance_modal.dart';
import 'controllers/pomodoro_controller.dart';
import 'dashboard_providers.dart';
import 'widgets/clean_timer.dart';
import 'widgets/pomodoro_timer_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/zikr_counter_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _freeTextController = TextEditingController();
  final FocusNode _entryFocusNode = FocusNode();
  final Map<String, _DashboardGoal> _goalConfigs = {
    'steady': const _DashboardGoal(
      titleKey: 'dashboardGoalSteadyTitle',
      subtitleKey: 'dashboardGoalSteadySubtitle',
      icon: Icons.flight_takeoff,
      weeklyTarget: 350,
    ),
    'growth': const _DashboardGoal(
      titleKey: 'dashboardGoalGrowthTitle',
      subtitleKey: 'dashboardGoalGrowthSubtitle',
      icon: Icons.rocket_launch,
      weeklyTarget: 550,
    ),
    'reflect': const _DashboardGoal(
      titleKey: 'dashboardGoalReflectTitle',
      subtitleKey: 'dashboardGoalReflectSubtitle',
      icon: Icons.self_improvement,
      weeklyTarget: 220,
    ),
  };
  String _selectedGoal = 'steady';
  bool _pomodoroListenerAttached = false;
  List<DeedEntry> _parsedEntries = [];
  List<String> _suggestions = [];

  @override
  void dispose() {
    _freeTextController.dispose();
    _entryFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_pomodoroListenerAttached) {
      _pomodoroListenerAttached = true;
      ref.listen<AsyncValue<PomodoroState>>(pomodoroControllerProvider, (previous, next) {
        final previousMode = previous?.valueOrNull?.lastCompletedMode;
        final newMode = next.valueOrNull?.lastCompletedMode;
        if (newMode != null && newMode != previousMode) {
          final strings = AppLocalizations.of(context);
          final message = newMode == PomodoroMode.focus
              ? strings.translate('dashboardPomodoroFocusComplete')
              : strings.translate('dashboardPomodoroBreakComplete');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(profileControllerProvider).value;
    final alias = profile?.alias ?? strings.translate('createAlias');
    final focusAreas = profile?.focusAreas ?? const [];
    final intention = profile?.dailyIntention;
    final weeklyScoreAsync = ref.watch(weeklyScoreProvider);
    final parserAsync = ref.watch(parserServiceProvider);
    final pointsConfigAsync = ref.watch(pointsConfigProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        bottomNavigationBar: buildNavigationBar(context, 0),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.45),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroHeader(context, strings, alias, weeklyScoreAsync, focusAreas),
                      const SizedBox(height: 16),
                      _buildWeeklyProgressCard(context, strings, weeklyScoreAsync),
                    ],
                  ),
                ),
                _buildTabBar(strings),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOverviewTab(
                        context,
                        strings,
                        intention,
                        parserAsync,
                        pointsConfigAsync,
                      ),
                      _buildFocusTab(context, strings, focusAreas),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: TabBar(
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.primary,
          ),
          tabs: [
            Tab(text: strings.translate('dashboardTabOverview')),
            Tab(text: strings.translate('dashboardTabFocus')),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    AppLocalizations strings,
    String? intention,
    AsyncValue<ParserService> parserAsync,
    AsyncValue<Map<String, dynamic>> pointsConfigAsync,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        _buildGoalSelector(context, strings),
        const SizedBox(height: 16),
        _buildIntentionCard(context, strings, intention),
        const SizedBox(height: 16),
        pointsConfigAsync.when(
          data: (config) => _buildQuickActionsCard(context, strings, config),
          loading: () => const _LoadingCard(),
          error: (error, stack) => _InfoBanner(message: strings.translate('companionScoreError')),
        ),
        const SizedBox(height: 16),
        _buildGuidedPrompts(context, strings),
        const SizedBox(height: 16),
        _buildEntryComposer(context, strings, parserAsync),
        const SizedBox(height: 16),
        _buildParsedResults(context, strings),
      ],
    );
  }

  Widget _buildFocusTab(
    BuildContext context,
    AppLocalizations strings,
    List<String> focusAreas,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        const CleanTimer(),
        const SizedBox(height: 16),
        const ZikrCounterCard(),
        const SizedBox(height: 16),
        const PomodoroTimerCard(),
        const SizedBox(height: 16),
        _buildFocusAreaSection(context, strings, focusAreas),
        const SizedBox(height: 16),
        _buildCompanionContent(context, strings),
        const SizedBox(height: 16),
        _buildRepentanceCard(context, strings),
      ],
    );
  }

  Widget _buildWeeklyProgressCard(
    BuildContext context,
    AppLocalizations strings,
    AsyncValue<int> weeklyScoreAsync,
  ) {
    final goal = _goalConfigs[_selectedGoal]!;
    final theme = Theme.of(context);
    return weeklyScoreAsync.when(
      loading: () => const _LoadingCard(),
      error: (error, stack) => _InfoBanner(message: strings.translate('companionScoreError')),
      data: (score) {
        final progress = goal.weeklyTarget == 0 ? 0.0 : score / goal.weeklyTarget;
        final clamped = progress.clamp(0, 1).toDouble();
        final description = score >= goal.weeklyTarget
            ? strings.translate('dashboardWeeklyProgressComplete')
            : strings.translate('dashboardWeeklyProgressHint').replaceAll('{points}', '${goal.weeklyTarget - score}');

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Icon(goal.icon, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.translate(goal.titleKey), style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(strings.translate(goal.subtitleKey), style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: clamped),
                const SizedBox(height: 12),
                Text('${strings.translate('dashboardWeeklyProgressLabel')} $score/${goal.weeklyTarget}'),
                const SizedBox(height: 8),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalSelector(BuildContext context, AppLocalizations strings) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.translate('dashboardGoalTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(strings.translate('dashboardGoalDescription'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _goalConfigs.entries
                  .map(
                    (entry) => ChoiceChip(
                      label: Text(strings.translate(entry.value.titleKey)),
                      selected: _selectedGoal == entry.key,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedGoal = entry.key;
                          });
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
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

  Widget _buildHeroHeader(
    BuildContext context,
    AppLocalizations strings,
    String alias,
    AsyncValue<int> weeklyScoreAsync,
    List<String> focusAreas,
  ) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final focusLabels = focusAreas.map((key) => _focusLabel(strings, key)).toList();

    final stats = weeklyScoreAsync.when<Widget>(
      data: (score) {
        final items = <Widget>[
          _HeroChip(
            label: strings.translate('weeklyScore'),
            value: '$score',
            foreground: onPrimary,
          ),
        ];
        for (final label in focusLabels.take(2)) {
          items.add(
            _HeroChip(
              label: strings.translate('companionFocusHeader'),
              value: label,
              foreground: onPrimary,
            ),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items,
        );
      },
      loading: () => const SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.centerLeft,
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
      error: (error, stack) => Text(
        strings.translate('companionScoreError'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: onPrimary.withOpacity(0.9),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${strings.translate('companionGreeting')} $alias!',
            style: theme.textTheme.headlineSmall?.copyWith(color: onPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            strings.translate('companionSubtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          stats,
        ],
      ),
    );
  }

  Widget _buildIntentionCard(
    BuildContext context,
    AppLocalizations strings,
    String? intention,
  ) {
    final theme = Theme.of(context);
    final hasIntention = intention != null && intention.trim().isNotEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.translate('companionIntentionTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              hasIntention
                  ? intention!
                  : strings.translate('companionIntentionFallback'),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusAreaSection(
    BuildContext context,
    AppLocalizations strings,
    List<String> focusAreas,
  ) {
    final theme = Theme.of(context);
    final labels = focusAreas.map((key) => _focusLabel(strings, key)).toList();
    final tips = focusAreas
        .map((key) => _focusTip(strings, key))
        .whereType<String>()
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.translate('companionFocusHeader'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (labels.isEmpty)
              Text(strings.translate('companionFocusEmpty'), style: theme.textTheme.bodyMedium)
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: labels
                    .map((label) => Chip(label: Text(label)))
                    .toList(),
              ),
              const SizedBox(height: 12),
              ...tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(tip, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionContent(BuildContext context, AppLocalizations strings) {
    final theme = Theme.of(context);
    final cards = [
      _CompanionContentData(
        icon: Icons.self_improvement_outlined,
        title: strings.translate('companionCardMindfulTitle'),
        body: strings.translate('companionCardMindfulBody'),
      ),
      _CompanionContentData(
        icon: Icons.book_outlined,
        title: strings.translate('companionCardGratitudeTitle'),
        body: strings.translate('companionCardGratitudeBody'),
      ),
      _CompanionContentData(
        icon: Icons.volunteer_activism_outlined,
        title: strings.translate('companionCardServiceTitle'),
        body: strings.translate('companionCardServiceBody'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.translate('companionContentTitle'), style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        ...cards.map((data) => _CompanionContentCard(data: data)),
      ],
    );
  }

  Widget _buildRepentanceCard(BuildContext context, AppLocalizations strings) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.translate('repentanceFlow'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(strings.translate('completeRepentance'), style: theme.textTheme.bodyMedium),
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
              label: Text(strings.translate('repentance')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(
    BuildContext context,
    AppLocalizations strings,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.translate('companionQuickActionsTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(strings.translate('companionQuickAdd'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            QuickActions(
              pointsConfig: config,
              onAction: (entry) async {
                await ref.read(scoreServiceProvider).applyDeeds([entry]);
                ref.invalidate(weeklyScoreProvider);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidedPrompts(BuildContext context, AppLocalizations strings) {
    final theme = Theme.of(context);
    final prompts = [
      strings.translate('companionGuidedPromptReflect'),
      strings.translate('companionGuidedPromptGratitude'),
      strings.translate('companionGuidedPromptPlan'),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.translate('companionGuidedPrompts'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: prompts
                  .map(
                    (prompt) => ActionChip(
                      label: Text(prompt),
                      onPressed: () {
                        _applyPrompt(prompt);
                        _entryFocusNode.requestFocus();
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryComposer(
    BuildContext context,
    AppLocalizations strings,
    AsyncValue<ParserService> parserAsync,
  ) {
    final theme = Theme.of(context);
    final parser = parserAsync.valueOrNull;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.translate('companionEntryHelperTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(strings.translate('companionEntryHelperSubtitle'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _freeTextController,
              focusNode: _entryFocusNode,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: strings.translate('freeTextPlaceholder'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: parser == null
                      ? null
                      : () => _parse(parser, strings),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(strings.translate('parse')),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
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
                  icon: const Icon(Icons.save_alt),
                  label: Text(strings.translate('save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedResults(BuildContext context, AppLocalizations strings) {
    if (_parsedEntries.isEmpty && _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_parsedEntries.isNotEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.translate('parsedEntries'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ..._parsedEntries.map(
                    (entry) => ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text('${entry.type.name} +${entry.points}'),
                      subtitle: entry.note != null ? Text(entry.note!) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.translate('unknownEntries'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ..._suggestions.map(
                      (suggestion) => ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: Text(suggestion),
                        onTap: () {
                          setState(() {
                            _freeTextController
                              ..text = suggestion
                              ..selection = TextSelection.collapsed(offset: suggestion.length);
                            _parsedEntries = [];
                          });
                          _entryFocusNode.requestFocus();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _applyPrompt(String prompt) {
    setState(() {
      _freeTextController
        ..text = prompt
        ..selection = TextSelection.collapsed(offset: prompt.length);
    });
  }

  String _focusLabel(AppLocalizations strings, String key) {
    switch (key) {
      case 'prayer':
        return strings.translate('onboardingFocusPrayer');
      case 'quran':
        return strings.translate('onboardingFocusQuran');
      case 'wellbeing':
        return strings.translate('onboardingFocusWellbeing');
      case 'charity':
        return strings.translate('onboardingFocusCharity');
      case 'knowledge':
        return strings.translate('onboardingFocusKnowledge');
      default:
        return key;
    }
  }

  String? _focusTip(AppLocalizations strings, String key) {
    switch (key) {
      case 'prayer':
        return strings.translate('companionFocusTipPrayer');
      case 'quran':
        return strings.translate('companionFocusTipQuran');
      case 'wellbeing':
        return strings.translate('companionFocusTipWellbeing');
      case 'charity':
        return strings.translate('companionFocusTipCharity');
      case 'knowledge':
        return strings.translate('companionFocusTipKnowledge');
      default:
        return null;
    }
  }
}

class _DashboardGoal {
  const _DashboardGoal({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.weeklyTarget,
  });

  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final int weeklyTarget;
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value, required this.foreground});

  final String label;
  final String value;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: foreground.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompanionContentData {
  const _CompanionContentData({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

class _CompanionContentCard extends StatelessWidget {
  const _CompanionContentCard({required this.data});

  final _CompanionContentData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(data.icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(data.body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}
