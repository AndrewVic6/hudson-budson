# Hudson Budson: Locker Raid

A first-person zombie comedy from Cool Uncle Andy Games. Shared project for Andrew and Hudson.

## Play
Open `project.godot` in Godot Standard and press **F5**. The supplied baseline was tested with Godot **4.4.1**, using the Compatibility renderer. The school is built at runtime; an empty editor viewport is normal.

Walk toward locker 101 on your left, aim at it, and press **C**. Grab the bat, search for the hall pass, and escape. See [all controls](docs/PLAYING.txt).

## Work together
- `main` holds the agreed working game.
- `visual/hallway-polish` is reserved for the next art pass.
- Start a branch for one change, play it in Godot, then open a pull request explaining what changed and what you tested.
- Review and merge after playing. Pull the latest main before starting again.
- Avoid both editing the same script or scene at once.

GitHub stores and reviews changes; each person plays their local copy in Godot. Branch protections have not been configured. The `baseline-first-person` tag marks the starting version. Do not force-push over shared work.

## First collaboration
Hudson chooses one improvement and describes how it should feel. Andrew helps keep its scope small. Try it together before accepting it. A good first task: compare three bat-knockback values.

## Project map
`scripts/main.gd` builds the school and controls UI and game flow. `player.gd` controls movement and aiming. `locker.gd` handles opening. `inventory.gd` defines loot. `art.gd` builds characters and items. `zombie.gd` handles enemies.

Read [PROJECT_STATUS.md](PROJECT_STATUS.md) before a session and update it when finished.

## Validation
The inherited baseline report records **43 checks passed**. These have not been rerun during repository preparation. Run with a graphical display:

```sh
godot --path . --script res://tests/smoke_test.gd
```

The suite tests mouse capture, so do not use `--headless`. See [the inherited report](docs/BASELINE-TEST-RESULTS.txt).

This is a short single-player prototype, without multiplayer, persistent saves or controller/touch support. The next art pass is planned, not implemented in this baseline.
