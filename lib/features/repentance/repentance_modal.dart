import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

class RepentanceModal extends ConsumerStatefulWidget {
  const RepentanceModal({super.key});

  @override
  ConsumerState<RepentanceModal> createState() => _RepentanceModalState();
}

class _RepentanceModalState extends ConsumerState<RepentanceModal> {
  int _currentStep = 0;
  bool _twoRakah = true;
  int _istighfarCount = 33;
  int _walkMinutes = 10;
  int _quranPages = 1;
  bool _microCharity = false;
  bool _shieldReminder = false;
  final TextEditingController _duaController = TextEditingController();

  @override
  void dispose() {
    _duaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.translate('repentanceFlow')),
      content: SizedBox(
        width: 400,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onContinue,
          onStepCancel: _onBack,
          controlsBuilder: (context, details) {
            return Row(
              children: [
                ElevatedButton(onPressed: details.onStepContinue, child: Text(_currentStep == 2 ? strings.translate('finish') : strings.translate('onboardingContinue'))),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(onPressed: details.onStepCancel, child: Text(strings.translate('cancel'))),
              ],
            );
          },
          steps: [
            Step(
              title: Text('${strings.translate('step')} 1'),
              content: Text(strings.translate('intentionPledge')),
            ),
            Step(
              title: Text('${strings.translate('step')} 2'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: _twoRakah,
                    onChanged: (value) => setState(() => _twoRakah = value ?? false),
                    title: Text(strings.translate('twoRakah')),
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(strings.translate('istighfar'))),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: '$_istighfarCount',
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _istighfarCount = int.tryParse(value) ?? 33,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(strings.translate('walk'))),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: '$_walkMinutes',
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _walkMinutes = int.tryParse(value) ?? 10,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(strings.translate('quran'))),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: '$_quranPages',
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _quranPages = int.tryParse(value) ?? 1,
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    value: _microCharity,
                    onChanged: (value) => setState(() => _microCharity = value ?? false),
                    title: const Text('Micro-charity'),
                  ),
                  SwitchListTile(
                    value: _shieldReminder,
                    onChanged: (value) => setState(() => _shieldReminder = value),
                    title: Text(strings.translate('enableShield')),
                  ),
                ],
              ),
            ),
            Step(
              title: Text('${strings.translate('step')} 3'),
              content: TextField(
                controller: _duaController,
                maxLines: 4,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBack() {
    if (_currentStep == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _onContinue() async {
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
      return;
    }
    final actions = {
      'two_rakah': _twoRakah,
      'istighfar': _istighfarCount,
      'walk_min': _walkMinutes,
      'quran_pages': _quranPages,
      'micro_charity': _microCharity,
      'dua': _duaController.text,
      'shield': _shieldReminder,
    };
    final points = await ref.read(repentanceServiceProvider).completeRepentance(actions);
    if (!mounted) return;
    Navigator.of(context).pop(points);
  }
}
