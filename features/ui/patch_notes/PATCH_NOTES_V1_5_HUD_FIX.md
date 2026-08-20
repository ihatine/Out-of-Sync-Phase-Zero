# v1.5.1 // HUD crash fix

- Fixed the single-player crash caused by calling `set_script()` on a null Inventory HUD reference.
- Inventory HUD is now optional and instantiated from its script safely with `script.new()`.
- Added a small 1/2/3 inventory-slot HUD showing the current test item.
- If the HUD script is missing or fails to load, gameplay continues and only a warning is emitted.
