// Turn activity, reported to the Android side so DshService's idle timer knows when the
// engine is genuinely quiet. Without it the timer refuses to stop on a guess.

import 'package:flutter/services.dart';

const MethodChannel _runtime = MethodChannel('dsh/runtime');

/// Best effort: widget tests and non-Android builds have no implementation behind it.
Future<void> reportTurnState({
  required bool available,
  required bool settled,
  required int activeTurns,
  required bool pendingWait,
}) async {
  try {
    await _runtime.invokeMethod<void>('turnState', <String, Object?>{
      'available': available,
      'settled': settled,
      'activeTurns': activeTurns,
      'pendingWait': pendingWait,
    });
  } catch (_) {
    // Not wired here: the idle timer keeps its safe default.
  }
}
