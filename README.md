# Out of Sync: Phase Zero — v1.8.0

Патч исправляет дисплей и настройки графики, добавляет рабочую мини-карту и базовую звуковую систему.

Проверять после распаковки:
1. Настройки → Графика → fullscreen / разрешение / профиль / яркость / гамма / VSync / motion blur.
2. Настройки → Интерфейс → HUD / мини-карта / информация.
3. Одиночная игра → шаги, фонарик, предметы, двери и удары.
4. ROOM 02 → HUD и мини-карта должны сохраняться после перехода.

# Multiplayer / Radmin VPN

Host: use the Radmin VPN IPv4 address and UDP port 1766. Client: enter that same Radmin IPv4 address and port in the network menu. Allow the Godot game executable / UDP 1766 through the Windows Firewall on the host. No Internet port forwarding is required when both players are connected to the same Radmin VPN network.


## v1.8.2
- Multiplayer remote body/hand/flashlight presentation fix.
- Targeted door transitions; no group scene change.
- Permanent right-side global chat.
- Tab-scoped defaults in Settings.
