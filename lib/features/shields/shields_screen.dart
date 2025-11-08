import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../common/navigation.dart';

class ShieldsScreen extends StatelessWidget {
  const ShieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    const guides = <({String title, List<String> steps})>[
      (
        title: 'iOS Screen Time',
        steps: [
          'Open Settings > Screen Time',
          'Enable Downtime and App Limits for distractors',
          'Add Always Allowed apps wisely',
        ],
      ),
      (
        title: 'Android Digital Wellbeing',
        steps: [
          'Open Settings > Digital Wellbeing & parental controls',
          'Set app timers for social media',
          'Schedule Bedtime mode to reduce temptation',
        ],
      ),
      (
        title: 'Browser Extensions',
        steps: [
          'Install open-source blockers like LeechBlock or uBlock Origin',
          'Configure focus schedules for peak vulnerability times',
        ],
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(strings.translate('shields'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: guides.length,
        itemBuilder: (context, index) {
          final guide = guides[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guide.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...guide.steps
                      .map((step) => ListTile(leading: const Icon(Icons.check), title: Text(step)))
                      .toList(),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: buildNavigationBar(context, 3),
    );
  }
}
