# STEP 6 — TEST STREET / INTERACTION SANDBOX

Rebuilt the playable 3D test level from scratch to eliminate the old spawn-under-map problem.

Added:
- Stable PlayerController spawn at the ground surface.
- Outdoor night test street with perimeter geometry and low walls.
- Functional campfire with animated emissive flame and dynamic warm light.
- Flashlight attached to the player's camera (F).
- Test door using the existing interaction system (E).
- Test table with a pickup stick (E).
- Stick can be equipped and swung with left mouse button.
- Pause menu on ESC with Continue / Settings / Main Menu and visible mouse cursor.
- Crosshair and compact control HUD.

Important:
- No external 3D assets are required. Geometry is generated procedurally by GDScript.
- VSync is disabled by default to avoid the input-lag feeling.
