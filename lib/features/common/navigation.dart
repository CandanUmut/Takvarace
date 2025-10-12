import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

NavigationBar buildNavigationBar(BuildContext context, int currentIndex) {
  final strings = AppLocalizations.of(context);
  return NavigationBar(
    selectedIndex: currentIndex,
    onDestinationSelected: (index) {
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/diary');
          break;
        case 2:
          context.go('/leaderboard');
          break;
        case 3:
          context.go('/shields');
          break;
        case 4:
          context.go('/settings');
          break;
      }
    },
    destinations: [
      NavigationDestination(icon: const Icon(Icons.today), label: strings.translate('dashboard')),
      NavigationDestination(icon: const Icon(Icons.book), label: strings.translate('diary')),
      NavigationDestination(icon: const Icon(Icons.emoji_events), label: strings.translate('leaderboard')),
      NavigationDestination(icon: const Icon(Icons.shield), label: strings.translate('shields')),
      NavigationDestination(icon: const Icon(Icons.settings), label: strings.translate('settings')),
    ],
  );
}
