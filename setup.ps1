[CmdletBinding()]
param(
    [switch] $IncludeCommunityGhostty,
    [switch] $SkipPackages,
    [switch] $SkipWSL,
    [string] $WSLDistribution = 'Ubuntu'
)

$ErrorActionPreference = 'Stop'
$dotfilesRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path $HOME 'dotfiles' }

if (-not (Test-Path -LiteralPath (Join-Path $dotfilesRoot '.git'))) {
    $dotfilesRoot = Join-Path $HOME 'dotfiles'
    if (-not (Test-Path -LiteralPath $dotfilesRoot)) {
        git clone https://github.com/allends/dotfiles $dotfilesRoot
    }
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'Winget is required. Install or update App Installer from Microsoft Store.'
}

function Install-OrUpgradeWingetPackage {
    param([Parameter(Mandatory)] [string] $Id)

    $installed = winget list --id $Id --exact --accept-source-agreements 2>$null | Out-String
    if ($installed -match [regex]::Escape($Id)) {
        winget upgrade --id $Id --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
    }
    else {
        winget install --id $Id --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
    }
}

$packages = @(
    'Oven-sh.Bun',
    'Git.Git',
    'GitHub.cli',
    'Microsoft.PowerShell',
    'Microsoft.WindowsTerminal',
    'Starship.Starship',
    'ajeetdsouza.zoxide',
    'eza-community.eza',
    'sharkdp.bat',
    'junegunn.fzf',
    'sharkdp.fd',
    'BurntSushi.ripgrep.MSVC',
    'Helix.Helix',
    'jdx.mise',
    'JesseDuffield.lazygit'
)

if (-not $SkipPackages) {
    foreach ($package in $packages) {
        Write-Host "==> Ensuring $package"
        Install-OrUpgradeWingetPackage -Id $package
    }

    if ($IncludeCommunityGhostty) {
        Write-Warning 'Installing winghostty, an unofficial community Windows port of Ghostty.'
        Install-OrUpgradeWingetPackage -Id 'AmanThanvi.winghostty'
    }
}

# Make newly installed portable Winget commands visible in this process.
$wingetLinks = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
if (Test-Path -LiteralPath $wingetLinks) {
    $env:PATH = "$wingetLinks;$env:PATH"
}
$bunBin = Join-Path $HOME '.bun\bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$userPathParts = @($userPath -split ';' | Where-Object { $_ })
$additionalUserPaths = @($bunBin)
$winghosttyBin = Join-Path $env:ProgramFiles 'winghostty'
if (Test-Path -LiteralPath $winghosttyBin) {
    $additionalUserPaths += $winghosttyBin
}
foreach ($path in $additionalUserPaths) {
    if ($path -notin $userPathParts) {
        $userPathParts += $path
    }
    if ($env:PATH -notlike "*$path*") {
        $env:PATH = "$path;$env:PATH"
    }
}
[Environment]::SetEnvironmentVariable('Path', ($userPathParts -join ';'), 'User')

function Copy-Dotfile {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination
    )

    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    if (Test-Path -LiteralPath $Destination) {
        $current = Get-Content -LiteralPath $Destination -Raw -ErrorAction SilentlyContinue
        $incoming = Get-Content -LiteralPath $Source -Raw -ErrorAction SilentlyContinue
        if ($current -ne $incoming) {
            Copy-Item -LiteralPath $Destination -Destination "$Destination.backup" -Force
        }
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

$windowsRoot = Join-Path $dotfilesRoot 'windows'
Copy-Dotfile `
    -Source (Join-Path $windowsRoot 'powershell\Microsoft.PowerShell_profile.ps1') `
    -Destination $PROFILE.CurrentUserAllHosts

# PowerShell loads the all-hosts profile above before this older, host-specific
# profile. Preserve any legacy file once, then remove it so it cannot override
# the dotfiles profile or initialize retired prompt tooling.
$legacyPowerShellProfile = $PROFILE.CurrentUserCurrentHost
if ((Test-Path -LiteralPath $legacyPowerShellProfile) -and
    $legacyPowerShellProfile -ne $PROFILE.CurrentUserAllHosts) {
    $legacyBackup = "$legacyPowerShellProfile.legacy.backup"
    if (-not (Test-Path -LiteralPath $legacyBackup)) {
        Copy-Item -LiteralPath $legacyPowerShellProfile -Destination $legacyBackup -Force
    }
    Remove-Item -LiteralPath $legacyPowerShellProfile -Force
}
Copy-Dotfile `
    -Source (Join-Path $windowsRoot 'helix\config.toml') `
    -Destination (Join-Path $env:APPDATA 'helix\config.toml')
Copy-Dotfile `
    -Source (Join-Path $windowsRoot 'helix\languages.toml') `
    -Destination (Join-Path $env:APPDATA 'helix\languages.toml')
Copy-Dotfile `
    -Source (Join-Path $windowsRoot 'ghostty\config.ghostty') `
    -Destination (Join-Path $env:LOCALAPPDATA 'winghostty\config.ghostty')
Copy-Dotfile `
    -Source (Join-Path $dotfilesRoot 'git\.config\git\ignore') `
    -Destination (Join-Path $HOME '.config\git\ignore')

# The community port registers itself as "winghostty". Add a discoverable
# Ghostty shortcut while retaining the package-owned shortcut and uninstaller.
$winghosttyExe = Join-Path $env:ProgramFiles 'winghostty\winghostty.exe'
if (Test-Path -LiteralPath $winghosttyExe) {
    $startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    $shortcutPath = Join-Path $startMenu 'Ghostty.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $winghosttyExe
    $shortcut.WorkingDirectory = Join-Path $HOME 'Documents'
    $shortcut.Description = 'Ghostty terminal (Ubuntu on WSL2)'
    $shortcut.IconLocation = "$winghosttyExe,0"
    $shortcut.Save()
}

# Windows-safe Git settings. SSH signing remains disabled unless configured locally.
git config --global user.name 'Allen Davis-Swing'
git config --global user.email 'allen.davisswing@gmail.com'
git config --global core.editor hx
git config --global core.excludesFile "$HOME/.config/git/ignore"
git config --global push.autoSetupRemote true
git config --global commit.gpgsign false
git config --global --unset-all gpg.ssh.program 2>$null
git config --global alias.st 'status --short --branch'
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.br branch
git config --global alias.unstage 'reset HEAD --'

$bun = Get-Command bun -ErrorAction SilentlyContinue
if ($bun) {
    & $bun.Source add --global typescript typescript-language-server
}
else {
    Write-Warning 'Bun was installed but is not available until a new terminal is opened.'
}

if (-not $SkipWSL) {
    $wslNames = @(wsl.exe --list --quiet 2>$null | ForEach-Object { $_.Trim([char]0).Trim() } | Where-Object { $_ })
    if ($WSLDistribution -in $wslNames) {
        wsl.exe --set-default-version 2 | Out-Null
        wsl.exe --set-version $WSLDistribution 2 | Out-Null
        wsl.exe --set-default $WSLDistribution | Out-Null

        $wslSetupWindows = Join-Path $windowsRoot 'wsl\setup.sh'
        $wslSetupLinux = (wsl.exe -d $WSLDistribution --exec wslpath -a $wslSetupWindows).Trim()
        wsl.exe -d $WSLDistribution --user root --exec bash $wslSetupLinux --system
        wsl.exe -d $WSLDistribution --exec bash $wslSetupLinux --user $dotfilesRoot

        $linuxUser = (wsl.exe -d $WSLDistribution --exec id -un).Trim()
        wsl.exe -d $WSLDistribution --exec test -x /home/linuxbrew/.linuxbrew/bin/fish
        if ($LASTEXITCODE -eq 0) {
            wsl.exe -d $WSLDistribution --user root --exec usermod -s /home/linuxbrew/.linuxbrew/bin/fish $linuxUser
        }
        else {
            Write-Warning 'Fish was not installed successfully in WSL; leaving the existing default shell unchanged.'
        }
    }
    else {
        Write-Warning "WSL distribution '$WSLDistribution' is not installed. Run 'wsl --install -d $WSLDistribution', restart, then rerun setup.ps1."
    }
}

Write-Host ''
Write-Host '==> Windows setup complete. Open a new PowerShell terminal to load the profile.'
