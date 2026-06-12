# Multiboot USB Toolkit

One stick, many setups: unbloated Windows 11, Ubuntu, Mint, NixOS, Arch with a full setup mode – and 7 ready-made Arch Hyprland shells. **No tools to install, nothing to activate, no commands** – drag files onto the stick and boot.

## Creating the stick

**Step 0 – one time only: put Ventoy on the stick.**
Download [Ventoy](https://www.ventoy.net/en/download.html), unzip, run `Ventoy2Disk.exe` (portable, installs nothing on your PC), select your stick, hit *Install*. ⚠️ This wipes the stick completely. For Secure Boot machines, check *Option → Secure Boot Support* first.

> This step is unavoidable – even a single ISO would need flashing with Rufus/Etcher. The difference: with Ventoy you do it **exactly once**. After that everything is drag & boot, and new ISOs are added without reflashing.

**Step 1: Drag this repo onto the stick.**
On GitHub: *Code → Download ZIP*, unzip, drag the **entire contents** onto the stick. Done – the folder structure (`ventoy/`, `shells/`, `Templates/`) brings everything with it, including the Windows debloat configuration.

**Step 2: Drag ISOs onto the stick.**
Anywhere on the stick works – Ventoy finds them everywhere and lists them in the boot menu. `ISO/Linux/` and `ISO/Shells/` are recommended to keep things tidy.

| System | Download |
|---|---|
| Windows 11 | [microsoft.com/software-download/windows11](https://www.microsoft.com/software-download/windows11) → save as **`Win11.iso`** (stick root or `ISO/Windows/`) |
| Arch Linux | [archlinux.org/download](https://archlinux.org/download/) |
| Ubuntu | [ubuntu.com/download](https://ubuntu.com/download/desktop) |
| Linux Mint | [linuxmint.com/download.php](https://linuxmint.com/download.php) |
| NixOS | [nixos.org/download](https://nixos.org/download/) |
| Omarchy | [omarchy.org](https://omarchy.org/) → ISO |
| ML4W OS | [ml4w.com/os](https://ml4w.com/os/) → Live ISO |

**Lazy option:** Double-click `create-stick.bat` to download all Linux/shell ISOs automatically and sort everything into place (only the Windows ISO must be downloaded manually for legal reasons). No installation, no settings required.

## Using the stick on a target machine

Boot from the stick (boot menu is usually `F12`, `F8` or `ESC`) → Ventoy menu → pick an ISO.

### Windows 11 (unbloated)

Select `Win11.iso` → Ventoy offers `autounattend.xml` (auto-selected after 30 s). [UnattendedWinstall](https://github.com/memstechtips/UnattendedWinstall) removes Edge, OneDrive, Copilot & co. during installation and creates a local account with no Microsoft sign-in.

### Ubuntu / Mint / NixOS / Omarchy / ML4W

Select the ISO, the respective installer starts. Omarchy installs a complete Arch+Hyprland system in ~5 minutes; ML4W can be tried live first, then installed with `sudo install-ml4w-os`.

### Arch setup mode + shell installation (the core feature)

1. Boot the Arch ISO, then in the live system:
   ```bash
   mount /dev/disk/by-label/Ventoy /mnt
   bash /mnt/shells/install-shell.sh
   ```
2. Pick a shell:

   | # | Shell | Style |
   |---|---|---|
   | 1 | **Caelestia** | Material You, Quickshell |
   | 2 | **Ambxst** | Ax-Shell successor, extremely customizable |
   | 3 | **KooL (JaKooLit)** | classic, lots of install options |
   | 4 | **end-4 / illogical-impulse** | transparent, every command shown |
   | 5 | **HyDE** | themes + wallbash (colors from wallpaper) |
   | 6 | plain Arch, no shell | – |

3. `archinstall` starts – **your setup mode**: kernel (`linux`, `linux-zen`, `linux-lts`), disk, encryption, user. Important: profile **Minimal**, user with **sudo**, network **NetworkManager**, do **not reboot** at the end.
4. `reboot`, remove the stick, log in → the chosen shell installer starts automatically.

Wi-Fi in the live system: `iwctl station wlan0 connect "YOUR-WIFI"`

## Known limitations

- **Secure Boot:** On first boot Ventoy asks for one-time key enrollment – or briefly disable Secure Boot in the BIOS.
- **NVIDIA:** KooL and HyDE install drivers automatically; for the others you may need to install `nvidia-dkms` afterwards.
- **Don't edit the shell scripts on Windows** (CRLF line endings break them – `.gitattributes` protects the repo, but not the stick). If you must: set `LF` in the bottom right of VS Code.
- Occasionally update the ISO versions at the top of `setup-stick.ps1` (Omarchy, ML4W, NixOS channel).
- Target machines: UEFI (any PC from the last ~10 years).

## Sources / projects

[Ventoy](https://www.ventoy.net) · [UnattendedWinstall](https://github.com/memstechtips/UnattendedWinstall) (MIT) · [Omarchy](https://omarchy.org) · [ML4W](https://github.com/mylinuxforwork/dotfiles) · [Caelestia](https://github.com/caelestia-dots/caelestia) · [Ambxst](https://github.com/Axenide/Ambxst) · [KooL Arch-Hyprland](https://github.com/LinuxBeginnings/Arch-Hyprland) · [end-4](https://github.com/end-4/dots-hyprland) · [HyDE](https://github.com/HyDE-Project/HyDE)
