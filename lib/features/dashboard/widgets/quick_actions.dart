import 'package:flutter/material.dart';

import '../../../domain/models/deed.dart';
import '../../../l10n/app_localizations.dart';

typedef QuickActionHandler = Future<void> Function(DeedEntry entry);

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.pointsConfig, required this.onAction});

  final Map<String, dynamic> pointsConfig;
  final QuickActionHandler onAction;

  int _prayerPoints({bool congregation = false, bool masjid = false}) {
    final prayer = pointsConfig['prayer'] as Map<String, dynamic>? ?? {};
    final base = prayer['base'] as int? ?? 10;
    final cong = congregation ? prayer['congregation'] as int? ?? 0 : 0;
    final mas = masjid ? prayer['masjid'] as int? ?? 0 : 0;
    return base + cong + mas;
  }

  int _configValue(String key) => pointsConfig[key] as int? ?? 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _actionButton(
          context,
          label: '${strings.translate('quran')} 10m',
          points: _valueFromConfig('quran', amount: 10, unit: 'minute'),
          type: DeedType.quran,
          meta: const {'minutes': 10},
        ),
        _actionButton(
          context,
          label: strings.translate('dhikr'),
          points: _configValue('dhikr'),
          type: DeedType.dhikr,
          meta: const {'context': 'morning_evening'},
        ),
        _actionButton(
          context,
          label: strings.translate('walk'),
          points: _valueFromSteps(10),
          type: DeedType.walk,
          meta: const {'minutes': 10},
        ),
        _actionButton(
          context,
          label: strings.translate('istighfar'),
          points: _valueFromConfig('istighfar', amount: 33, unit: 'x'),
          type: DeedType.istighfar,
          meta: const {'repetitions': 33},
        ),
        _actionButton(
          context,
          label: '${strings.translate('repentance')} +',
          points: _configValue('repentance_base') + _configValue('repentance_recovery'),
          type: DeedType.repentance,
          meta: const {'quick': true},
        ),
        _actionButton(
          context,
          label: '${strings.translate('prayer')} (Farz)',
          points: _prayerPoints(),
          type: DeedType.prayer,
          meta: const {'mode': 'solo'},
        ),
        _actionButton(
          context,
          label: '${strings.translate('prayer')} (Jamaah)',
          points: _prayerPoints(congregation: true),
          type: DeedType.prayer,
          meta: const {'mode': 'congregation'},
        ),
        _actionButton(
          context,
          label: '${strings.translate('prayer')} (Masjid)',
          points: _prayerPoints(congregation: true, masjid: true),
          type: DeedType.prayer,
          meta: const {'mode': 'masjid'},
        ),
      ],
    );
  }

  int _valueFromConfig(String key, {int amount = 1, String? unit}) {
    final config = pointsConfig[key];
    if (config is int) return config;
    if (config is Map<String, dynamic>) {
      final base = config['minute'] as int? ?? config['page'] as int? ?? 0;
      final block = config['block'] as int? ?? 1;
      final multiplier = (amount / block).ceil();
      return base * multiplier;
    }
    return 0;
  }

  int _valueFromSteps(int minutes) {
    final config = pointsConfig['walk'];
    if (config is Map<String, dynamic>) {
      final steps = config['steps'] as Map<String, dynamic>?;
      if (steps != null) {
        int best = 0;
        for (final entry in steps.entries) {
          final threshold = int.tryParse(entry.key) ?? 0;
          if (minutes >= threshold) {
            best = entry.value as int;
          }
        }
        return best;
      }
    }
    return 0;
  }

  Widget _actionButton(BuildContext context,
      {required String label,
      required int points,
      required DeedType type,
      required Map<String, dynamic> meta}) {
    return ElevatedButton.icon(
      onPressed: () async {
        final entry = DeedEntry(
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          type: type,
          points: points,
          meta: meta,
          source: DeedSource.form,
        );
        await onAction(entry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${label} +$points')),
        );
      },
      icon: const Icon(Icons.add),
      label: Text(label),
    );
  }
}
