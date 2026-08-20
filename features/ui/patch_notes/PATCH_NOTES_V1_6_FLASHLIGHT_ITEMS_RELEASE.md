# v1.6 — flashlight + item pipeline + release

- Fixed flashlight toggle being processed twice. One F press now switches the light exactly once.
- Kept physical SpotLight3D attached to the flashlight viewmodel, so the actual light originates from the flashlight rather than the camera center.
- Added a generic physical pickup script with a short pickup tween.
- Added a wrench as a second test item with its own grip/attack rotation.
- Dropped items use the correct item definition instead of always becoming a stick.
- Room 02 now contains both the stick and wrench for testing slots, pickup, holster, drop and re-equip.
- Added Windows .exe export instructions to README.md.
