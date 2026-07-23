# Bootstrap script for allends/dotfiles on Windows (Zed config only)
#
# Symlink creation requires either Developer Mode (Settings > System > For developers)
# or an elevated (Administrator) PowerShell.
#
# Usage:
#   git clone https://github.com/allends/dotfiles $HOME\dotfiles
#   powershell -ExecutionPolicy Bypass -File $HOME\dotfiles\setup-windows.ps1

$ErrorActionPreference = "Stop"

$dotfiles = Join-Path $HOME "dotfiles"

if (-not (Test-Path $dotfiles)) {
    Write-Host "==> Cloning dotfiles..."
    git clone https://github.com/allends/dotfiles $dotfiles
}

$zedSource = Join-Path $dotfiles "zed\.config\zed"
$zedTarget = Join-Path $env:APPDATA "Zed"

New-Item -ItemType Directory -Force -Path $zedTarget | Out-Null

foreach ($file in @("settings.json", "keymap.json")) {
    $link = Join-Path $zedTarget $file
    $source = Join-Path $zedSource $file

    $existing = Get-Item $link -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -eq "SymbolicLink") {
            Write-Host "==> $file already linked, skipping"
            continue
        }
        $backup = "$link.backup"
        Write-Host "==> Backing up existing $file to $backup"
        Move-Item -Force $link $backup
    }

    Write-Host "==> Linking $link -> $source"
    New-Item -ItemType SymbolicLink -Path $link -Target $source | Out-Null
}

Write-Host ""
Write-Host "==> Done. Restart Zed to pick up the shared config."
Write-Host "==> To pull future changes: git -C $dotfiles pull"
