#!/usr/bin/env bash
# ==============================================================================
# Revert Display Manager Configuration to SDDM
# Removes systemd TTY autologin overrides and enables sddm.service.
# ==============================================================================
set -e

echo "==> Removing systemd TTY1 autologin override configuration..."
rm -f /etc/systemd/system/getty@tty1.service.d/override.conf

echo "==> Re-enabling sddm.service..."
systemctl daemon-reload
systemctl enable sddm.service

echo "==> Operation completed. SDDM display manager restored."
