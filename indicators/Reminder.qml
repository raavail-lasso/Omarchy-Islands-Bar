import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarIndicator {
  id: root

  property int reminderCount: 0
  property string tooltip: ""

  // `omarchy-reminder show --json` answers with one small JSON object, so a
  // run that floods stdout or never exits is broken rather than busy. Both
  // are bounded here: the collector reads incrementally and stops the run at
  // the byte cap, and `timeout` puts a hard deadline on the process itself.
  readonly property int maxOutputBytes: 16384
  readonly property int readTimeoutSeconds: 5

  active: reminderCount > 0
  activeText: "󰢌"
  inactiveText: "󰢌"
  activeTooltipText: tooltip
  inactiveTooltipText: tooltip

  function refresh() {
    // A read still in flight also means this tick has nothing to add, so let
    // it finish instead of stacking a second process on top of it.
    if (jsonProc.running) return

    jsonProc.output = ""
    jsonProc.truncated = false
    jsonProc.running = true
  }

  function openReminderFlow() {
    Quickshell.execDetached(["omarchy-reminder", "-i"])
  }

  function clear() {
    reminderCount = 0
    tooltip = ""
  }

  function update(raw) {
    var data = extractData(raw)
    reminderCount = Number(data.count || 0)
    tooltip = String(data.tooltip || "")
  }

  Component.onCompleted: refresh()

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() { root.refresh() }
  }

  Process {
    id: jsonProc

    // `timeout` runs the command in its own process group and signals the
    // whole group, so nothing is left behind when a run is cut short. -k
    // follows the deadline's TERM with a KILL for anything that ignores it.
    command: ["timeout", "-k", "1s", root.readTimeoutSeconds + "s",
              "omarchy-reminder", "show", "--json"]

    // What this run has printed so far, and whether we cut it off. refresh()
    // resets both before every start.
    property string output: ""
    property bool truncated: false

    stdout: StdioCollector {
      // Deliberately not waitForEnd: that buffers the entire stream, however
      // large, before handing any of it over. Reading chunk by chunk lets us
      // stop the moment a run passes the cap.
      waitForEnd: false
      onDataChanged: {
        if (jsonProc.truncated) return

        if (text.length > root.maxOutputBytes) {
          // Over the cap the JSON is cut mid-object and unparseable anyway.
          // Drop what we have and end the run; `running = false` sends TERM,
          // which timeout passes on to the command.
          jsonProc.truncated = true
          jsonProc.output = ""
          jsonProc.running = false
        } else {
          jsonProc.output = text
        }
      }
    }

    // Anything other than a clean exit — a failed command, the deadline
    // (timeout reports 124), or our own cap — leaves nothing worth showing.
    onExited: function(exitCode) {
      if (exitCode === 0 && !jsonProc.truncated) root.update(jsonProc.output)
      else root.clear()
    }
  }

  onPressed: function() {
    if (root.reminderCount > 0) Quickshell.execDetached(["omarchy-reminder", "show"])
    else root.openReminderFlow()
  }
}
