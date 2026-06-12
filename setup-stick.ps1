# ============================================================
# setup-stick.ps1
# Fills a Ventoy-prepared USB stick with:
#   - folder structure + Ventoy configuration
#   - UnattendedWinstall autounattend.xml (Windows debloat)
#   - Linux ISOs (Arch, Ubuntu, Mint, NixOS)
#   - shell ISOs (Omarchy, ML4W)
#   - Arch shell installer scripts (Caelestia, Ambxst, KooL, end-4, HyDE)
#
# BEFORE: install Ventoy on the stick using Ventoy2Disk.exe!
#         https://www.ventoy.net/en/download.html
#
# Usage:  double-click create-stick.bat
#         (or: .\setup-stick.ps1 -Drive E:)
# Run again = update (existing ISOs are skipped,
# use -Force to re-download them).
# ============================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,                 # e.g. "E:"
    [switch]$SkipLinux,             # skip Ubuntu/Mint/NixOS downloads
    [switch]$SkipShells,            # skip Omarchy/ML4W ISO downloads
    [switch]$Force                  # overwrite existing downloads
)

$ErrorActionPreference = "Stop"

# ----- Versions / URLs (update here when needed) -----
$OmarchyIsoUrl  = "https://iso.omarchy.org/omarchy-3.8.2.iso"
$Ml4wIsoUrl     = "https://ml4w.com/iso/ml4w-os/ml4w-os-2.12.0-x86_64.iso"
$NixosChannel   = "nixos-25.11"   # see https://channels.nixos.org
$ArchIsoUrl     = "https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"
$UnattendXmlUrl = "https://raw.githubusercontent.com/memstechtips/UnattendedWinstall/main/autounattend.xml"

$Drive = $Drive.TrimEnd('\')
if (-not (Test-Path "$Drive\")) {
    Write-Error "Drive $Drive not found. Stick plugged in? Ventoy installed?"
}

$vol = Get-Volume -DriveLetter $Drive.TrimEnd(':') -ErrorAction SilentlyContinue
if ($vol -and $vol.FileSystemLabel -ne "Ventoy") {
    Write-Warning "Drive $Drive is labeled '$($vol.FileSystemLabel)' instead of 'Ventoy'."
    Write-Warning "If Ventoy is not installed yet: run Ventoy2Disk.exe first!"
    $answer = Read-Host "Continue anyway? (y/n)"
    if ($answer -ne "y") { exit 1 }
}

function Get-RemoteText([string]$Url) {
    return (Invoke-WebRequest -Uri $Url -UseBasicParsing).Content
}

function Save-File([string]$Url, [string]$Dest) {
    if ((Test-Path $Dest) -and (-not $Force)) {
        Write-Host "  [skip] $(Split-Path $Dest -Leaf) already exists" -ForegroundColor DarkGray
        return
    }
    Write-Host "  [down] $Url" -ForegroundColor Cyan
    try {
        Start-BitsTransfer -Source $Url -Destination $Dest -DisplayName (Split-Path $Dest -Leaf)
    } catch {
        Write-Host "  [info] BITS failed, falling back to Invoke-WebRequest..." -ForegroundColor DarkGray
        Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
    }
}

# ----- 1. Folder structure -----
Write-Host "`n== Creating folder structure ==" -ForegroundColor Green
$dirs = "ISO\Windows", "ISO\Linux", "ISO\Shells", "Templates", "ventoy", "shells"
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path "$Drive\$d" -Force | Out-Null
}

# ----- 2. Copy toolkit files (entire repo, ISOs excluded) -----
Write-Host "`n== Copying configuration & scripts ==" -ForegroundColor Green
Copy-Item -Path "$PSScriptRoot\*" -Destination "$Drive\" -Recurse -Force -Exclude "*.iso"

# Move files to the locations Ventoy expects,
# in case the repo is laid out flat (without folder structure):
$moves = @{
    "ventoy.json"       = "ventoy\ventoy.json"
    "install-shell.sh"  = "shells\install-shell.sh"
    "firstboot-rice.sh" = "shells\firstboot-rice.sh"
    "autounattend.xml"  = "Templates\autounattend.xml"
}
foreach ($name in $moves.Keys) {
    if (Test-Path "$Drive\$name") {
        Move-Item "$Drive\$name" "$Drive\$($moves[$name])" -Force
    }
}
Write-Host "  [ok] configuration and scripts are in place"

# ----- 3. Windows debloat answer file -----
Write-Host "`n== UnattendedWinstall (Windows debloat) ==" -ForegroundColor Green
if (Test-Path "$Drive\Templates\autounattend.xml") {
    Write-Host "  [ok] autounattend.xml already present (from the repo)"
} else {
    Save-File $UnattendXmlUrl "$Drive\Templates\autounattend.xml"
}

# ----- 4. Linux ISOs -----
if (-not $SkipLinux) {
    Write-Host "`n== Linux ISOs ==" -ForegroundColor Green

    # Arch (always current under /latest/)
    Save-File $ArchIsoUrl "$Drive\ISO\Linux\archlinux-x86_64.iso"

    # Ubuntu LTS (detect current file name from SHA256SUMS)
    try {
        $sums = Get-RemoteText "https://releases.ubuntu.com/noble/SHA256SUMS"
        if ($sums -match 'ubuntu-[\d\.]+-desktop-amd64\.iso') {
            $ubuntuIso = $Matches[0]
            Save-File "https://releases.ubuntu.com/noble/$ubuntuIso" "$Drive\ISO\Linux\$ubuntuIso"
        }
    } catch { Write-Warning "Could not determine Ubuntu ISO: $_" }

    # Linux Mint (latest stable version from the kernel.org mirror)
    try {
        $base = "https://mirrors.edge.kernel.org/linuxmint/stable/"
        $idx  = Get-RemoteText $base
        $versions = [regex]::Matches($idx, 'href="(\d+(?:\.\d+)?)/"') |
                    ForEach-Object { $_.Groups[1].Value } |
                    Sort-Object { if ($_ -match '\.') { [version]$_ } else { [version]"$_.0" } } -Descending
        if ($versions) {
            $v = $versions[0]
            $list = Get-RemoteText "$base$v/"
            if ($list -match "linuxmint-$v-cinnamon-64bit(?:-v\d+)?\.iso") {
                $mintIso = $Matches[0]
                Save-File "$base$v/$mintIso" "$Drive\ISO\Linux\$mintIso"
            }
        }
    } catch { Write-Warning "Could not determine Mint ISO: $_" }

    # NixOS (GNOME installer of the chosen channel)
    try {
        Save-File "https://channels.nixos.org/$NixosChannel/latest-nixos-gnome-x86_64-linux.iso" `
                  "$Drive\ISO\Linux\nixos-gnome-x86_64.iso"
    } catch { Write-Warning "NixOS ISO failed (check channel '$NixosChannel'): $_" }
}

# ----- 5. Shell ISOs (ready-made Arch setups with their own installer) -----
if (-not $SkipShells) {
    Write-Host "`n== Shell ISOs (Omarchy, ML4W) ==" -ForegroundColor Green
    Save-File $OmarchyIsoUrl "$Drive\ISO\Shells\$(Split-Path $OmarchyIsoUrl -Leaf)"
    Save-File $Ml4wIsoUrl    "$Drive\ISO\Shells\$(Split-Path $Ml4wIsoUrl -Leaf)"
}

# ----- 6. Check for the Windows ISO -----
Write-Host "`n== Windows 11 ==" -ForegroundColor Green
if ((Test-Path "$Drive\Win11.iso") -or (Test-Path "$Drive\ISO\Windows\Win11.iso")) {
    Write-Host "  [ok] Win11.iso present"
} else {
    Write-Host "  [!] Win11.iso missing (cannot be redistributed/auto-downloaded for legal reasons)." -ForegroundColor Yellow
    Write-Host "      1. Open https://www.microsoft.com/software-download/windows11"
    Write-Host "      2. Download 'Windows 11 (multi-edition ISO)'"
    Write-Host "      3. Save as $Drive\Win11.iso (or $Drive\ISO\Windows\Win11.iso)"
}

Write-Host "`n== Done! ==" -ForegroundColor Green
Write-Host "Eject the stick, boot the target machine from it via UEFI (boot menu usually F12/F8/ESC)."
Write-Host "Usage details: README.md on the stick."
