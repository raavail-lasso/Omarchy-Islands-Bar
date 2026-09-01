import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Workspaces, but every number sits on its own island. Island geometry comes
// from the host bar when it exposes the tokens, with sane fallbacks so this
// still renders if some other bar loads it.
BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  readonly property color islandBackground: bar && bar.islandBackground !== undefined ? bar.islandBackground : Color.bar.background
  readonly property int islandPad: bar && bar.islandPadX !== undefined ? bar.islandPadX : Style.space(8)
  readonly property int islandGap: bar && bar.islandGap !== undefined ? bar.islandGap : Style.space(4)
  readonly property int islandThickness: bar && bar.islandThickness !== undefined ? bar.islandThickness : root.barSize
  readonly property int islandRadius: bar && bar.islandRadius !== undefined ? bar.islandRadius : Style.cornerRadius

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  implicitWidth: grid.implicitWidth
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    columns: root.vertical ? 1 : root.workspaceIds().length
    // Each island overhangs its button by islandPad on both sides, so the
    // spacing has to clear two overhangs plus the gap we want to see.
    columnSpacing: root.vertical ? 0 : root.islandPad * 2 + root.islandGap
    rowSpacing: root.vertical ? root.islandPad * 2 + root.islandGap : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        id: cell
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        implicitWidth: button.implicitWidth
        implicitHeight: button.implicitHeight

        BorderSurface {
          z: -1
          anchors.centerIn: parent
          width: root.vertical ? root.islandThickness : parent.width + root.islandPad * 2
          height: root.vertical ? parent.height + root.islandPad * 2 : root.islandThickness
          color: root.islandBackground
          radius: root.islandRadius
        }

        WidgetButton {
          id: button
          bar: root.bar
          text: cell.focused ? "󱓻" : (cell.modelData === 10 ? "0" : String(cell.modelData))
          opacity: cell.occupied || cell.focused ? 1 : 0.5
          horizontalMargin: 6
          verticalPadding: 6
          fixedWidth: root.vertical ? root.barSize : Style.space(20)
          fixedHeight: root.barSize
          onPressed: function() { root.focusWorkspace(cell.modelData) }
        }
      }
    }
  }
}
