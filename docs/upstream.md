# Upstream tracking

Islands Bar is a restyle of the Omarchy bar, not a rewrite. The look it changes
is not reachable from outside the bar, so the bar and a handful of its
indicators are copied into this repository and adjusted. Copies go stale, and a
stale copy can miss a fix that upstream has already made, so this page records
what is copied, what state it is aligned with, and how that stays true.

## Aligned with

**Omarchy 4.0.2.** Update this line whenever the files below are rebased.

## What is copied

Run `tools/upstream-diff` to compare these against the Omarchy installed on
this machine (`$OMARCHY_PATH`, or `/usr/share/omarchy`). It only reads and
prints, and exits non-zero when a verbatim file has drifted.

### Verbatim

Copied unchanged. Any difference means upstream moved and this plugin has not
caught up yet.

| File |
| --- |
| `BarModel.js` |
| `indicators/Dnd.qml` |
| `indicators/NightLight.qml` |
| `indicators/ScreenRecording.qml` |
| `indicators/StayAwake.qml` |

### Adapted

Copied and then changed on purpose. Differences are expected, so a rebase here
means reading the upstream diff and porting what applies, rather than
overwriting.

| File | Why it diverges |
| --- | --- |
| `Bar.qml` | Islands layout and geometry; bounded output collection for custom command modules and the two internal probes. |
| `indicators/Dictation.qml` | Bounded line framing, session deadline and restart policy on the status follower. |
| `indicators/Reminder.qml` | Bounded output collection and a deadline on the reminder read. |

### Original

`widgets/IslandIndicators.qml`, `widgets/IslandTray.qml`,
`widgets/IslandWorkspaces.qml` and `BarModel.js`'s island helpers are written
for this plugin and have no upstream counterpart.

## Policy

1. On every Omarchy release, run `tools/upstream-diff`.
2. Verbatim files that drifted are re-copied from upstream.
3. Adapted files are diffed by hand, and upstream changes are ported into the
   local version. Correctness and security fixes are ported; styling changes
   are ported only where they do not fight the islands layout.
4. Security-relevant upstream fixes are released here within **7 days** of the
   upstream release.
5. The *Aligned with* version above is updated in the same commit as the
   rebase, so the recorded baseline is never older than the code.
