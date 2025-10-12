import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/time.dart';
import '../../../domain/models/streak.dart';
import '../../../l10n/app_localizations.dart';

class CleanTimer extends ConsumerStatefulWidget {
  const CleanTimer({super.key});

  @override
  ConsumerState<CleanTimer> createState() => _CleanTimerState();
}

class _CleanTimerState extends ConsumerState<CleanTimer> {
  Timer? _timer;
  StreakState? _streak;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _tick());
  }

  Future<void> _load() async {
    final streak = await ref.read(streakServiceProvider).load();
    setState(() => _streak = streak);
  }

  void _tick() {
    final streak = _streak;
    if (streak == null) return;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final updated = streak.copyWith(currentSeconds: nowSeconds - streak.lastFallTimestamp);
    setState(() => _streak = updated);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final streak = _streak;
    if (streak == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final duration = Duration(seconds: streak.currentSeconds);
    final text = TimeUtils.formatDuration(duration, strings.locale.languageCode);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.translate('cleanTimer'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(text, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
