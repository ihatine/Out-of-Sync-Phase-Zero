# v1.2 — Input, flashlight origin, smooth viewmodel and item pipeline

## Input/settings
- Mouse sensitivity 0.10–5.00 is converted to a useful radians-per-pixel range instead of clamping almost the entire slider to one value.
- Remapped keys use `physical_keycode` consistently.
- Remapping and sensitivity changes are saved immediately, while Apply still writes the complete settings set.
- Player startup no longer adds default bindings on top of existing user bindings.

## Console errors
- Fixed the repeated `is_inside_tree()` Transform3D error in `drop_item()`: the dropped body is added to the world before its global transform is assigned.

## Flashlight
- SpotLights now live under the flashlight viewmodel mounts, so the actual light origin is the flashlight lens rather than the camera center.
- Right hand owns the flashlight when no item is equipped.
- Picking up an item moves the flashlight to the left hand.
- Holstering/dropping returns the flashlight to the right hand.

## Viewmodel
- Added smoothed mouse sway, movement bob and softer interpolation.
- Equip/holster uses short eased transitions instead of instant visibility changes.

## Item pipeline
- The stick is treated as an inventory item in slot 1.
- Pickup -> inventory slot -> right-hand grip -> attack animation.
- `Q` holsters the item but keeps it in the slot.
- `G` drops it as a physical `RigidBody3D` with a small throw impulse.
- Dropped sticks can be picked up again.
- Added `ItemData` as the foundation for per-item grip/equip/holster/attack profiles.
