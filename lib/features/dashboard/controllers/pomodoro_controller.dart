import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/repo_local.dart';
import '../../../domain/models/pomodoro_settings.dart';

enum PomodoroMode { focus, rest }

class PomodoroState {
  const PomodoroState({
    required this.mode,
    required this.remaining,
    required this.focusDuration,
    required this.restDuration,
    required this.isRunning,
    required this.completedSessions,
    this.lastCompletedMode,
  });

  factory PomodoroState.fromSettings(PomodoroSettings settings) => PomodoroState(
        mode: PomodoroMode.focus,
        remaining: Duration(minutes: settings.focusMinutes),
        focusDuration: Duration(minutes: settings.focusMinutes),
        restDuration: Duration(minutes: settings.breakMinutes),
        isRunning: false,
        completedSessions: 0,
      );

  final PomodoroMode mode;
  final Duration remaining;
  final Duration focusDuration;
  final Duration restDuration;
  final bool isRunning;
  final int completedSessions;
  final PomodoroMode? lastCompletedMode;

  Duration get totalForCurrentMode =>
      mode == PomodoroMode.focus ? focusDuration : restDuration;

  PomodoroState copyWith({
    PomodoroMode? mode,
    Duration? remaining,
    Duration? focusDuration,
    Duration? restDuration,
    bool? isRunning,
    int? completedSessions,
    PomodoroMode? lastCompletedMode,
  }) {
    return PomodoroState(
      mode: mode ?? this.mode,
      remaining: remaining ?? this.remaining,
      focusDuration: focusDuration ?? this.focusDuration,
      restDuration: restDuration ?? this.restDuration,
      isRunning: isRunning ?? this.isRunning,
      completedSessions: completedSessions ?? this.completedSessions,
      lastCompletedMode: lastCompletedMode,
    );
  }
}

class PomodoroController extends StateNotifier<AsyncValue<PomodoroState>> {
  PomodoroController(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final LocalRepository _repository;
  Timer? _timer;

  Future<void> _load() async {
    try {
      final settings = await _repository.loadPomodoroSettings();
      state = AsyncValue.data(PomodoroState.fromSettings(settings));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  PomodoroState? get _value => state.valueOrNull;

  void start() {
    final current = _value;
    if (current == null) return;
    _startForMode(current.mode);
  }

  void startFocus() => _startForMode(PomodoroMode.focus);

  void startRest() => _startForMode(PomodoroMode.rest);

  void pause() {
    final current = _value;
    if (current == null) return;
    _timer?.cancel();
    state = AsyncValue.data(current.copyWith(isRunning: false, lastCompletedMode: current.lastCompletedMode));
  }

  void toggle() {
    final current = _value;
    if (current == null) return;
    if (current.isRunning) {
      pause();
    } else {
      _startForMode(current.mode);
    }
  }

  void reset() {
    final current = _value;
    if (current == null) return;
    _timer?.cancel();
    final resetDuration = current.mode == PomodoroMode.focus ? current.focusDuration : current.restDuration;
    state = AsyncValue.data(
      current.copyWith(
        remaining: resetDuration,
        isRunning: false,
        lastCompletedMode: null,
      ),
    );
  }

  Future<void> updateDurations({int? focusMinutes, int? restMinutes}) async {
    final current = _value;
    if (current == null) return;
    final newFocus = Duration(minutes: focusMinutes ?? current.focusDuration.inMinutes);
    final newRest = Duration(minutes: restMinutes ?? current.restDuration.inMinutes);
    final updated = current.copyWith(
      focusDuration: newFocus,
      restDuration: newRest,
      remaining: current.mode == PomodoroMode.focus ? newFocus : newRest,
      lastCompletedMode: null,
    );
    state = AsyncValue.data(updated);
    await _repository.savePomodoroSettings(
      PomodoroSettings(
        focusMinutes: newFocus.inMinutes,
        breakMinutes: newRest.inMinutes,
      ),
    );
  }

  void _startForMode(PomodoroMode mode) {
    final current = _value;
    if (current == null) return;
    _timer?.cancel();
    final duration = mode == PomodoroMode.focus ? current.focusDuration : current.restDuration;
    state = AsyncValue.data(
      current.copyWith(
        mode: mode,
        remaining: duration,
        isRunning: true,
        lastCompletedMode: null,
      ),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    final current = _value;
    if (current == null) {
      timer.cancel();
      return;
    }
    final newRemaining = current.remaining - const Duration(seconds: 1);
    if (newRemaining.inSeconds <= 0) {
      timer.cancel();
      _handleCompletion(current);
    } else {
      state = AsyncValue.data(
        current.copyWith(
          remaining: newRemaining,
          isRunning: true,
          lastCompletedMode: null,
        ),
      );
    }
  }

  void _handleCompletion(PomodoroState completedState) {
    if (completedState.mode == PomodoroMode.focus) {
      final next = completedState.copyWith(
        mode: PomodoroMode.rest,
        remaining: completedState.restDuration,
        isRunning: false,
        completedSessions: completedState.completedSessions + 1,
        lastCompletedMode: PomodoroMode.focus,
      );
      state = AsyncValue.data(next);
    } else {
      final next = completedState.copyWith(
        mode: PomodoroMode.focus,
        remaining: completedState.focusDuration,
        isRunning: false,
        lastCompletedMode: PomodoroMode.rest,
      );
      state = AsyncValue.data(next);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
