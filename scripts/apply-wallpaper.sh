#!/usr/bin/env bash
# ===================================================
# Apply Wallpaper Sync (Matugen, Kitty, SDDM & Cache)
# (Visual display is natively managed by Quickshell)
# ===================================================

target="$1"
prev="$2"

if [ ! -f "$target" ]; then
    exit 1
fi

# 1. Record current wallpaper cache
mkdir -p "$HOME/.cache"
echo "$target" > "$HOME/.cache/current-wallpaper"

# 2. Generate Matugen Material You colors
if command -v matugen >/dev/null 2>&1; then
    matugen image "$target" --prefer saturation >/dev/null 2>&1
fi

# 3. Reload Hyprland and Kitty colors
hyprctl reload >/dev/null 2>&1
if command -v kitty >/dev/null 2>&1 && [ -f "$HOME/.config/kitty/generated/matugen.conf" ]; then
    kitty @ set-colors --all "$HOME/.config/kitty/generated/matugen.conf" >/dev/null 2>&1
fi

# 4. Sync SDDM lockscreen/login wallpaper
SDDM_SYNC="$HOME/.config/sddm/themes/matugen/scripts/sync-wallpaper.sh"
if [ -x "$SDDM_SYNC" ]; then
    "$SDDM_SYNC" "$target" >/dev/null 2>&1
fi

# 5. Notification
notify-send "Wallpaper Changed" "$(basename "$target")"
