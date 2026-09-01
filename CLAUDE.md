# Islands Bar

A replacement for the Omarchy status bar. Instead of one long bar stretching
across the screen, every widget sits on its own small rounded "island" with the
wallpaper showing through the gaps.

It only changes how the bar *looks*, not how it works. Widgets, settings,
popups and dragging things around all behave exactly like the normal bar,
because this is the normal bar with its paint job swapped out.

Island colour comes from whatever theme is active, so themes just work with no
setup. Corner roundness follows the same setting your windows use.

`Bar.qml` is the bar itself. `widgets/` holds three widgets that were copied
and adjusted so each item gets its own island. `indicators/` holds the small
status icons.

## Dev loop

Edit files here in `~/Projects/Omarchy-Islands-Bar`. Nothing changes on screen
until you copy them across.

**1. See your change live** — no commit needed. The bar redraws by itself the
moment the files land:

```bash
rsync -a --delete --exclude='.git/' \
  ~/Projects/Omarchy-Islands-Bar/ \
  ~/.config/omarchy/plugins/raavail.islands-bar/
```

**2. Once you're happy**, commit and push from here as normal.

**3. Tidy up the live copy**, throwing away the loose files from step 1:

```bash
git -C ~/.config/omarchy/plugins/raavail.islands-bar checkout .
```

The bar briefly flips back to the old look here. That's expected.

**4. Pull the published version** so the live copy matches a real commit:

```bash
omarchy plugin update raavail.islands-bar
```

### Three things not to get wrong

- Keep `-C ...` in step 3. Without it, run from this folder, that command
  deletes the work you just did.
- Never add `--delete-excluded` to step 1. It would wipe the live copy's git
  folder.
- Do step 3 before step 4. The update refuses to run if the live copy has
  leftover files sitting in it.
