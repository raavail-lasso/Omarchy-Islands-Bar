import QtQuick
import Quickshell.Io
import qs.Ui

BarIndicator {
  id: root

  property string state: "idle"
  property string icon: ""

  // The status follower is the one reader here that stays open for the life of
  // the bar, so it is bounded on three axes rather than one. `fold` caps how
  // many raw bytes can arrive before a line ending does, which is what stops an
  // unterminated line from growing inside the parser; `timeout` caps how long
  // any single follower lives and signals its whole process group when the
  // deadline lands; and the restart below brings the stream back afterwards.
  readonly property int maxLineBytes: 4096
  readonly property int sessionSeconds: 3600
  readonly property int restartDelayMs: 2000
  readonly property int minSessionMs: 5000

  active: state === "recording"
  activeText: icon
  inactiveText: "󰍬"
  activeTooltipText: state
  inactiveTooltipText: "Dictate"

  function update(raw) {
    // `fold` already bounds this, so an over-long line means something upstream
    // of it is misbehaving and the payload can't be trusted either way.
    if (String(raw).length > maxLineBytes) return

    var data = extractData(raw)

    state = String(data.alt || data.class || "idle")
    if (state === "recording") icon = "󰍬"
    else if (state === "transcribing") icon = "󰔟"
    else icon = ""
  }

  Process {
    id: statusProc

    command: ["timeout", "-k", "1s", root.sessionSeconds + "s", "bash", "-c",
              "omarchy-voxtype-status | fold -b -w " + root.maxLineBytes]
    running: true

    stdout: SplitParser {
      onRead: function(data) { root.update(data) }
    }

    property double startedAt: 0

    onStarted: statusProc.startedAt = Date.now()

    // The follower is meant to be up for as long as the bar is, so a stream
    // that ends gets replaced rather than leaving the indicator frozen on its
    // last state. Two exceptions, both of which would otherwise spawn a
    // process every few seconds forever: `omarchy-voxtype-status` prints one
    // idle line and exits when voxtype isn't installed, and a follower that
    // dies immediately on every attempt is broken rather than interrupted. A
    // run our own deadline ended (124) is always worth replacing.
    onExited: function(exitCode) {
      if (exitCode !== 124 && Date.now() - statusProc.startedAt < root.minSessionMs) return

      restartTimer.restart()
    }
  }

  Timer {
    id: restartTimer
    interval: root.restartDelayMs
    onTriggered: if (!statusProc.running) statusProc.running = true
  }

  onPressed: function() {
    if (!root.bar) return
    root.bar.run("omarchy-voxtype-config")
  }
}
