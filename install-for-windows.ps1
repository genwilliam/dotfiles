param(
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ZshPackageUrl = 'https://mirror.msys2.org/msys/x86_64/zsh-5.9-5-x86_64.pkg.tar.zst'
$DotfilesRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$WindowsPackageManager = ''

trap {
    $line = $_.InvocationInfo.ScriptLineNumber
    $command = $_.InvocationInfo.Line
    throw "ERROR: Command failed at line $line: $command`n$($_.Exception.Message)"
}

function Write-Log {
    param([string]$Message)
    Write-Host "`n==> $Message"
}

function Fail {
    param([string]$Message)
    throw "ERROR: $Message"
}

function Test-Windows {
    return $env:OS -eq 'Windows_NT'
}

function Get-WindowsPackageManager {
    if ($WindowsPackageManager) {
        return $WindowsPackageManager
    }

    foreach ($manager in @('winget', 'choco', 'scoop')) {
        if (Get-Command $manager -ErrorAction SilentlyContinue) {
            $script:WindowsPackageManager = $manager
            return $manager
        }
    }

    return $null
}

function Ensure-Windows {
    if (-not (Test-Windows)) {
        Fail 'This script is for Windows only.'
    }
}

function Install-Git {
    $manager = Get-WindowsPackageManager
    if (-not $manager) {
        Fail 'git is required, but winget/choco/scoop was not found.'
    }

    switch ($manager) {
        'winget' {
            Write-Log 'Installing git via winget'
            winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements
        }
        'choco' {
            Write-Log 'Installing git via choco'
            choco install -y git
        }
        'scoop' {
            Write-Log 'Installing git via scoop'
            scoop install git
        }
    }
}

function Ensure-Git {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Log 'git already installed'
        return
    }

    Install-Git

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Fail 'git installation finished, but git was still not found.'
    }
}

function Get-GitInstallPath {
    $defaultPath = 'C:\Program Files\Git'

    if (Test-Path $defaultPath) {
        return $defaultPath
    }

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        Fail 'Unable to resolve git path.'
    }

    $probe = Split-Path -Parent $gitCommand.Source
    for ($i = 0; $i -lt 5; $i++) {
        if ((Test-Path (Join-Path $probe 'usr')) -and (Test-Path (Join-Path $probe 'bin\bash.exe'))) {
            return $probe
        }
        $parent = Split-Path -Parent $probe
        if ($parent -eq $probe) {
            break
        }
        $probe = $parent
    }

    Fail 'Cannot determine Git installation directory. Expected C:\Program Files\Git.'
}

function Install-Zstd {
    if (Get-Command zstd -ErrorAction SilentlyContinue) {
        return
    }

    $manager = Get-WindowsPackageManager
    if (-not $manager) {
        Fail 'zstd is required to decompress .zst, but winget/choco/scoop was not found.'
    }

    switch ($manager) {
        'winget' {
            Write-Log 'Installing zstd via winget'
            winget install --id Facebook.Zstandard -e --accept-package-agreements --accept-source-agreements
        }
        'choco' {
            Write-Log 'Installing zstd via choco'
            choco install -y zstandard
        }
        'scoop' {
            Write-Log 'Installing zstd via scoop'
            scoop install zstd
        }
    }

    if (-not (Get-Command zstd -ErrorAction SilentlyContinue)) {
        Fail 'zstd is required to decompress .zst. Please install zstd and run again.'
    }
}

function Merge-DirectoryNoOverwrite {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    $sourceRoot = (Resolve-Path $Source).Path
    $copied = 0
    $skipped = 0

    Get-ChildItem -LiteralPath $sourceRoot -Recurse -Force | ForEach-Object {
        $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\\')
        $target = Join-Path $Destination $relative

        if ($_.PSIsContainer) {
            if (-not (Test-Path $target)) {
                New-Item -ItemType Directory -Path $target -Force | Out-Null
            }
            return
        }

        $targetDir = Split-Path -Parent $target
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        if (Test-Path $target) {
            $skipped++
        }
        else {
            Copy-Item -LiteralPath $_.FullName -Destination $target
            $copied++
        }
    }

    Write-Log "Merge completed. Copied: $copied, Skipped(existing): $skipped"
}

function Ensure-Zsh {
    param(
        [string]$GitInstallPath,
        [switch]$AssumeYes
    )

    $zshExe = Join-Path $GitInstallPath 'usr\bin\zsh.exe'
    if (Test-Path $zshExe) {
        Write-Log 'zsh already installed'
        return
    }

    if ($AssumeYes) {
        $confirm = 'y'
    }
    else {
        Write-Host 'zsh not found. Download and install now? [y/N]: ' -NoNewline
        $confirm = Read-Host
    }

    if ($confirm -notmatch '^[Yy]$') {
        Fail 'zsh installation not confirmed.'
    }

    Install-Zstd

    $tarCmd = (Get-Command tar -ErrorAction SilentlyContinue)
    if (-not $tarCmd) {
        Fail 'tar was not found. Please ensure tar is available in PATH.'
    }

    $tmpRoot = Join-Path $env:TEMP ("dotfiles-zsh-" + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $tmpRoot -Force

    $zstFile = Join-Path $tmpRoot 'zsh.pkg.tar.zst'
    $tarFile = Join-Path $tmpRoot 'zsh.pkg.tar'
    $extractDir = Join-Path $tmpRoot 'extract'
    $null = New-Item -ItemType Directory -Path $extractDir -Force

    Write-Log 'Downloading zsh package'
    Invoke-WebRequest -Uri $ZshPackageUrl -OutFile $zstFile

    Write-Log 'Decompress #1: .zst -> .tar'
    zstd -d -f $zstFile -o $tarFile | Out-Null

    if (-not (Test-Path $tarFile)) {
        Fail 'First decompression failed: .tar file not found.'
    }

    Write-Log 'Decompress #2: .tar -> files'
    tar -xf $tarFile -C $extractDir

    if (-not (Test-Path (Join-Path $extractDir 'usr'))) {
        Fail 'Unexpected package layout: usr directory not found after extraction.'
    }

    Write-Log "Merging extracted files into Git directory: $GitInstallPath"
    Merge-DirectoryNoOverwrite -Source $extractDir -Destination $GitInstallPath

    Remove-Item -LiteralPath $tmpRoot -Recurse -Force

    if (-not (Test-Path $zshExe)) {
        Write-Log 'zsh files copied, but zsh.exe not found at expected location. Please verify package extraction result manually.'
    }
}

function Set-ZshAsDefaultInBashrc {
    $bashrcPath = Join-Path $HOME '.bashrc'
    if (-not (Test-Path $bashrcPath)) {
        New-Item -ItemType File -Path $bashrcPath -Force | Out-Null
    }

    $content = Get-Content -LiteralPath $bashrcPath -Raw

    $chcpLine = '/c/Windows/System32/chcp.com 65001 > /dev/null 2>&1'
    if ($content -notmatch [regex]::Escape($chcpLine)) {
        Add-Content -LiteralPath $bashrcPath -Value "`n$chcpLine"
        Write-Log 'Added UTF-8 code page fix to ~/.bashrc'
    }

    $zshBlock = @'
if [ -t 1 ]; then
  exec zsh
fi
'@

    if ($content -notmatch 'exec zsh') {
        Add-Content -LiteralPath $bashrcPath -Value "`n$zshBlock"
        Write-Log 'Added default zsh block to ~/.bashrc'
    }
}

function Install-OhMyZsh {
    param([string]$GitInstallPath)

    $bashExe = Join-Path $GitInstallPath 'bin\bash.exe'
    if (-not (Test-Path $bashExe)) {
        Fail "bash.exe not found: $bashExe"
    }

    Write-Log 'Installing Oh My Zsh (if not already installed)'
    & $bashExe -lc 'if [ -d "$HOME/.oh-my-zsh" ]; then echo "Oh My Zsh already installed"; else RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; fi'
}

function Verify-ZshVersion {
    param([string]$GitInstallPath)

    $bashExe = Join-Path $GitInstallPath 'bin\bash.exe'
    if (-not (Test-Path $bashExe)) {
        return
    }

    Write-Log 'Verifying zsh version in Git Bash'
    & $bashExe -lc 'zsh --version || true'
}

function Link-Dotfile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path -LiteralPath $Destination) {
        $item = Get-Item -LiteralPath $Destination -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $target = $item.Target
            if ($target -is [array]) {
                $target = $target[0]
            }
            if ($target -and $target -eq $Source) {
                Write-Log "Link unchanged $Destination -> $Source"
                return
            }
            Remove-Item -LiteralPath $Destination -Force
        }
        else {
            $backup = "$Destination.bak.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
            Move-Item -LiteralPath $Destination -Destination $backup
            Write-Log "Backed up existing item: $Destination -> $backup"
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
        Write-Log "Linked $Destination -> $Source"
    }
    catch {
        Fail "Failed to create symbolic link: $Destination -> $Source. On Windows, run PowerShell as Administrator or enable Developer Mode (Settings -> Privacy & security -> For developers -> Developer Mode)."
    }
}

function Link-Dotfiles {
    Write-Log 'Linking main dotfiles'

    $homeConfig = Join-Path $HOME '.config'
    $homeLocalBin = Join-Path $HOME '.local\bin'
    New-Item -ItemType Directory -Path $homeConfig -Force | Out-Null
    New-Item -ItemType Directory -Path $homeLocalBin -Force | Out-Null

    Link-Dotfile -Source (Join-Path $DotfilesRoot 'git\gitconfig') -Destination (Join-Path $HOME '.gitconfig')
    Link-Dotfile -Source (Join-Path $DotfilesRoot 'git\gitignore_global') -Destination (Join-Path $HOME '.gitignore_global')

    Link-Dotfile -Source (Join-Path $DotfilesRoot 'zsh\zshenv') -Destination (Join-Path $HOME '.zshenv')
    Link-Dotfile -Source (Join-Path $DotfilesRoot 'zsh\zprofile') -Destination (Join-Path $HOME '.zprofile')
    Link-Dotfile -Source (Join-Path $DotfilesRoot 'zsh\zshrc') -Destination (Join-Path $HOME '.zshrc')
    Link-Dotfile -Source (Join-Path $DotfilesRoot 'zsh\zlogin') -Destination (Join-Path $HOME '.zlogin')
    Link-Dotfile -Source (Join-Path $DotfilesRoot 'zsh\zlogout') -Destination (Join-Path $HOME '.zlogout')
    Link-Dotfile -Source (Join-Path $DotfilesRoot 'zsh\zshrc.d') -Destination (Join-Path $HOME '.zshrc.d')

    Link-Dotfile -Source (Join-Path $DotfilesRoot 'tmux\tmux.conf') -Destination (Join-Path $HOME '.tmux.conf')
    Link-Dotfile -Source (Join-Path $DotfilesRoot 'tmux\tmux.conf.local') -Destination (Join-Path $HOME '.tmux.conf.local')

    Link-Dotfile -Source (Join-Path $DotfilesRoot 'nvim') -Destination (Join-Path $homeConfig 'nvim')

    Link-Dotfile -Source (Join-Path $DotfilesRoot 'config\starship.toml') -Destination (Join-Path $homeConfig 'starship.toml')
    Link-Dotfile -Source (Join-Path $DotfilesRoot 'config\thefuck') -Destination (Join-Path $homeConfig 'thefuck')
    Link-Dotfile -Source (Join-Path $DotfilesRoot 'config\aria2') -Destination (Join-Path $homeConfig 'aria2')

    $binDir = Join-Path $DotfilesRoot 'bin'
    if (Test-Path -LiteralPath $binDir) {
        Get-ChildItem -LiteralPath $binDir -File | ForEach-Object {
            Link-Dotfile -Source $_.FullName -Destination (Join-Path $homeLocalBin $_.Name)
        }
    }
}

function Main {
    param([switch]$AssumeYes)

    Ensure-Windows

    Write-Log 'Step 1/3: Ensure Git (Bash terminal support)'
    Ensure-Git

    $gitInstallPath = Get-GitInstallPath
    Write-Log "Detected Git install path: $gitInstallPath"

    Write-Log 'Step 2/3: Ensure Zsh (download package and double-extract if missing)'
    Ensure-Zsh -GitInstallPath $gitInstallPath -AssumeYes:$AssumeYes

    Write-Log 'Step 3/3: Configure Bash -> Zsh and install Oh My Zsh'
    Set-ZshAsDefaultInBashrc
    Install-OhMyZsh -GitInstallPath $gitInstallPath
    Verify-ZshVersion -GitInstallPath $gitInstallPath
    Link-Dotfiles

    Write-Log 'Done'
    Write-Host 'Please close and reopen Git Bash to apply ~/.bashrc changes.'
    Write-Host 'For Powerlevel10k, install Meslo Nerd Font: https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k'
}

Main -AssumeYes:$Yes
