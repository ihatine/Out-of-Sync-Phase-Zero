# v0.6 — Incremental UI / transition patch

Base: previous clean v472 build. Existing systems are preserved.

## Changed
- Added canonical `res://features/ui/main_menu/main_menu.tscn`.
- Updated `project.godot` to launch that scene.
- Main menu now has working Singleplayer transition.
- Host button starts ENet on port 12345, then enters GameWorld.
- Settings button opens an overlay scene.
- Settings Back button closes the overlay.
- ESC is consumed before deferred scene transition.
- ESC returns to the canonical main menu.
- PlayerView owns Sprite2D facing presentation.
- Facing is driven by `PlayerData.last_facing_direction`.
- Added future asset folders for world/horror content.

## Preserved
- PlayerData resource.
- MovementSystem.
- viewport-size dependency injection.
- screen clamping.
- existing core/features/scenes organization.

## Test checklist
1. Main menu opens.
2. Singleplayer enters GameWorld.
3. WASD moves the player.
4. A/left turns the player left.
5. D/right turns the player right.
6. Releasing movement preserves facing.
7. ESC returns safely to main menu.
8. Host enters GameWorld after ENet initialization.
9. Settings opens and Back returns to main menu.


## v0.7 Input safety patch
- Added `core/systems/input_bootstrap.gd`.
- Registers WASD and arrow-key actions automatically at GameWorld startup.
- `MovementSystem` now checks the InputMap before `Input.get_vector()`.
- Missing actions now produce `Vector2.ZERO` instead of runtime error spam.
- Preserved last-facing-direction logic and `Sprite2D.flip_h`.
- Added optional `shaders/horror/glitch_overlay.gdshader` asset; it is not forced onto the scene, so existing visuals remain stable.
