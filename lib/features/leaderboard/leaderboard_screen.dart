import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/navigation.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileControllerProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.translate('leaderboard'))),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null || !profile.shareScore) {
            return Center(child: Text(strings.translate('noLeaderboard')));
          }
          return leaderboardAsync.when(
            data: (rows) {
              return RefreshIndicator(
                onRefresh: () async {
                  await ref.refresh(leaderboardProvider.future);
                },
                child: rows.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_people, size: 64, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(height: 16),
                                Text(
                                  strings.translate('leaderboardEmpty'),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  strings.translate('leaderboardEmptyHint'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          final alias = (row['alias'] as Map?)?['alias']?.toString() ?? row['alias']?.toString() ?? '—';
                          final score = row['score']?.toString() ?? '0';
                          final isMe = alias == profile.alias;
                          return ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(alias),
                            subtitle: Text('${strings.translate('week')}: ${row['week_start']}'),
                            trailing: Text(score, style: Theme.of(context).textTheme.titleLarge),
                            tileColor: isMe ? Theme.of(context).colorScheme.secondaryContainer : null,
                          );
                        },
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemCount: rows.length,
                      ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: buildNavigationBar(context, 2),
    );
  }
}
