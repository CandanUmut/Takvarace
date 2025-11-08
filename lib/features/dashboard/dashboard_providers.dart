import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/models/zikr_state.dart';
import 'controllers/pomodoro_controller.dart';
import 'controllers/zikr_controller.dart';

final zikrControllerProvider = StateNotifierProvider<ZikrController, AsyncValue<ZikrState>>(
  (ref) => ZikrController(ref.watch(localRepositoryProvider)),
);

final pomodoroControllerProvider =
    StateNotifierProvider<PomodoroController, AsyncValue<PomodoroState>>(
  (ref) => PomodoroController(ref.watch(localRepositoryProvider)),
);
