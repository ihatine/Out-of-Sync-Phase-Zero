# Fix — GameSettingsData.load_saved()

Исправлена причина Parser Error:
`Static function "load_saved()" not found in base "GameSettingsData"`.

Теперь `load_saved()` является обычным методом экземпляра:
`data = GameSettingsData.new()`
`data.load_saved()`

Это убирает зависимость settings_menu.gd от разрешения статического метода через глобальный class_name-кэш Godot.
