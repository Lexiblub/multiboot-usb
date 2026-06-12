#!/usr/bin/env bash
# ============================================================
# install-shell.sh
# Run inside the Arch Linux LIVE ISO (booted from this Ventoy stick):
#
#   mount /dev/disk/by-label/Ventoy /mnt
#   bash /mnt/shells/install-shell.sh
#
# Flow:
#   1. Pick a shell/rice
#   2. archinstall runs (your "setup mode": kernel, disk, user...)
#   3. This script injects the rice installer into the new installation
#   4. After reboot + first login the shell installs itself
# ============================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="/mnt/archinstall"

if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Please run as root (you are root automatically in the Arch live ISO)."
    exit 1
fi

if ! command -v archinstall >/dev/null 2>&1; then
    echo "[!] 'archinstall' not found. Are you in the official Arch live ISO?"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/firstboot-rice.sh" ]; then
    echo "[!] firstboot-rice.sh is missing next to this script."
    exit 1
fi

echo "=============================================="
echo "   Install Arch + a ready-made Hyprland shell"
echo "=============================================="
echo ""
echo "  1) Caelestia        (Material You, Quickshell)"
echo "  2) Ambxst           (Ax-Shell successor, Quickshell)"
echo "  3) KooL / JaKooLit  (classic, lots of options)"
echo "  4) end-4 / illogical-impulse"
echo "  5) HyDE             (themes, wallbash)"
echo "  6) Plain Arch, no shell"
echo ""
read -rp "Choice [1-6]: " num

case "$num" in
    1) CHOICE="caelestia" ;;
    2) CHOICE="ambxst" ;;
    3) CHOICE="kool" ;;
    4) CHOICE="end4" ;;
    5) CHOICE="hyde" ;;
    6) CHOICE="none" ;;
    *) echo "[!] Invalid choice."; exit 1 ;;
esac

echo ""
echo "Selected: $CHOICE"
echo ""
echo "archinstall starts now. IMPORTANT:"
echo "  - Profile:        choose 'Minimal' (the shell brings everything itself)"
echo "  - User account:   create a user, answer the sudo/superuser question with YES"
echo "  - Network:        choose 'NetworkManager'"
echo "  - Do NOT reboot at the end ('no' on the reboot question / chroot: no)"
echo ""
read -rp "Press Enter to start archinstall..." _

archinstall

if [ ! -d "$TARGET" ]; then
    echo "[!] $TARGET not found. Did archinstall finish (without rebooting)?"
    exit 1
fi

if [ "$CHOICE" = "none" ]; then
    echo "[+] Done. You can type 'reboot' now."
    exit 0
fi

# --- Find the first regular user in the target system ---
USERNAME=""
for d in "$TARGET"/home/*/; do
    [ -d "$d" ] || continue
    USERNAME="$(basename "$d")"
    break
done

if [ -z "$USERNAME" ]; then
    echo "[!] No user found in $TARGET/home. Did you create a user in archinstall?"
    exit 1
fi
echo "[+] Target user: $USERNAME"

USERHOME="$TARGET/home/$USERNAME"

# --- Base tools into the target system (git, base-devel for AUR builds) ---
echo "[*] Installing base packages into the new system..."
arch-chroot "$TARGET" pacman -S --needed --noconfirm git base-devel curl wget || {
    echo "[!] Package installation failed (network?)."
    exit 1
}

# --- Set up the first-boot installer ---
cp "$SCRIPT_DIR/firstboot-rice.sh" "$USERHOME/firstboot-rice.sh"
echo "$CHOICE" > "$USERHOME/.rice-choice"

touch "$USERHOME/.bash_profile"
if ! grep -q "RICE-FIRSTBOOT-BEGIN" "$USERHOME/.bash_profile"; then
    cat >> "$USERHOME/.bash_profile" <<'HOOK'
# RICE-FIRSTBOOT-BEGIN
if [ -f "$HOME/.rice-choice" ]; then
    bash "$HOME/firstboot-rice.sh"
fi
# RICE-FIRSTBOOT-END
HOOK
fi

arch-chroot "$TARGET" chown "$USERNAME:$USERNAME" \
    "/home/$USERNAME/firstboot-rice.sh" \
    "/home/$USERNAME/.rice-choice" \
    "/home/$USERNAME/.bash_profile"
chmod +x "$USERHOME/firstboot-rice.sh"

echo ""
echo "=============================================="
echo "  All set!"
echo "  1. Type 'reboot' and remove the stick"
echo "  2. Log in as '$USERNAME' (console/TTY)"
echo "  3. The $CHOICE installer starts automatically"
echo "=============================================="
