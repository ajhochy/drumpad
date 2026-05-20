#!/bin/bash
# One-time Pi setup: creates autostart desktop entry
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cat > /etc/xdg/autostart/edrum.desktop <<EOF
[Desktop Entry]
Type=Application
Name=EDrum Lessons
Exec=$SCRIPT_DIR/start.sh
EOF

echo "Autostart configured. Reboot to activate."
