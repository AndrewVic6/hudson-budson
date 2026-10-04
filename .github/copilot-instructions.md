# Hudson Budson coaching instructions
The user is a beginner making a funny 3D school zombie game. Use plain English.
Read PROJECT_STATUS.md and the relevant existing scripts before editing.
Target Godot 4.4.1 Standard with GDScript and Compatibility rendering.
Keep changes inside this project. Make one small requested gameplay change at
a time. Do not redesign the project, install plug-ins, or add dependencies.
Confirm a recoverable checkpoint exists before code edits. Never delete the
only working copy. Explain the changed behavior in three short bullets.
Give the user one concrete playtest and one creative tuning choice.
Do not assume code works merely because it parses. Do not claim visual testing
unless actually performed. Ask for the exact error or screenshot when needed.
Remember: CharacterBody3D movement and gravity are scripted; use velocity for
zombie knockback, not RigidBody3D-only impulse APIs. Main builds the scene at
runtime. Keep spawned physics actors PROCESS_MODE_PAUSABLE.
Update PROJECT_STATUS.md at the end of a completed task. No new features unless
requested. Never bury the beginner in several alternative implementation paths.
