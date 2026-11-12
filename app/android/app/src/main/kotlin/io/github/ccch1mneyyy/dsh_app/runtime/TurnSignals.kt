package io.github.ccch1mneyyy.dsh_app.runtime

/**
 * Per-session turn state, as reported by the Dart side (M2 of the idle-stop work).
 *
 * Kotlin has no notion of a "turn": only the engine's SSE session stream knows. Until
 * RuntimePlugin feeds this object, [available] stays false and the idle timer refuses to stop
 * the engine on a guess — a guess can kill a long background turn or a handoff that is
 * waiting for the person.
 */
internal object TurnSignals {

    /** True once the Dart side reports turn state at all. */
    @Volatile
    var available: Boolean = false

    /** Turns currently streaming across every session (including subagents). */
    @Volatile
    var activeTurns: Int = 0

    /**
     * True once the report describes a settled picture: the first report after a (re)connect
     * is a guess, and mux does not replay which sessions were already streaming.
     */
    @Volatile
    var settled: Boolean = false

    /** Wall clock of the last report. A Dart side that stopped reporting is not "idle". */
    @Volatile
    var lastReportMs: Long = 0L

    /** Something waits on the person: a handoff, an approval, a decision card. */
    @Volatile
    var pendingWait: Boolean = false

    /** Opt-in for stopping on the long window without turn state (设置 › 后台). Default false. */
    @Volatile
    var stopWithoutSignal: Boolean = false
}
