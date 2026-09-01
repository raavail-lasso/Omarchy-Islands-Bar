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

`~/.local/bin/islands-bar` drives the whole loop and is the easiest way to run
it. It deliberately lives outside this repo: it is developer tooling, and a
script that cleans a tree, updates a plugin and restarts a service reads like
an installer to the plugin marketplace's security scan.

**1. See your change live** — no commit needed:

```bash
islands-bar sync
```

The shell runs with its file watcher off, so a change that doesn't show up
isn't necessarily broken. `islands-bar sync --restart` restarts the shell and
puts the new files in front of you.

**2. Once you're happy**, commit and push from here as normal.

**3. Deploy the published commit.** This throws away the synced files,
fast-forwards the live copy and restarts the shell:

```bash
islands-bar deploy
```

It refuses to start unless your work is committed and pushed, because it
deploys what is on the remote rather than what is on your disk, and it checks
where the live copy actually landed rather than trusting the update's exit
status. The bar flips back to the old look partway through. That's expected.

### Doing it by hand

The same four steps without the wrapper:

```bash
# 1. sync
rsync -a --delete --exclude='.git/' \
  ~/Projects/Omarchy-Islands-Bar/ \
  ~/.config/omarchy/plugins/raavail.islands-bar/

# 2. commit and push

# 3. tidy up the live copy
git -C ~/.config/omarchy/plugins/raavail.islands-bar checkout .
git -C ~/.config/omarchy/plugins/raavail.islands-bar clean -fd

# 4. pull the published version
omarchy plugin update raavail.islands-bar
```

### Four things not to get wrong

- Keep `-C ...` in step 3. Without it, run from this folder, those commands
  delete the work you just did. `clean -fd` makes that mistake unrecoverable,
  which is the reason the wrapper bakes the path in.
- Never add `--delete-excluded` to step 1. It would wipe the live copy's git
  folder.
- Do step 3 before step 4. The update refuses to run if the live copy has
  leftover files sitting in it.
- `checkout .` alone isn't enough. It restores files the sync overwrote but
  leaves ones it added, and an untracked leftover blocks the update even when
  its contents match the committed file exactly. Hence `clean -fd`.
