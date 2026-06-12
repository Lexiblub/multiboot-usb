#!/usr/bin/env bash
# ============================================================
# firstboot-rice.sh
# Runs on the FIRST login of the freshly installed Arch system.
# Installs the chosen Hyprland shell (see ~/.rice-choice).
# Set up automatically by install-shell.sh.
# ============================================================

CHOICE_FILE="$HOME/.rice-choice"

if [ ! -f "$CHOICE_FILE" ]; then
    exit 0
fi

CHOICE="$(cat "$CHOICE_FILE")"

echo "=============================================="
echo "  Rice installer: $CHOICE"
echo "=============================================="

# --- Wait for network (max 60s) ---
echo "[*] Waiting for internet connection..."
for i in $(seq 1 12); do
    if ping -c 1 -W 2 archlinux.org >/dev/null 2>&1; then
        break
    fi
    if [ "$i" -eq 12 ]; then
        echo "[!] No internet. Connect (e.g. 'nmtui') and log in again."
        exit 1
    fi
    sleep 5
done
echo "[+] Network ok."

set -e

case "$CHOICE" in
    caelestia)
        # https://github.com/caelestia-dots/caelestia
        sudo pacman -S --needed --noconfirm fish git
        git clone https://github.com/caelestia-dots/caelestia.git "$HOME/.local/share/caelestia"
        "$HOME/.local/share/caelestia/install.fish"
        ;;
    ambxst)
        # https://github.com/Axenide/Ambxst  (prerequisite: Hyprland)
        sudo pacman -S --needed --noconfirm hyprland git curl
        curl -L get.axeni.de/ambxst | sh
        # Reload PATH, then enable the Hyprland integration
        export PATH="$HOME/.local/bin:$PATH"
        ambxst install hyprland || echo "[!] Please run 'ambxst install hyprland' manually after login."
        ;;
    kool)
        # KooL / JaKooLit Arch-Hyprland (maintained by LinuxBeginnings since 03/2026)
        git clone --depth=1 https://github.com/LinuxBeginnings/Arch-Hyprland.git "$HOME/Arch-Hyprland" \
            || git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git "$HOME/Arch-Hyprland"
        cd "$HOME/Arch-Hyprland"
        chmod +x install.sh
        ./install.sh
        ;;
    end4)
        # end-4 / illogical-impulse  https://github.com/end-4/dots-hyprland
        bash <(curl -s https://ii.clsty.link/get)
        ;;
    hyde)
        # HyDE  https://github.com/HyDE-Project/HyDE
        sudo pacman -S --needed --noconfirm git base-devel
        git clone --depth 1 https://github.com/HyDE-Project/HyDE "$HOME/HyDE"
        cd "$HOME/HyDE/Scripts"
        ./install.sh
        ;;
    *)
        echo "[!] Unknown choice: $CHOICE"
        exit 1
        ;;
esac

# --- Cleanup: remove the hook so this only runs once ---
rm -f "$CHOICE_FILE"
sed -i '/# RICE-FIRSTBOOT-BEGIN/,/# RICE-FIRSTBOOT-END/d' "$HOME/.bash_profile" 2>/dev/null || true

echo ""
echo "=============================================="
echo "  Done! Please reboot (sudo reboot)."
echo "=============================================="
