import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/utils/validators.dart';
import '../../domain/models/user_profile.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _focusAreaKeys = [
    'prayer',
    'quran',
    'wellbeing',
    'charity',
    'knowledge',
  ];

  final _aliasController = TextEditingController();
  final _intentionController = TextEditingController();
  final PageController _pageController = PageController();

  String _languageCode = 'en';
  bool _shareScore = true;
  int _currentPage = 0;
  String? _error;
  final Set<String> _selectedFocus = <String>{};

  int get _pageCount => 3;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).value;
    if (profile != null) {
      _aliasController.text = profile.alias;
      _languageCode = profile.languageCode;
      _shareScore = profile.shareScore;
      _selectedFocus.addAll(profile.focusAreas);
      if (profile.dailyIntention != null) {
        _intentionController.text = profile.dailyIntention!;
      }
    }
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _intentionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isLoading = ref.watch(profileControllerProvider).isLoading;
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.translate('onboardingWelcomeTitle'),
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.translate('onboardingWelcomeDescription'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              _goToPage(_pageCount - 1);
                            },
                      child: Text(strings.translate('onboardingSkip')),
                    ),
                ],
              ),
            ),
            _ProgressDots(currentPage: _currentPage, total: _pageCount),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const _WelcomePage(),
                  _buildFocusSelection(context, strings),
                  _buildProfileForm(context, strings, isLoading),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              _goToPage(_currentPage - 1);
                            },
                      child: Text(strings.translate('onboardingBack')),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              if (isLastPage) {
                                _submit(context, strings);
                              } else {
                                _goToPage(_currentPage + 1);
                              }
                            },
                      child: Text(
                        isLastPage
                            ? strings.translate('startTracking')
                            : strings.translate('onboardingNext'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusSelection(BuildContext context, AppLocalizations strings) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.translate('onboardingFocusTitle'), style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(strings.translate('onboardingFocusDescription'), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _focusAreaKeys.map((key) {
              final selected = _selectedFocus.contains(key);
              return ChoiceChip(
                label: Text(_focusLabel(strings, key)),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedFocus.add(key);
                    } else {
                      _selectedFocus.remove(key);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.translate('companionContentSubtitle'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _HighlightTile(
                    icon: Icons.track_changes_outlined,
                    title: strings.translate('onboardingWelcomeCard1Title'),
                    subtitle: strings.translate('onboardingWelcomeCard1Body'),
                  ),
                  const SizedBox(height: 12),
                  _HighlightTile(
                    icon: Icons.favorite_outlined,
                    title: strings.translate('onboardingWelcomeCard2Title'),
                    subtitle: strings.translate('onboardingWelcomeCard2Body'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(
    BuildContext context,
    AppLocalizations strings,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.translate('onboardingProfileTitle'), style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(strings.translate('onboardingProfileDescription'), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _languageCode,
            decoration: InputDecoration(labelText: strings.translate('language')),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
            ],
            onChanged: isLoading ? null : (value) => setState(() => _languageCode = value ?? 'en'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aliasController,
            decoration: InputDecoration(
              labelText: strings.translate('alias'),
              helperText: strings.translate('aliasHint'),
              errorText: _error,
            ),
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _intentionController,
            decoration: InputDecoration(
              labelText: strings.translate('onboardingDailyIntentionLabel'),
              helperText: strings.translate('onboardingDailyIntentionHint'),
            ),
            enabled: !isLoading,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _shareScore,
            onChanged: isLoading ? null : (value) => setState(() => _shareScore = value),
            title: Text(strings.translate('shareScore')),
            subtitle: Text(strings.translate('anonymousPledge')),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, AppLocalizations strings) async {
    final alias = _aliasController.text.trim();
    if (!Validators.isValidAlias(alias)) {
      setState(() => _error = strings.translate('aliasHint'));
      return;
    }
    setState(() => _error = null);
    final focusAreas = _selectedFocus.toList()..sort();
    final intention = _intentionController.text.trim().isEmpty
        ? null
        : _intentionController.text.trim();
    final profile = UserProfile(
      alias: alias,
      languageCode: _languageCode,
      shareScore: _shareScore,
      focusAreas: focusAreas,
      dailyIntention: intention,
    );
    await ref.read(profileControllerProvider.notifier).updateProfile(profile);
    ref.invalidate(pointsConfigProvider);
    ref.invalidate(parserServiceProvider);
    if (!mounted) return;
    context.go('/dashboard');
  }

  void _goToPage(int page) {
    final target = page.clamp(0, _pageCount - 1);
    setState(() => _currentPage = target);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
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
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.currentPage, required this.total});

  final int currentPage;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          final isActive = index == currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 24 : 12,
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final highlights = [
      _HighlightTile(
        icon: Icons.timeline_outlined,
        title: strings.translate('onboardingWelcomeCard1Title'),
        subtitle: strings.translate('onboardingWelcomeCard1Body'),
      ),
      _HighlightTile(
        icon: Icons.auto_fix_high_outlined,
        title: strings.translate('onboardingWelcomeCard2Title'),
        subtitle: strings.translate('onboardingWelcomeCard2Body'),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.85),
                  theme.colorScheme.secondary.withOpacity(0.75),
                ],
              ),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.self_improvement_outlined,
                    color: theme.colorScheme.onPrimary, size: 40),
                const SizedBox(height: 16),
                Text(
                  strings.translate('intentionPledge'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.translate('pledgeText'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(strings.translate('companionQuickActionsTitle'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...highlights,
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
