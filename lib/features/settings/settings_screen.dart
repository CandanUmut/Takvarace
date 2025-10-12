import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../../domain/models/user_profile.dart';
import '../../l10n/app_localizations.dart';
import '../common/navigation.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _privateMode = false;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _privateMode = prefs.getBool('private_mode') ?? false;
      _loadingPrefs = false;
    });
  }

  Future<void> _togglePrivateMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('private_mode', value);
    setState(() => _privateMode = value);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.translate('settings'))),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(strings.translate('createAlias')));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: Text(strings.translate('alias')),
                subtitle: Text(profile.alias),
              ),
              DropdownButtonFormField<String>(
                value: profile.languageCode,
                decoration: InputDecoration(labelText: strings.translate('language')),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  final updated = profile.copyWith(languageCode: value);
                  ref.read(profileControllerProvider.notifier).updateProfile(updated);
                  ref.invalidate(pointsConfigProvider);
                  ref.invalidate(parserServiceProvider);
                },
              ),
              SwitchListTile(
                value: profile.shareScore,
                onChanged: (value) {
                  final updated = profile.copyWith(shareScore: value);
                  ref.read(profileControllerProvider.notifier).updateProfile(updated);
                },
                title: Text(strings.translate('shareScore')),
              ),
              if (!_loadingPrefs)
                SwitchListTile(
                  value: _privateMode,
                  onChanged: _togglePrivateMode,
                  title: Text(strings.translate('privacyMode')),
                  subtitle: Text(_privateMode ? strings.translate('enable') : strings.translate('disable')),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: buildNavigationBar(context, 4),
    );
  }
}
