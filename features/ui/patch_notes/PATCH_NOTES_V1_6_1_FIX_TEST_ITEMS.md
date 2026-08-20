# v1.6.1 — Test item inheritance fix + flashlight off fix

- Fixed `test_item.gd`: removed an invalid nested function declaration that caused Godot to fail parsing the base class.
- Pickup completion is now handled by a normal `_finish_pickup()` method through `Callable.bind()`.
- `test_stick.gd` and `test_wrench.gd` can now safely inherit from `test_item.gd`.
- Flashlight synchronization now explicitly sets `light_energy` to `0.0` while disabled, so F reliably turns the actual light off.
- Right/left flashlight energy is restored when the active hand changes.
