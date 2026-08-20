# Step 3.1 — Input latency + settings apply fix

Replace these files directly over the project:

- `core/data/game_settings_data.gd`
- `features/ui/settings/settings_menu.gd`
- `features/movement/player.gd`

Changes:

- VSync defaults to OFF and is explicitly disabled at runtime.
- Mouse accumulated input is disabled.
- FPS mouse look no longer uses smoothing/lerp, removing the artificial one-frame/low-pass feeling.
- Mouse sensitivity is loaded from saved settings.
- Settings persist in `user://out_of_sync_settings.cfg`.
- Apply saves display/audio/input settings without closing the settings screen.
- Resolution/fullscreen/VSync/audio/keybinds are actually applied.
- Reset restores defaults and saves them.
- Settings key remapping now uses the same action names as the Player Controller: move_forward/move_backward/move_left/move_right.
