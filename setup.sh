#!/usr/bin/env bash
set -e

echo "▶ Installing required packages..."
REQUIRED=(brightnessctl alsa-utils)
MISSING=()
for p in "${REQUIRED[@]}"; do
    dpkg -s "$p" &>/dev/null || MISSING+=("$p")
done
if ((${#MISSING[@]})); then
    sudo apt update
    sudo apt install -y "${MISSING[@]}"
fi
echo "✓ Packages OK."

echo "▶ Enabling udev rule for brightnessctl..."

# Copy udev rule if it exists in /usr/lib
if [ -f /usr/lib/udev/rules.d/90-brightnessctl.rules ]; then
    sudo install -m 644 /usr/lib/udev/rules.d/90-brightnessctl.rules /etc/udev/rules.d/
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "✓ udev rule installed."
else
    echo "⚠ brightnessctl rule not found in /usr/lib/udev/rules.d/"
fi

# Add user to video group if not already
if ! groups "$USER" | grep -qw video; then
    echo "ℹ Adding $USER to 'video' group for brightness access"
    sudo usermod -aG video "$USER"
    echo "⚠ Please log out and log back in (or reboot) to apply group change."
else
    echo "✓ User already in 'video' group."
fi

# --- Configure GNOME custom keybindings ---
echo "▶ Creating GNOME custom keyboard shortcuts for Wayland..."

SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
KEY="custom-keybindings"

# Define shortcuts (name, command, key, ID suffix)
SHORTCUTS=(
  "Brightness Up:::brightnessctl set +5%:::KP_Add:::custom0"
  "Brightness Down:::brightnessctl set 5%-:::KP_Subtract:::custom1"
  "Volume Up:::amixer -D pulse sset Master 5%+:::KP_Multiply:::custom2"
  "Volume Down:::amixer -D pulse sset Master 5%-:::KP_Divide:::custom3"
)

# Collect all binding paths to set in custom-keybindings array
BINDING_PATHS=()
for ENTRY in "${SHORTCUTS[@]}"; do
  IFS=":::" read -r NAME CMD KEYBIND ID <<< "$ENTRY"
  BINDING="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$ID/"
  BINDING_PATHS+=("'$BINDING'")

  echo "  ↪ $NAME → $KEYBIND"

  gsettings set "$SCHEMA.custom-keybinding:$BINDING" name "$NAME"
  gsettings set "$SCHEMA.custom-keybinding:$BINDING" command "$CMD"
  gsettings set "$SCHEMA.custom-keybinding:$BINDING" binding "$KEYBIND"
done

# Apply the full array of paths
JOINED=$(IFS=, ; echo "[${BINDING_PATHS[*]}]")
gsettings set "$SCHEMA" "$KEY" "$JOINED"

echo "✓ GNOME shortcuts registered."

# --- mpv input.conf --------------------------------------------------
echo "▶ Deploying mpv input.conf..."

mkdir -p "$HOME/.config/mpv"
cp -v mpv/input.conf "$HOME/.config/mpv/"
cp -v mpv/mpv.conf "$HOME/.config/mpv/"

echo "✓ mpv configuration deployed."

echo "🎉  All done!"
