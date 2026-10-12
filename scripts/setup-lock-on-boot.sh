#!/usr/bin/env bash
# ==============================================================================
# Setup Lock-on-Boot (Direct Hyprland + Quickshell Session Initialization)
# Replaces display managers with a lightweight TTY1 autologin sequence.
# ==============================================================================
set -e

USER_NAME="${SUDO_USER:-$(id -un)}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
[ -z "$USER_HOME" ] && USER_HOME="$HOME"

echo "==> [1/3] Configuring Hyprland startup sequence in ~/.zprofile..."
if [ ! -f "$USER_HOME/.zprofile" ] || ! grep -q "exec Hyprland" "$USER_HOME/.zprofile"; then
    cat << 'EOF' >> "$USER_HOME/.zprofile"

# Launch Hyprland on TTY1 login session
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec Hyprland
fi
EOF
    chown "$USER_NAME:$USER_NAME" "$USER_HOME/.zprofile"
    chmod 644 "$USER_HOME/.zprofile"
    echo "    [OK] ~/.zprofile configured successfully."
else
    echo "    [OK] ~/.zprofile already contains Hyprland autostart entry."
fi

echo "==> [2/3] Configuring systemd TTY1 autologin override for user '$USER_NAME'..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF
echo "    [OK] /etc/systemd/system/getty@tty1.service.d/override.conf generated."

echo "==> [3/3] Disabling display manager (SDDM)..."
systemctl disable sddm.service
systemctl daemon-reload
echo "    [OK] SDDM service disabled."

echo ""
echo "=============================================================================="
echo "Configuration completed successfully."
echo "Startup sequence:"
echo "1. System autologins to TTY1 and executes Hyprland."
echo "2. Quickshell initializes and locks the session via native lockscreen."
echo "3. Session unlocks upon PAM authentication."
echo "=============================================================================="
