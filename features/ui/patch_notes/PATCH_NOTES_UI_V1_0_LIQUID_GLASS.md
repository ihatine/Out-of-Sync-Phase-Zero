# Out of Sync: Phase Zero — UI v1.0 Liquid Glass

This is an incremental replacement patch for the existing project.

## Replace

Extract this archive directly over the project root and allow files to be replaced.

No existing gameplay/movement structure is removed.

## Updated

- `features/ui/main_menu/main_menu.gd`
- `features/ui/main_menu/main_menu.tscn`
- `features/ui/main_menu/GlassBlur.gdshader`
- `features/ui/main_menu/assets/icons/*.svg`
- `features/ui/settings/settings_menu.gd`
- `features/ui/settings/settings_menu.tscn`
- `features/ui/shared/glass_button.gd`
- `core/data/game_settings_data.gd`
- `shaders/ui/menu_ambient.gdshader`
- `shaders/ui/glass_haze.gdshader`
- `shaders/ui/glass_panel.gdshader`
- `shaders/ui/glass_button.gdshader`

## Visual target

- dark wet-glass surface instead of flat blue panels;
- subtle back-buffer blur and distortion;
- glass grain/scratches;
- thin cyan edge reflections;
- soft cold glow around frames;
- independent glass button plates;
- hover scale/light response;
- press compression/light response;
- menu and news remain visible behind the settings overlay;
- settings panel sits in the lower center like the target composition;
- 1920x1080 is the design reference, with responsive scaling for smaller/larger viewports.

## Settings

Four TabContainer pages are generated:

- ГРАФИКА
- ИНТЕРФЕЙС
- УПРАВЛЕНИЕ
- ЗВУК

The settings data is stored in `GameSettingsData` and the existing `InputBootstrap` remains the source of truth for movement actions.

No C#/Java/Python runtime dependency was added: the UI is implemented with native Godot GDScript + CanvasItem shaders so the existing Godot 4.7.2 project does not acquire a second runtime/toolchain.
