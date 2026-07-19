# Install LatinRouter as a Hermes model-provider plugin (Windows native).
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

function Write-EmbeddedPlugin {
    param([string]$Dest)

    New-Item -ItemType Directory -Force -Path $Dest | Out-Null

    @'
"""LatinRouter provider profile for Hermes Agent.

OpenAI-compatible gateway at https://llm.latinrouter.ai/v1.
Drop this directory under $HERMES_HOME/plugins/model-providers/
(or run hermes/install.sh / hermes/install.ps1) to appear in `hermes model`.
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

$HermesHome = Get-HermesHome
Write-Host "==> LatinRouter provider for Hermes (Windows)"
Write-Host "    HERMES_HOME=$HermesHome"

if (-not (Test-Path $HermesHome)) {
    Write-Host ""
    Write-Host "WARNING: $HermesHome does not exist."
    Write-Host "Install Hermes first (PowerShell):"
    Write-Host "  iex (irm https://hermes-agent.nousresearch.com/install.ps1)"
    Write-Host ""
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        $reply = Read-Host "Create $HermesHome and continue anyway? [y/N]"
        if ($reply -notmatch '^(y|yes)$') {
            Write-Host "Aborted. Install Hermes, then re-run this script."
            exit 1
        }
    }
    New-Item -ItemType Directory -Force -Path $HermesHome | Out-Null
}

if (-not (Get-Command hermes -ErrorAction SilentlyContinue)) {
    Write-Host "WARNING: 'hermes' not found in PATH. Plugin will still be installed;"
    Write-Host "         open a new PowerShell after installing Hermes."
}

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

if ($PluginSrc) {
    Write-Host "==> Copying plugin from $PluginSrc"
    Copy-Item -Recurse -Force $PluginSrc $Dest
} else {
    Write-Host "==> Writing embedded plugin (iex / irm mode)"
    Write-EmbeddedPlugin -Dest $Dest
}

Write-Host ""
Write-Host "Installed: $Dest"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Get an API key at $SignupUrl"
Write-Host "  2. Run:  hermes model"
Write-Host "  3. Select: LatinRouter"
Write-Host "  4. Paste your LATINROUTER_API_KEY when prompted"
Write-Host "  5. Pick a model from the live catalog ($BaseUrl/models)"
Write-Host "  6. Start chatting:  hermes"
Write-Host ""
Write-Host "Optional: set the key manually in $HermesHome\.env"
Write-Host "  LATINROUTER_API_KEY=sk-..."
Write-Host ""
Write-Host "Note: On WSL2 use bash hermes/install.sh (Linux path ~/.hermes)."
Write-Host ""
