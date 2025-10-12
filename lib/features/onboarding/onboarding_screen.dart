import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/models/user_profile.dart';
import '../../core/utils/validators.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _aliasController = TextEditingController();
  String _languageCode = 'en';
  bool _shareScore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).value;
    if (profile != null) {
      _aliasController.text = profile.alias;
      _languageCode = profile.languageCode;
      _shareScore = profile.shareScore;
    }
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isLoading = ref.watch(profileControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(strings.translate('pledgeTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings.translate('pledgeText'), style: Theme.of(context).textTheme.titleMedium),
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
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _shareScore,
                  onChanged: isLoading ? null : (value) => setState(() => _shareScore = value),
                  title: Text(strings.translate('shareScore')),
                  subtitle: Text(strings.translate('anonymousPledge')),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : () => _submit(context, strings),
                  child: Text(strings.translate('startTracking')),
                ),
              ],
            ),
          ),
        ),
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
    final profile = UserProfile(alias: alias, languageCode: _languageCode, shareScore: _shareScore);
    await ref.read(profileControllerProvider.notifier).updateProfile(profile);
    ref.invalidate(pointsConfigProvider);
    ref.invalidate(parserServiceProvider);
    if (!mounted) return;
    context.go('/dashboard');
  }
}
