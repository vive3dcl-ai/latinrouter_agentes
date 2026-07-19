# Install LatinRouter as an OpenClaw provider plugin — Windows.
#
# Behavior:
#   1. No OpenClaw → official install.ps1 (--no-onboard when possible)
#   2. Prompt update if openclaw update exists (Enter = Yes)
#   3. Install plugin under %USERPROFILE%\.openclaw\extensions\latinrouter
#   4. Prompt API key (blank = onboard wizard later)
#
# Language: automatic from Windows UI culture (es / en).
# Skip update: $env:LATINROUTER_SKIP_OPENCLAW_UPDATE = "1"
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File openclaw\install.ps1
#   iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.ps1)

$ErrorActionPreference = "Stop"

$ProviderId = "latinrouter"
$BaseUrl = "https://llm.latinrouter.ai/v1"
$SignupUrl = "https://latinrouter.ai"
$DisplayName = "LatinRouter (Gateway IA Centralizado para Latinoamérica)"
$OfficialInstallUrl = "https://openclaw.ai/install.ps1"
$PluginRawBase = "https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/plugin"

function Get-InstallLang {
    try {
        $c = [System.Globalization.CultureInfo]::CurrentUICulture
        if ($c.TwoLetterISOLanguageName -eq "es") { return "es" }
    } catch {}
    try {
        if ((Get-Culture).TwoLetterISOLanguageName -eq "es") { return "es" }
    } catch {}
    return "en"
}

$script:Lang = Get-InstallLang

function Get-Msg {
    param([string]$Key, [object[]]$Args = @())
    $es = @{
        banner         = "==> LatinRouter + OpenClaw (Windows)"
        home           = "    Home: {0}"
        no_oc          = "==> OpenClaw no encontrado — instalando…"
        oc_ok          = "✓ OpenClaw instalado"
        oc_path_err    = "ERROR: 'openclaw' no está en el PATH. Abre PowerShell nuevo y re-ejecuta."
        checking       = "==> Comprobando actualizaciones de OpenClaw…"
        update_prompt  = "OpenClaw puede tener actualizaciones. ¿Actualizar ahora? [S/n]"
        updating       = "==> Actualizando OpenClaw…"
        updated        = "✓ OpenClaw actualizado"
        update_fail    = "ADVERTENCIA: falló la actualización — se continúa con LatinRouter"
        skip_update    = "==> Se omite la actualización de OpenClaw"
        no_tty_update  = "==> No hay terminal interactiva; se omite la actualización"
        install_prov   = "==> Instalando proveedor LatinRouter"
        plugin_ok      = "✓ Plugin instalado → {0}"
        key_prompt     = "API key de LatinRouter (Enter para omitir y usar el wizard después)"
        key_saved      = "✓ API key guardada en .openclaw\.env"
        key_skip       = "==> Sin key — usa: openclaw onboard → More… → LatinRouter"
        auth_ok        = "✓ Auth LatinRouter configurada"
        auth_fail      = "ADVERTENCIA: completa auth con openclaw onboard"
        next_title     = "Siguientes pasos:"
        next_1         = "  1. Obtén una key en {0}"
        next_2         = "  2. Ejecuta:  openclaw onboard"
        next_3         = "  3. More… → LatinRouter → pega tu API key"
        next_4         = "  4. Modelos desde {0}/models"
        next_5         = "  5. Verifica:  openclaw models list"
    }
    $en = @{
        banner         = "==> LatinRouter + OpenClaw (Windows)"
        home           = "    Home: {0}"
        no_oc          = "==> OpenClaw not found — installing…"
        oc_ok          = "✓ OpenClaw installed"
        oc_path_err    = "ERROR: 'openclaw' is not on PATH. Open a new PowerShell and re-run."
        checking       = "==> Checking OpenClaw updates…"
        update_prompt  = "OpenClaw may have updates. Update now? [Y/n]"
        updating       = "==> Updating OpenClaw…"
        updated        = "✓ OpenClaw updated"
        update_fail    = "WARNING: update failed — continuing with LatinRouter"
        skip_update    = "==> Skipping OpenClaw update"
        no_tty_update  = "==> No interactive terminal; skipping update"
        install_prov   = "==> Installing LatinRouter provider"
        plugin_ok      = "✓ Plugin installed → {0}"
        key_prompt     = "LatinRouter API key (Enter to skip and use the wizard later)"
        key_saved      = "✓ API key saved to .openclaw\.env"
        key_skip       = "==> No key — run: openclaw onboard → More… → LatinRouter"
        auth_ok        = "✓ LatinRouter auth configured"
        auth_fail      = "WARNING: finish auth with openclaw onboard"
        next_title     = "Next steps:"
        next_1         = "  1. Get a key at {0}"
        next_2         = "  2. Run:  openclaw onboard"
        next_3         = "  3. More… → LatinRouter → paste your API key"
        next_4         = "  4. Models from {0}/models"
        next_5         = "  5. Check:  openclaw models list"
    }
    $map = if ($script:Lang -eq "es") { $es } else { $en }
    $fmt = $map[$Key]
    if (-not $fmt) { return $Key }
    if ($Args.Count -gt 0) { return ($fmt -f $Args) }
    return $fmt
}

function Get-OpenClawStateDir {
    if ($env:OPENCLAW_STATE_DIR) { return $env:OPENCLAW_STATE_DIR }
    if ($env:OPENCLAW_HOME) { return $env:OPENCLAW_HOME }
    return (Join-Path $HOME ".openclaw")
}

function Test-OpenClawAvailable {
    return [bool](Get-Command openclaw -ErrorAction SilentlyContinue)
}

function Install-OpenClawOfficial {
    Write-Host (Get-Msg no_oc)
    try {
        $script = Invoke-WebRequest -Uri $OfficialInstallUrl -UseBasicParsing
        # Prefer --no-onboard when the script supports it
        Invoke-Expression ($script.Content + "`n")
    } catch {
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            npm i -g openclaw@latest
        } else {
            Write-Host "Install OpenClaw first: https://openclaw.ai"
            exit 1
        }
    }
    if (-not (Test-OpenClawAvailable)) {
        Write-Host (Get-Msg oc_path_err)
        exit 1
    }
    Write-Host (Get-Msg oc_ok)
}

function Confirm-UpdateOpenClaw {
    if ($env:LATINROUTER_SKIP_OPENCLAW_UPDATE -eq "1") { return $false }
    try {
        $reply = Read-Host (Get-Msg update_prompt)
    } catch {
        Write-Host (Get-Msg no_tty_update)
        return $false
    }
    if ([string]::IsNullOrWhiteSpace($reply)) { return $true }
    return ($reply.Trim() -notmatch '^(n|no)$')
}

function Update-OpenClaw {
    Write-Host (Get-Msg updating)
    try {
        & openclaw update
        Write-Host (Get-Msg updated)
    } catch {
        Write-Host (Get-Msg update_fail)
    }
}

function Install-PluginFiles {
    param([string]$ExtDir)
    New-Item -ItemType Directory -Force -Path $ExtDir | Out-Null
    $src = $null
    if ($PSScriptRoot) {
        $candidate = Join-Path $PSScriptRoot "plugin"
        if (Test-Path (Join-Path $candidate "index.ts")) { $src = $candidate }
    }
    if ($src) {
        Copy-Item -Force (Join-Path $src "index.ts") $ExtDir
        Copy-Item -Force (Join-Path $src "package.json") $ExtDir
        Copy-Item -Force (Join-Path $src "openclaw.plugin.json") $ExtDir
    } else {
        Invoke-WebRequest -Uri "$PluginRawBase/index.ts" -OutFile (Join-Path $ExtDir "index.ts") -UseBasicParsing
        Invoke-WebRequest -Uri "$PluginRawBase/package.json" -OutFile (Join-Path $ExtDir "package.json") -UseBasicParsing
        Invoke-WebRequest -Uri "$PluginRawBase/openclaw.plugin.json" -OutFile (Join-Path $ExtDir "openclaw.plugin.json") -UseBasicParsing
    }
}

function Register-Plugin {
    param([string]$ExtDir)
    try {
        & openclaw plugins install --link $ExtDir 2>$null | Out-Null
    } catch {}
    try {
        & openclaw plugins enable $ProviderId 2>$null | Out-Null
    } catch {}
}

function Save-EnvKey {
    param([string]$EnvFile, [string]$Key)
    $dir = Split-Path $EnvFile -Parent
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $line = "LATINROUTER_API_KEY=$Key"
    if (Test-Path $EnvFile) {
        $content = Get-Content $EnvFile -ErrorAction SilentlyContinue
        $found = $false
        $out = foreach ($l in $content) {
            if ($l -match '^LATINROUTER_API_KEY=') {
                $found = $true
                $line
            } else {
                $l
            }
        }
        if (-not $found) { $out = @($out) + $line }
        Set-Content -Path $EnvFile -Value $out -Encoding utf8
    } else {
        Set-Content -Path $EnvFile -Value $line -Encoding utf8
    }
    $env:LATINROUTER_API_KEY = $Key
}

function Apply-AuthNonInteractive {
    param([string]$Key)
    try {
        & openclaw onboard --non-interactive --accept-risk `
            --auth-choice latinrouter-api-key `
            --latinrouter-api-key $Key 2>$null | Out-Null
        Write-Host (Get-Msg auth_ok)
    } catch {
        Write-Host (Get-Msg auth_fail)
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$StateDir = Get-OpenClawStateDir
$ExtDir = Join-Path $StateDir "extensions\$ProviderId"
$EnvFile = Join-Path $StateDir ".env"

Write-Host (Get-Msg banner)
Write-Host (Get-Msg home -Args @($StateDir))

if (-not (Test-OpenClawAvailable)) {
    Install-OpenClawOfficial
} else {
    Write-Host (Get-Msg checking)
    $hasUpdate = $false
    try {
        & openclaw update --help 2>$null | Out-Null
        $hasUpdate = $true
    } catch { $hasUpdate = $false }
    if ($hasUpdate) {
        if (Confirm-UpdateOpenClaw) {
            Update-OpenClaw
        } else {
            Write-Host (Get-Msg skip_update)
        }
    }
}

Write-Host (Get-Msg install_prov)
Install-PluginFiles -ExtDir $ExtDir
Register-Plugin -ExtDir $ExtDir
Write-Host (Get-Msg plugin_ok -Args @($ExtDir))

$apiKey = ""
try {
    $apiKey = Read-Host (Get-Msg key_prompt)
} catch {
    $apiKey = ""
}
$apiKey = if ($apiKey) { $apiKey.Trim() } else { "" }

if ($apiKey) {
    Save-EnvKey -EnvFile $EnvFile -Key $apiKey
    Write-Host (Get-Msg key_saved)
    Apply-AuthNonInteractive -Key $apiKey
} else {
    Write-Host (Get-Msg key_skip)
}

Write-Host ""
Write-Host (Get-Msg next_title)
Write-Host (Get-Msg next_1 -Args @($SignupUrl))
Write-Host (Get-Msg next_2)
Write-Host (Get-Msg next_3)
Write-Host (Get-Msg next_4 -Args @($BaseUrl))
Write-Host (Get-Msg next_5)
Write-Host ""
