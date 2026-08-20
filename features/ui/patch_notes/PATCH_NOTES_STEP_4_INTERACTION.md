# STEP 4 — INTERACTION SYSTEM

Direct replacement/addition patch. Extract over the current project with overwrite.

Added:
- features/interaction/interactable.gd
- features/interaction/interaction_controller.gd
- features/interaction/interaction_prompt.gd
- features/interaction/door.gd

Replaced:
- features/movement/player.gd

Controls:
- E = interact
- F = flashlight

The interaction controller creates the camera RayCast3D and Liquid Glass prompt at runtime.
No manual scene tree changes are required for the player side.

For a usable door: create an AnimatableBody3D, assign features/interaction/door.gd, add MeshInstance3D + CollisionShape3D as children.
