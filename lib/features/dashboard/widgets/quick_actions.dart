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
      spacing: 16,
      runSpacing: 16,
      children: [
        _actionCard(
          context,
          label: '${strings.translate('quran')} 10m',
          points: _valueFromConfig('quran', amount: 10, unit: 'minute'),
          type: DeedType.quran,
          meta: const {'minutes': 10},
        ),
        _actionCard(
          context,
          label: strings.translate('dhikr'),
          points: _configValue('dhikr'),
          type: DeedType.dhikr,
          meta: const {'context': 'morning_evening'},
        ),
        _actionCard(
          context,
          label: strings.translate('walk'),
          points: _valueFromSteps(10),
          type: DeedType.walk,
          meta: const {'minutes': 10},
        ),
        _actionCard(
          context,
          label: strings.translate('istighfar'),
          points: _valueFromConfig('istighfar', amount: 33, unit: 'x'),
          type: DeedType.istighfar,
          meta: const {'repetitions': 33},
        ),
        _actionCard(
          context,
          label: '${strings.translate('repentance')} +',
          points: _configValue('repentance_base') + _configValue('repentance_recovery'),
          type: DeedType.repentance,
          meta: const {'quick': true},
        ),
        _actionCard(
          context,
          label: '${strings.translate('prayer')} (Farz)',
          points: _prayerPoints(),
          type: DeedType.prayer,
          meta: const {'mode': 'solo'},
        ),
        _actionCard(
          context,
          label: '${strings.translate('prayer')} (Jamaah)',
          points: _prayerPoints(congregation: true),
          type: DeedType.prayer,
          meta: const {'mode': 'congregation'},
        ),
        _actionCard(
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

  Widget _actionCard(
    BuildContext context, {
    required String label,
    required int points,
    required DeedType type,
    required Map<String, dynamic> meta,
  }) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    return SizedBox(
      width: 200,
      child: Material(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: points == 0
              ? null
              : () async {
                  final entry = DeedEntry(
                    timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    type: type,
                    points: points,
                    meta: meta,
                    source: DeedSource.form,
                  );
                  await onAction(entry);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${strings.translate('companionQuickAdd')} $label (+$points)',
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconForType(type), color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('${strings.translate('points')}: +$points', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(DeedType type) {
    switch (type) {
      case DeedType.quran:
        return Icons.menu_book_rounded;
      case DeedType.dhikr:
        return Icons.brightness_auto_outlined;
      case DeedType.walk:
        return Icons.directions_walk_rounded;
      case DeedType.istighfar:
        return Icons.repeat_rounded;
      case DeedType.repentance:
        return Icons.healing;
      case DeedType.prayer:
        return Icons.mosque_outlined;
      default:
        return Icons.auto_fix_high;
    }
  }
}
