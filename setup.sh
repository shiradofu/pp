#!/usr/bin/env bash
set -e

echo "▶ Installing required packages..."
REQUIRED=(xbindkeys brightnessctl alsa-utils)
MISSING=()
for p in "${REQUIRED[@]}"; do
    dpkg -s "$p" &>/dev/null || MISSING+=("$p")
done
if ((${#MISSING[@]})); then
    sudo apt update
    sudo apt install -y "${MISSING[@]}"
fi
echo "✓ Packages OK."

echo "▶ Deploying..."

# --- xbindkeys --------------------------------------------------------
cp -v .xbindkeysrc "$HOME"/.xbindkeysrc

mkdir -p "$HOME/.config/autostart"
cp -v xbindkeys.desktop "$HOME/.config/autostart/"

# Restart (or start) xbindkeys for the current session
killall xbindkeys &>/dev/null || true
xbindkeys & disown
echo "✓ xbindkeys deployed."

# --- mpv --------------------------------------------------------------
mkdir -p "$HOME/.config/mpv"
cp -v mpv/input.conf "$HOME/.config/mpv/"
echo "✓ mpv input.conf deployed."

echo "🎉  All done!"
