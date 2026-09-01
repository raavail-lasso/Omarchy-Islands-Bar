# Islands Bar

A drop-in replacement for the Omarchy status bar where **every widget floats on its own rounded island** instead of sharing one edge-to-edge background.

![Islands Bar](preview.png)

It is a *styling* layer, not a fork of the bar's behaviour. Widget layout, settings, popups, panels, drag-to-reorder, bar-position gestures and the `omarchy bar` / `omarchy plugin` commands all work exactly as they do on the stock bar, because this plugin is the stock bar engine with its painting changed.

---

## Install

```bash
omarchy plugin add https://github.com/<you>/Omarchy-Islands-Bar.git
omarchy bar use raavail.islands
```

To go back at any time:

```bash
omarchy bar use omarchy.bar
```

Removing the plugin also falls back to the built-in bar automatically.

**Requires** Omarchy 4.x with the Quickshell shell (`omarchy-shell`). Developed and tested against Omarchy 4.0.1 and Quickshell 0.3.1.

---

## What it does

### Islands instead of a bar

The bar window paints nothing. Each widget slot paints its own rounded surface, so the wallpaper shows through the gaps between them, at the screen edges, and between the left, centre and right groups.

Island colour is taken from the active theme's `[bar] background`, so **every theme works with no per-theme setup** — switch themes and the islands follow. Corner radius follows Hyprland's `decoration:rounding`, so the bar matches your window corners.

Works in all four bar positions. Vertical bars get the same treatment on the other axis.

### Per-item islands for grouped widgets

Two widgets normally render several things inside one slot. Here each item gets its own island:

- **Workspaces** — every workspace number is a separate island.
- **Indicators** — every indicator is a separate island.

### Indicators that hold still

Two changes to indicator behaviour, both scoped to this bar:

- **Always visible.** Indicators do not wait for hover.
- **They don't move when they activate.** The stock widget keeps two separate blocks — inactive and active — and activating an indicator moves it from one to the other, shifting everything after it. This bar renders one block in a stable order and lets each indicator show its state in place, through opacity.

### A refined tray

- **The reveal chevron only appears when something is actually hidden.** The stock tray shows it whenever the tray has any item at all, including when everything is pinned and there is nothing to reveal.
- **The island tracks the drawer animation.** The stock tray permanently reserves the collapsed drawer's full width and masks it. Here the width follows the reveal, so the island grows and shrinks with the slide, and the pinned icons stay perfectly still while it does.
- **Middle-click any tray icon opens the pin/unpin manager.** With the chevron gone once everything is pinned, right-clicking it is no longer an option, so the gesture lives on the icons themselves.

---

## Configuration

### Geometry

All tunables sit in one block at the top of `Bar.qml`:

| Property | Default | What it controls |
|---|---|---|
| `islandBackground` | `Color.bar.background` | Island fill; follows the theme |
| `islandEdgeMargin` | `Style.space(8)` | Gap from the outermost island to the screen edge |
| `islandPadX` | `Style.space(8)` | Padding inside an island, along the bar |
| `islandInset` | `Style.space(2)` | How far the island sits inside the bar's thickness |
| `islandThickness` | `barSize - islandInset * 2` | Island height (width on a vertical bar) |
| `islandRadius` | `Style.cornerRadius` | Corner radius; follows Hyprland rounding |
| `islandGap` | `Style.space(4)` | Visible gap between two islands |
| `islandStep` | `islandPadX * 2 + islandGap` | Slot spacing that produces that gap |

Each island overhangs its slot by `islandPadX` on both sides, and every layout uses `islandStep`, so the visible gap is `islandGap` everywhere.

### Making a colour theme-settable

`islandBackground` is a plain property, so you can point it at a theme key instead:

```qml
property color islandBackground: {
  var v = Color.pick("bar.island-background", "")
  return v ? Color.flatColor(v, Color.bar.background) : Color.bar.background
}
```

Any theme can then set it in its own `shell.bar.toml`, or you can set it machine-wide in `~/.config/omarchy/shell.toml`:

```toml
[bar]
island-background = "#101418"
```

Omarchy's TOML walker accepts any `[section] key = value`, so no upstream change is needed to introduce a new key.

### Everything else

Bar layout, widget settings, position and transparency are still plain Omarchy config — `~/.config/omarchy/shell.json` and the `omarchy bar` commands. This plugin does not read or write your layout.

---

## Limitations

**Three widgets are forked.** `IslandWorkspaces.qml`, `IslandIndicators.qml` and `IslandTray.qml` are modified copies of Omarchy's own widgets, loaded in place of the registry versions. They will not pick up upstream fixes to those widgets. Everything else — audio, network, power, bluetooth, clock, weather, menu, third-party widgets — uses the shared registry and stays current. Tracking Omarchy 4.0.1.

**Islands can be invisible on themes with flat wallpapers.** If a theme's wallpaper is nearly the same colour as its `[bar] background`, the gaps are there but you cannot see them. `harbordark` is the clearest example: its islands are `#1B1B1B` and its wallpapers are `rgb(28,28,28)` — a difference of about 2/255. Add a faint border to the island surfaces if you want them to read regardless of wallpaper.

**Middle-click on tray icons is repurposed.** It opens the pin/unpin manager instead of calling the tray item's `secondaryActivate()`. Few applications implement that method, but if one you use does, you will lose it.

**Third-party widgets that paint their own background** will render as a box inside a box. Widgets built against the stock bar sometimes draw their own fill rather than letting the bar own it.

**Widgets that reserve width they do not paint** get an oversized island, since the island is sized from the widget's `implicitWidth`. This is what the tray did before it was adapted.

Both of the last two are fixable the same way the bundled widgets were: copy the widget into `widgets/`, adjust it, and add an entry to `localWidgetOverrides` in `Bar.qml`.

---

## How it is put together

```
Bar.qml                        bar engine (modified Omarchy source)
BarModel.js                    layout helpers
manifest.json                  kind: "bar", entry point Bar.qml
widgets/IslandWorkspaces.qml   one island per workspace number
widgets/IslandIndicators.qml   one island per indicator, single-block state
widgets/IslandTray.qml         conditional chevron, animated width, middle-click manager
widgets/TrayModel.js           tray helpers
indicators/*.qml               the six indicator components
```

Three mechanisms in `Bar.qml` do the work:

**`localWidgetOverrides`** maps a widget id to a QML file in this repo. `ModuleSlot` checks it before the shared registry and loads the local file through the url `Loader`. The layout entry still says `omarchy.workspaces` — only this bar swaps what it loads, so nothing in `shell.json` changes and other bars are unaffected.

**`selfIslandWidgets`** lists which of those paint an island per item, so the slot does not also paint one behind them. The tray is overridden but not listed, because it stays a single group island.

**`widgetSettingOverrides`** merges forced widget settings over whatever `shell.json` supplies — it is how the indicators stay revealed here without changing the shared config. It is applied in both places the bar hands settings to a widget: `ModuleSlot.injectProps()` and the in-place `applySettingsDelta()` fast path.

To adapt another widget, copy it into `widgets/`, add the island, and add one line to `localWidgetOverrides`.

---

## Notes for anyone hacking on a bar plugin

Two things cost real time when this was built:

**Cloned bars fail to load as shipped.** `omarchy plugin clone omarchy.bar` produces a bar that never mounts — no bar, no exclusion zone. `Bar.qml` declares `required property omarchyPath / barWidgetRegistry / barConfig`, but the shell loads a third-party bar through `Loader { source: <url> }`, which cannot initialise required properties; only the built-in path uses an inline `Component` that sets them declaratively. This plugin drops `required` and gives them defaults — `configureBar()` assigns all three in `onLoaded` anyway. Symptom: `Required property <name> was not initialized` in the journal.

**The QML compile cache goes stale and silently serves old code.** After editing any file here:

```bash
rm -rf ~/.cache/quickshell/qmlcache && omarchy restart shell
```

Saving alone does not reliably hot-reload a `kind: "bar"` plugin.

Also: `console.log` from a plugin does not reach the journal — use `console.warn` and read it with `journalctl --user --since "-30 seconds"`.

---

## Credits and licence

Derived from the [Omarchy](https://github.com/basecamp/omarchy) shell by Basecamp and the Omarchy contributors, used under the MIT Licence. `Bar.qml`, `BarModel.js`, `widgets/TrayModel.js`, the `indicators/` components and the `widgets/Island*.qml` files are modified copies of Omarchy source.

MIT — see [LICENSE](LICENSE).
