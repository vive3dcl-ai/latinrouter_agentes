# Install LatinRouter as a Hermes model-provider plugin (Windows native).
#
# Behavior:
#   1. No Hermes            → install from official NousResearch installer
#   2. Hermes outdated      → ask to update (default: Yes), then install plugin
#   3. Hermes up to date    → install LatinRouter provider quietly
#
# Language: auto from UI culture (es → Spanish, else English).
# Override: $env:LATINROUTER_LANG = "es" | "en"
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

function Get-InstallLang {
    $override = $env:LATINROUTER_LANG
    if ($override) {
        $o = $override.Trim().ToLowerInvariant()
        if ($o -match '^(es|spanish|español|espanol)' -or $o.StartsWith("es")) { return "es" }
        if ($o -match '^(en|english)' -or $o.StartsWith("en")) { return "en" }
    }
    try {
        $culture = [System.Globalization.CultureInfo]::CurrentUICulture
        if ($culture.TwoLetterISOLanguageName -eq "es") { return "es" }
        if ($culture.Name -match '^es') { return "es" }
    } catch {}
    try {
        $culture = Get-Culture
        if ($culture.TwoLetterISOLanguageName -eq "es") { return "es" }
    } catch {}
    if ($env:LANG -match '(?i)^es') { return "es" }
    return "en"
}

$script:Lang = Get-InstallLang

function Get-Msg {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [object[]]$Args = @()
    )
    $mapEs = @{
        banner           = "==> LatinRouter + Hermes (Windows)"
        home             = "    HERMES_HOME={0}"
        checking         = "==> Comprobando versión de Hermes…"
        install_provider = "==> Instalando proveedor LatinRouter"
        provider_ok      = "✓ Proveedor LatinRouter instalado → {0}"
        hermes_missing   = "==> Hermes no encontrado — instalando desde el instalador oficial"
        hermes_ok        = "✓ Hermes instalado"
        hermes_path_err  = "ERROR: la instalación de Hermes terminó pero 'hermes' no está en el PATH."
        hermes_path_hint = "Abre una ventana nueva de PowerShell y vuelve a ejecutar este script."
        update_ni        = "==> Hermes está desactualizado — actualizando (modo no interactivo: Sí)"
        update_prompt    = "Hermes está desactualizado. ¿Actualizar ahora? [S/n]"
        updating         = "==> Actualizando Hermes…"
        updated          = "✓ Hermes actualizado"
        update_fail      = "ADVERTENCIA: falló 'hermes update' — se continúa con la instalación del proveedor LatinRouter"
        skip_update      = "==> Se omite la actualización de Hermes"
        next_quiet       = "Siguiente: hermes model  →  LatinRouter  →  pega tu API key  ({0})"
        next_title       = "Siguientes pasos:"
        next_1           = "  1. Obtén una API key en {0}"
        next_2           = "  2. Ejecuta:  hermes model"
        next_3           = "  3. Elige: LatinRouter"
        next_4           = "  4. Pega tu LATINROUTER_API_KEY cuando te la pida"
        next_5           = "  5. Los modelos se cargan solos desde {0}/models"
        next_6           = "  6. Empieza a chatear:  hermes"
    }
    $mapEn = @{
        banner           = "==> LatinRouter + Hermes (Windows)"
        home             = "    HERMES_HOME={0}"
        checking         = "==> Checking Hermes version…"
        install_provider = "==> Installing LatinRouter provider"
        provider_ok      = "✓ LatinRouter provider installed → {0}"
        hermes_missing   = "==> Hermes not found — installing from official installer"
        hermes_ok        = "✓ Hermes installed"
        hermes_path_err  = "ERROR: Hermes install finished but 'hermes' is not on PATH."
        hermes_path_hint = "Open a new PowerShell window and re-run this script."
        update_ni        = "==> Hermes is outdated — updating (non-interactive default: Yes)"
        update_prompt    = "Hermes is outdated. Update now? [Y/n]"
        updating         = "==> Updating Hermes…"
        updated          = "✓ Hermes updated"
        update_fail      = "WARNING: hermes update failed — continuing with LatinRouter provider install"
        skip_update      = "==> Skipping Hermes update"
        next_quiet       = "Next: hermes model  →  LatinRouter  →  paste API key  ({0})"
        next_title       = "Next steps:"
        next_1           = "  1. Get an API key at {0}"
        next_2           = "  2. Run:  hermes model"
        next_3           = "  3. Select: LatinRouter"
        next_4           = "  4. Paste your LATINROUTER_API_KEY when prompted"
        next_5           = "  5. Models load automatically from {0}/models"
        next_6           = "  6. Start chatting:  hermes"
    }
    $map = if ($script:Lang -eq "es") { $mapEs } else { $mapEn }
    $fmt = $map[$Key]
    if (-not $fmt) { return $Key }
    if ($Args.Count -gt 0) {
        return ($fmt -f $Args)
    }
    return $fmt
}

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

    Write-Log (Get-Msg install_provider)
    if ($PluginSrc) {
        Copy-Item -Recurse -Force $PluginSrc $Dest
    } else {
        Write-EmbeddedPlugin -Dest $Dest
    }
    Write-LogAlways (Get-Msg provider_ok -Args @($Dest))
}

function Install-HermesOfficial {
    Write-LogAlways (Get-Msg hermes_missing)
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
        Write-LogAlways (Get-Msg hermes_path_err)
        Write-LogAlways (Get-Msg hermes_path_hint)
        exit 1
    }
    Write-LogAlways (Get-Msg hermes_ok)
}

function Test-HermesUpdateAvailable {
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
    return 'current'
}

function Confirm-UpdateHermes {
    if ($env:LATINROUTER_SKIP_HERMES_UPDATE -eq "1") {
        return $false
    }
    if (-not (Test-Interactive)) {
        Write-LogAlways (Get-Msg update_ni)
        return $true
    }
    $reply = Read-Host (Get-Msg update_prompt)
    if ([string]::IsNullOrWhiteSpace($reply)) { return $true }
    return ($reply -notmatch '^(n|no)$')
}

function Update-Hermes {
    Write-LogAlways (Get-Msg updating)
    try {
        & hermes update -y
        Refresh-Path
        Write-LogAlways (Get-Msg updated)
    } catch {
        Write-LogAlways (Get-Msg update_fail)
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$HermesHome = Get-HermesHome
Write-Log (Get-Msg banner)
Write-Log (Get-Msg home -Args @($HermesHome))

if (-not (Test-HermesAvailable)) {
    Install-HermesOfficial
    $script:Quiet = $false
} else {
    Write-Log (Get-Msg checking)
    $status = Test-HermesUpdateAvailable
    if ($status -eq 'available') {
        if (Confirm-UpdateHermes) {
            Update-Hermes
            $script:Quiet = $false
        } else {
            Write-Log (Get-Msg skip_update)
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
    Write-LogAlways (Get-Msg next_quiet -Args @($SignupUrl))
} else {
    Write-Host ""
    Write-Host (Get-Msg next_title)
    Write-Host (Get-Msg next_1 -Args @($SignupUrl))
    Write-Host (Get-Msg next_2)
    Write-Host (Get-Msg next_3)
    Write-Host (Get-Msg next_4)
    Write-Host (Get-Msg next_5 -Args @($BaseUrl))
    Write-Host (Get-Msg next_6)
    Write-Host ""
}
