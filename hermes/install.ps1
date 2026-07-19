# Install LatinRouter as a Hermes model-provider plugin (Windows native).
#
# Behavior:
#   1. No Hermes            → install from official NousResearch installer
#   2. Hermes outdated      → ask to update (default: Yes), then install plugin
#   3. Hermes up to date    → install LatinRouter provider quietly
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File hermes\install.ps1
#   iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.ps1)
#
# Hermes on native Windows uses %LOCALAPPDATA%\hermes (not ~/.hermes).
# For WSL2, use the Linux installer instead: bash hermes/install.sh

$ErrorActionPreference = "Stop"

$ProviderName = "latinrouter"
$BaseUrl = "https://llm.latinrouter.ai/v1"
$SignupUrl = "https://latinrouter.ai"
$OfficialInstallUrl = "https://hermes-agent.nousresearch.com/install.ps1"
$script:Quiet = $false

function Write-Log {
    param([string]$Message)
    if (-not $script:Quiet) { Write-Host $Message }
}

function Write-LogAlways {
    param([string]$Message)
    Write-Host $Message
}

function Test-Interactive {
    try {
        return [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
    } catch {
        return $false
    }
}

function Get-HermesHome {
    if ($env:HERMES_HOME -and $env:HERMES_HOME.Trim()) {
        return $env:HERMES_HOME.Trim()
    }
    $localAppData = $env:LOCALAPPDATA
    if (-not $localAppData) {
        $localAppData = Join-Path $HOME "AppData\Local"
    }
    return (Join-Path $localAppData "hermes")
}

function Refresh-Path {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($machine -or $user) {
        $env:Path = @($machine, $user) -join ";"
    }
    $localBin = Join-Path $env:LOCALAPPDATA "hermes\bin"
    if (Test-Path $localBin) {
        $env:Path = "$localBin;$env:Path"
    }
}

function Test-HermesAvailable {
    Refresh-Path
    return [bool](Get-Command hermes -ErrorAction SilentlyContinue)
}

function Write-EmbeddedPlugin {
    param([string]$Dest)

    New-Item -ItemType Directory -Force -Path $Dest | Out-Null

    @'
"""LatinRouter provider profile for Hermes Agent.

OpenAI-compatible gateway at https://llm.latinrouter.ai/v1.
Live model catalog via GET /v1/models (Hermes fetch_models).

Drop this directory under $HERMES_HOME/plugins/model-providers/
(or run hermes/install.sh / hermes/install.ps1) to appear in `hermes model`.

HERMES_HOME defaults:
  Linux / macOS / WSL2 → ~/.hermes
  Windows native       → %LOCALAPPDATA%\\hermes
"""

from providers import register_provider
from providers.base import ProviderProfile

latinrouter = ProviderProfile(
    name="latinrouter",
    aliases=("latin-router", "lr"),
    env_vars=("LATINROUTER_API_KEY", "LATINROUTER_BASE_URL"),
    display_name="LatinRouter",
    description="LatinRouter — gateway OpenAI-compatible para Latinoamérica",
    signup_url="https://latinrouter.ai",
    base_url="https://llm.latinrouter.ai/v1",
    models_url="https://llm.latinrouter.ai/v1/models",
    auth_type="api_key",
    fallback_models=(),
)

register_provider(latinrouter)
'@ | Set-Content -Path (Join-Path $Dest "__init__.py") -Encoding utf8

    @'
name: latinrouter
kind: model-provider
version: 1.0.0
description: LatinRouter — gateway OpenAI-compatible para Latinoamérica
author: LatinRouter
'@ | Set-Content -Path (Join-Path $Dest "plugin.yaml") -Encoding utf8

    @'
# LatinRouter — Hermes model provider

| Campo | Valor |
|-------|--------|
| Provider id | `latinrouter` |
| Base URL | `https://llm.latinrouter.ai/v1` |
| Models | `GET /v1/models` (automático) |
| API key env | `LATINROUTER_API_KEY` |

```powershell
hermes model
hermes
```

Key: https://latinrouter.ai
'@ | Set-Content -Path (Join-Path $Dest "README.md") -Encoding utf8
}

function Install-LatinRouterPlugin {
    param([string]$HermesHome)

    $Dest = Join-Path $HermesHome "plugins\model-providers\$ProviderName"
    $PluginSrc = $null
    if ($PSScriptRoot) {
        $candidate = Join-Path $PSScriptRoot "plugin\$ProviderName"
        if (Test-Path (Join-Path $candidate "__init__.py")) {
            $PluginSrc = $candidate
        }
    }

    New-Item -ItemType Directory -Force -Path (Split-Path $Dest -Parent) | Out-Null
    if (Test-Path $Dest) {
        Remove-Item -Recurse -Force $Dest
    }

    Write-Log "==> Installing LatinRouter provider"
    if ($PluginSrc) {
        Copy-Item -Recurse -Force $PluginSrc $Dest
    } else {
        Write-EmbeddedPlugin -Dest $Dest
    }
    Write-LogAlways "✓ LatinRouter provider installed → $Dest"
}

function Install-HermesOfficial {
    Write-LogAlways "==> Hermes not found — installing from official installer"
    Write-LogAlways "    $OfficialInstallUrl"
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "hermes-official-install.ps1"
    Invoke-WebRequest -Uri $OfficialInstallUrl -OutFile $tmp -UseBasicParsing
    try {
        & $tmp -SkipSetup
    } finally {
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    }
    Refresh-Path
    if (-not (Test-HermesAvailable)) {
        Write-LogAlways "ERROR: Hermes install finished but 'hermes' is not on PATH."
        Write-LogAlways "Open a new PowerShell window and re-run this script."
        exit 1
    }
    Write-LogAlways "✓ Hermes installed"
}

function Test-HermesUpdateAvailable {
    # Returns: 'available' | 'current' | 'unknown'
    Refresh-Path
    try {
        $out = & hermes update --check 2>&1 | Out-String
    } catch {
        $out = "$_"
    }
    if ($out -match '(?i)Update available|behind') {
        ($out -split "`n" | Where-Object { $_ -match '(?i)Update available|behind' } | Select-Object -First 5) | ForEach-Object { Write-Host $_ }
        return 'available'
    }
    if ($out -match '(?i)Already up to date|up to date') {
        return 'current'
    }
    return 'current'
}

function Confirm-UpdateHermes {
    if ($env:LATINROUTER_SKIP_HERMES_UPDATE -eq "1") {
        return $false
    }
    if (-not (Test-Interactive)) {
        Write-LogAlways "==> Hermes is outdated — updating (non-interactive default: Yes)"
        return $true
    }
    $reply = Read-Host "Hermes está desactualizado. ¿Actualizar ahora? [Y/n]"
    if ([string]::IsNullOrWhiteSpace($reply)) { return $true }
    return ($reply -notmatch '^(n|no)$')
}

function Update-Hermes {
    Write-LogAlways "==> Updating Hermes…"
    try {
        & hermes update -y
        Refresh-Path
        Write-LogAlways "✓ Hermes updated"
    } catch {
        Write-LogAlways "WARNING: hermes update failed — continuing with LatinRouter provider install"
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$HermesHome = Get-HermesHome
Write-Log "==> LatinRouter + Hermes (Windows)"
Write-Log "    HERMES_HOME=$HermesHome"

if (-not (Test-HermesAvailable)) {
    Install-HermesOfficial
    $script:Quiet = $false
} else {
    Write-Log "==> Checking Hermes version…"
    $status = Test-HermesUpdateAvailable
    if ($status -eq 'available') {
        if (Confirm-UpdateHermes) {
            Update-Hermes
            $script:Quiet = $false
        } else {
            Write-Log "==> Skipping Hermes update"
            $script:Quiet = $false
        }
    } else {
        $script:Quiet = $true
    }
}

$HermesHome = Get-HermesHome
New-Item -ItemType Directory -Force -Path $HermesHome | Out-Null
Install-LatinRouterPlugin -HermesHome $HermesHome

if ($script:Quiet) {
    Write-LogAlways "Next: hermes model  →  LatinRouter  →  paste API key  ($SignupUrl)"
} else {
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Get an API key at $SignupUrl"
    Write-Host "  2. Run:  hermes model"
    Write-Host "  3. Select: LatinRouter"
    Write-Host "  4. Paste your LATINROUTER_API_KEY when prompted"
    Write-Host "  5. Models load automatically from $BaseUrl/models"
    Write-Host "  6. Start chatting:  hermes"
    Write-Host ""
}
