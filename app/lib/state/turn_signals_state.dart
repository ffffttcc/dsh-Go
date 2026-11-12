// Which conversations are running right now, and whether something waits on the person.
// Pushed to the Android side so the local engine can be stopped once the app is idle
// (runtime/DshService.kt idle timer; TurnSignals is the receiving end).

import 'dart:async';

import 'package:dsh_client/dsh_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../runtime/turn_signals_channel.dart';
import 'connection_state.dart';
import 'session_attention_state.dart';

/// Alive from launch (app.dart), whether or not the pet, the overlay or a chat page is up.
final turnSignalsProvider = Provider<TurnSignalsController>((ref) {
  final controller = TurnSignalsController();
  ref.listen(localConnectionProvider, (_, next) => controller.attach(next.value?.client),
      fireImmediately: true);
  ref.listen(pendingSourceProvider, (_, next) => controller.pendingSource(next),
      fireImmediately: true);
  ref.onDispose(controller.dispose);
  return controller;
});

class TurnSignalsController {
  /// How long a fresh connection is allowed to look idle before its empty set is believed.
  /// After a reconnect the mux replays requests but not which sessions were already
  /// streaming, so the first report is a guess.
  static const settleGrace = Duration(seconds: 10);

  StreamSubscription<HostEvent>? _sub;
  final Set<String> _running = {};
  PendingSource? _pending;
  Timer? _settle;
  bool _settled = false;

  /// One host connection at a time: the local engine. A new client replaces the old one.
  void attach(DshClient? client) {
    unawaited(_sub?.cancel());
    _sub = null;
    _running.clear();
    _restartSettle();
    if (client == null) {
      _push(available: false);
      return;
    }
    _sub = client.hostEvents.listen(_onEvent, onError: (Object _) {});
    _push();
  }

  void pendingSource(PendingSource? source) {
    _pending = source;
    _push();
  }

  void _onEvent(HostEvent event) {
    switch (event) {
      case SessionStatusEvent(:final sessionId, :final running):
        // Subagents report through the same edge; they count too.
        _settleNow();
        if (running) {
          _running.add(sessionId);
        } else {
          _running.remove(sessionId);
        }
        _push();
      case HostReadyEvent():
        // A new generation: what was running before is no longer known.
        _running.clear();
        _restartSettle();
        _push();
      default:
        break;
    }
  }

  void _restartSettle() {
    _settled = false;
    _settle?.cancel();
    _settle = Timer(settleGrace, () {
      _settled = true;
      _push();
    });
  }

  void _settleNow() {
    _settled = true;
    _settle?.cancel();
    _settle = null;
  }

  void _push({bool available = true}) {
    unawaited(reportTurnState(
      available: available,
      settled: _settled,
      activeTurns: _running.length,
      pendingWait: _pending?.pending().isNotEmpty ?? false,
    ));
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
    _settle?.cancel();
    _settle = null;
  }
}
