# Out of Sync: Phase Zero — v0.8 UI Glass Pass

Инкрементальное обновление поверх v0.7. Существующие системы не удалены.

## Изменения
- Добавлен `features/ui/shared/glass_button.gd` — переиспользуемая кнопка Liquid Glass.
- Добавлены hover/focus/press анимации через Tween.
- Добавлены полупрозрачные стеклянные StyleBoxFlat, границы и мягкая тень.
- Добавлен анимированный холодный фон `shaders/ui/menu_ambient.gdshader`.
- Добавлена тонкая атмосферная дымка `shaders/ui/glass_haze.gdshader`.
- Главная панель получила стеклянную многослойную поверхность.
- Логика меню, переходы, ENet и Input Bootstrap не менялись.

## Визуальная цель
PS1 horror + modern liquid glass: холодный графит, голубоватые отражения, мягкая глубина, без яркого sci-fi неона.
