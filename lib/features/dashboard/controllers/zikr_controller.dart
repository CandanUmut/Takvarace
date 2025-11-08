import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/repo_local.dart';
import '../../../domain/models/zikr_state.dart';

class ZikrController extends StateNotifier<AsyncValue<ZikrState>> {
  ZikrController(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final LocalRepository _repository;

  Future<void> _load() async {
    try {
      final state = await _repository.loadZikrState();
      this.state = AsyncValue.data(state);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> increment([int delta = 1]) async {
    final current = state.valueOrNull ?? ZikrState.initial();
    final updated = current.copyWith(
      count: (current.count + delta).clamp(0, current.goal).toInt(),
    );
    await _persist(updated);
  }

  Future<void> decrement([int delta = 1]) async {
    final current = state.valueOrNull ?? ZikrState.initial();
    final updated = current.copyWith(count: (current.count - delta).clamp(0, current.goal).toInt());
    await _persist(updated);
  }

  Future<void> reset() async {
    final current = state.valueOrNull ?? ZikrState.initial();
    await _persist(current.copyWith(count: 0));
  }

  Future<void> updateSettings({String? phrase, int? goal}) async {
    final current = state.valueOrNull ?? ZikrState.initial();
    final sanitizedGoal = (goal ?? current.goal).clamp(1, 10000).toInt();
    final cleanedPhrase = phrase == null
        ? current.phrase
        : phrase.trim().isEmpty
            ? current.phrase
            : phrase.trim();
    final updated = current.copyWith(
      phrase: cleanedPhrase,
      goal: sanitizedGoal,
      count: current.count.clamp(0, sanitizedGoal).toInt(),
    );
    await _persist(updated);
  }

  Future<void> _persist(ZikrState stateToPersist) async {
    state = AsyncValue.data(stateToPersist);
    await _repository.saveZikrState(stateToPersist);
  }
}
