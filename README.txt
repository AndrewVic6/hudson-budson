HUDSON BUDSON: HALL PASS
A small playable Godot starter made for the Hudson Budson Challenge.

START
1. Download Godot Standard (not .NET) from https://godotengine.org/download/
   Tested in Godot 4.4.1. Use that version for the closest match.
   Official archive: https://godotengine.org/download/archive/4.4.1-stable/
2. Extract the entire starter-kit ZIP. Do not run from inside the ZIP.
3. Open Godot > Import > choose HudsonBudson/project.godot > Import & Edit.
4. Press F5 (some laptops need Fn+F5), or click Run Project.
   The school is generated when you play; an empty editor view is expected.
5. Click the game window. WASD moves; Q hooks; hold E to reel; F swings.

CONTROLS
WASD: move relative to the fixed camera. Walk toward a zombie to face it.
Shift: sprint. Space: jump. Q or right-click: hook/release the nearest zombie
in front of you. E: hold to pull. F or left-click: swing the cafeteria tray.
T: embarrass Hudson (+25). At 100, a six-second speed boost activates.
Tab or Escape: pause and open the Tuning Lab. R: restart the whole run.
Defeat all three zombies, then step onto the green EXIT pad.

FIRST EXPERIMENT
Press Tab. Try Hudson speed 10 and zombie speed 0.5. Press Tab to play.
Sliders only last this run. R restores the defaults in scripts/settings.gd.
To keep favorite values, stop the game and edit scripts/settings.gd.

FILES
scenes/Main.tscn: entry scene.
scripts/main.gd: school geometry, fishing, tray hit detection, UI, game flow.
scripts/player.gd: movement, jump, health and input.
scripts/zombie.gd: chase, pull movement, health and knockback.
scripts/settings.gd: easy-to-change starting values.
PROJECT_STATUS.md: current project state for your AI helper.
.github/copilot-instructions.md: instructions for Copilot in this project.
tests/smoke_test.gd: repeatable gameplay checks.

RECOVERY
R only restarts gameplay; it cannot undo code changes.
Before changing code, close Godot and copy the whole HudsonBudson folder.
Name copies HudsonBudson-01-movement, HudsonBudson-02-fishing, and so on.
If stuck, keep your broken folder, extract Checkpoints/00-Clean-Starter.zip
to a NEW folder, and import that project.godot. Never overwrite your only copy.

LIMITS
This is a small prototype, not a finished game. Fixed camera, placeholder
block characters, straight-line zombie chasing, no audio, no save-game system.
The original NPC Ben, trust system, complex school and falling props are future
missions. No paid assets, add-ons, account or internet required to play after
Godot is installed. Desktop keyboard/mouse required; this is not an Android app.

Built and checked October 3, 2026 UTC. See TEST_RESULTS.txt in the kit.
