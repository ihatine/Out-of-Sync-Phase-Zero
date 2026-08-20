# Out of Sync v1.5 — Room Transitions

Added a second procedural test room and a working door-to-scene transition.

## Added
- `features/world/rooms/test_room_02.gd`
- `features/world/rooms/test_room_02.tscn`

## Extended
- `features/interaction/door.gd` now supports `target_scene` and performs a short transition after opening.
- `features/movement/scenes/game_world.gd` now points its test door to Room 02.

## Test
1. Start the game from the main menu.
2. Enter the test street.
3. Aim at the door and press `E`.
4. Room 02 should load with a safe player spawn above the floor.
5. Use the opposite door to return to the street.
