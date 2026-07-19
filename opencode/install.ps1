# Install LatinRouter as an OpenCode provider (plugin + config) — Windows.
#
# Behavior:
#   1. No OpenCode → try scoop / npm / choco official install
#   2. OpenCode outdated → ask to update (default: Yes), then install provider
#   3. Prompt API key (blank = /connect later)
#   4. Drop plugin + merge opencode.json
#
# Language: automatic from Windows UI culture (es / en).
# Skip update prompt: $env:LATINROUTER_SKIP_OPENCODE_UPDATE = "1"
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File opencode\install.ps1
#   iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.ps1)

$ErrorActionPreference = "Stop"

$ProviderId = "latinrouter"
$BaseUrl = "https://llm.latinrouter.ai/v1"
$SignupUrl = "https://latinrouter.ai"
$DisplayName = "LatinRouter (Gateway IA Centralizado para Latinoamérica)"
$PluginRawUrl = "https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/plugin/latinrouter.js"
$ReleasesApi = "https://api.github.com/repos/anomalyco/opencode/releases/latest"

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
        banner         = "==> LatinRouter + OpenCode (Windows)"
        home           = "    Config: {0}"
        no_oc          = "==> OpenCode no encontrado — instalando…"
        oc_ok          = "✓ OpenCode instalado"
        oc_path_err    = "ERROR: 'opencode' no está en el PATH. Abre PowerShell nuevo y re-ejecuta."
        checking       = "==> Comprobando actualizaciones de OpenCode…"
        update_prompt  = "OpenCode está desactualizado ({0} → {1}). ¿Actualizar ahora? [S/n]"
        updating       = "==> Actualizando OpenCode…"
        updated        = "✓ OpenCode actualizado"
        update_fail    = "ADVERTENCIA: falló 'opencode upgrade' — se continúa con LatinRouter"
        skip_update    = "==> Se omite la actualización de OpenCode"
        no_tty_update  = "==> No hay terminal interactiva; se omite la actualización de OpenCode"
        install_prov   = "==> Instalando proveedor LatinRouter"
        plugin_ok      = "✓ Plugin instalado → {0}"
        config_ok      = "✓ Config actualizada → {0}"
        key_prompt     = "API key de LatinRouter (Enter para omitir y usar /connect después)"
        key_saved      = "✓ API key guardada"
        key_skip       = "==> Sin key — usa /connect → LatinRouter dentro de OpenCode"
        models_ok      = "✓ Modelos detectados: {0} (default: {1})"
        models_fail    = "ADVERTENCIA: no se pudo listar /v1/models"
        next_title     = "Siguientes pasos:"
        next_1         = "  1. Obtén una key en {0}"
        next_2         = "  2. Ejecuta:  opencode"
        next_3         = "  3. /connect → LatinRouter → pega tu API key"
        next_4         = "  4. /models → elige un modelo"
    }
    $en = @{
        banner         = "==> LatinRouter + OpenCode (Windows)"
        home           = "    Config: {0}"
        no_oc          = "==> OpenCode not found — installing…"
        oc_ok          = "✓ OpenCode installed"
        oc_path_err    = "ERROR: 'opencode' is not on PATH. Open a new PowerShell and re-run."
        checking       = "==> Checking OpenCode updates…"
        update_prompt  = "OpenCode is outdated ({0} → {1}). Update now? [Y/n]"
        updating       = "==> Updating OpenCode…"
        updated        = "✓ OpenCode updated"
        update_fail    = "WARNING: opencode upgrade failed — continuing with LatinRouter"
        skip_update    = "==> Skipping OpenCode update"
        no_tty_update  = "==> No interactive terminal; skipping OpenCode update"
        install_prov   = "==> Installing LatinRouter provider"
        plugin_ok      = "✓ Plugin installed → {0}"
        config_ok      = "✓ Config updated → {0}"
        key_prompt     = "LatinRouter API key (Enter to skip and use /connect later)"
        key_saved      = "✓ API key saved"
        key_skip       = "==> No key — use /connect → LatinRouter inside OpenCode"
        models_ok      = "✓ Models found: {0} (default: {1})"
        models_fail    = "WARNING: could not list /v1/models"
        next_title     = "Next steps:"
        next_1         = "  1. Get a key at {0}"
        next_2         = "  2. Run:  opencode"
        next_3         = "  3. /connect → LatinRouter → paste your API key"
        next_4         = "  4. /models → pick a model"
    }
    $map = if ($script:Lang -eq "es") { $es } else { $en }
    $fmt = $map[$Key]
    if (-not $fmt) { return $Key }
    if ($Args.Count -gt 0) { return ($fmt -f $Args) }
    return $fmt
}

function Get-OpenCodeConfigDir {
    if ($env:XDG_CONFIG_HOME) { return (Join-Path $env:XDG_CONFIG_HOME "opencode") }
    return (Join-Path $HOME ".config\opencode")
}

function Get-OpenCodeDataDir {
    if ($env:XDG_DATA_HOME) { return (Join-Path $env:XDG_DATA_HOME "opencode") }
    return (Join-Path $HOME ".local\share\opencode")
}

function Get-OpenCodeStateDir {
    if ($env:XDG_STATE_HOME) { return (Join-Path $env:XDG_STATE_HOME "opencode") }
    return (Join-Path $HOME ".local\state\opencode")
}

function Test-OpenCodeAvailable {
    return [bool](Get-Command opencode -ErrorAction SilentlyContinue)
}

function Get-OpenCodeVersion {
    try {
        $raw = (& opencode -v 2>$null | Out-String).Trim()
        if (-not $raw) { $raw = (& opencode --version 2>$null | Out-String).Trim() }
        if ($raw -match '(\d+(?:\.\d+)+)') { return $Matches[1] }
    } catch {}
    return $null
}

function Get-LatestOpenCodeVersion {
    try {
        $headers = @{ "User-Agent" = "latinrouter-opencode-installer" }
        $resp = Invoke-RestMethod -Uri $ReleasesApi -Headers $headers -TimeoutSec 12
        $tag = [string]$resp.tag_name
        if ($tag -match '(\d+(?:\.\d+)+)') { return $Matches[1] }
    } catch {}
    return $null
}

function ConvertTo-VersionTuple {
    param([string]$Version)
    $parts = @()
    foreach ($p in ($Version -split '\.')) {
        $n = 0
        [void][int]::TryParse($p, [ref]$n)
        $parts += $n
    }
    while ($parts.Count -lt 3) { $parts += 0 }
    return ,$parts
}

function Test-OpenCodeUpdateAvailable {
    $current = Get-OpenCodeVersion
    $latest = Get-LatestOpenCodeVersion
    if (-not $current -or -not $latest) { return $null }
    if ($current -eq $latest) { return $null }
    $c = ConvertTo-VersionTuple $current
    $l = ConvertTo-VersionTuple $latest
    for ($i = 0; $i -lt 3; $i++) {
        if ($c[$i] -lt $l[$i]) {
            return @{ Current = $current; Latest = $latest }
        }
        if ($c[$i] -gt $l[$i]) { return $null }
    }
    return $null
}

function Confirm-UpdateOpenCode {
    param([string]$Current, [string]$Latest)
    if ($env:LATINROUTER_SKIP_OPENCODE_UPDATE -eq "1") { return $false }
    try {
        $reply = Read-Host (Get-Msg update_prompt -Args @($Current, $Latest))
    } catch {
        Write-Host (Get-Msg no_tty_update)
        return $false
    }
    if ([string]::IsNullOrWhiteSpace($reply)) { return $true }
    return ($reply.Trim() -notmatch '^(n|no)$')
}

function Update-OpenCode {
    Write-Host (Get-Msg updating)
    try {
        & opencode upgrade
        Write-Host (Get-Msg updated)
    } catch {
        Write-Host (Get-Msg update_fail)
    }
}

function Install-OpenCodeOfficial {
    Write-Host (Get-Msg no_oc)
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop install opencode
    } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
        npm i -g opencode-ai@latest
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install opencode -y
    } else {
        Write-Host "Install OpenCode first: https://opencode.ai  (scoop / npm / choco)"
        Write-Host "  scoop install opencode"
        Write-Host "  npm i -g opencode-ai@latest"
        exit 1
    }
    if (-not (Test-OpenCodeAvailable)) {
        Write-Host (Get-Msg oc_path_err)
        exit 1
    }
    Write-Host (Get-Msg oc_ok)
}

function Write-Plugin {
    param([string]$Dest)
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest -Parent) | Out-Null
    $src = $null
    if ($PSScriptRoot) {
        $candidate = Join-Path $PSScriptRoot "plugin\latinrouter.js"
        if (Test-Path $candidate) { $src = $candidate }
    }
    if ($src) {
        Copy-Item -Force $src $Dest
    } else {
        Invoke-WebRequest -Uri $PluginRawUrl -OutFile $Dest -UseBasicParsing
    }
}

function Invoke-JsonPython {
    param([string]$Code)
    $py = $null
    foreach ($c in @("python", "python3", "py")) {
        if (Get-Command $c -ErrorAction SilentlyContinue) { $py = $c; break }
    }
    if (-not $py) { return $false }
    & $py -c $Code
    return ($LASTEXITCODE -eq 0)
}

function Merge-Config {
    param([string]$ConfigFile, [string]$ModelId)
    $dir = Split-Path $ConfigFile -Parent
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $pyModel = if ($ModelId) { $ModelId } else { "" }
    $code = @"
import json, os
path = r'$ConfigFile'
pid, name, base, model_id = r'$ProviderId', r'$DisplayName', r'$BaseUrl', r'$pyModel'
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {}
if os.path.isfile(path):
    try:
        data = json.load(open(path, encoding='utf-8')) or {}
    except Exception:
        data = {}
if not isinstance(data, dict):
    data = {}
data.setdefault('`$schema', 'https://opencode.ai/config.json')
providers = data.setdefault('provider', {})
if not isinstance(providers, dict):
    providers = {}
    data['provider'] = providers
entry = providers.get(pid) if isinstance(providers.get(pid), dict) else {}
opts = entry.get('options') if isinstance(entry.get('options'), dict) else {}
opts['baseURL'] = base
entry.update({'npm': '@ai-sdk/openai-compatible', 'name': name, 'env': ['LATINROUTER_API_KEY'], 'options': opts})
providers[pid] = entry
if model_id:
    data['model'] = f'{pid}/{model_id}'
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"@
    if (Invoke-JsonPython -Code $code) { return $ConfigFile }
    # Fallback: merge with PSCustomObject (Windows PowerShell 5.1)
    $root = $null
    if (Test-Path $ConfigFile) {
        try { $root = Get-Content $ConfigFile -Raw | ConvertFrom-Json } catch { $root = $null }
    }
    if (-not $root) { $root = [pscustomobject]@{} }
    if (-not $root.PSObject.Properties['$schema']) {
        $root | Add-Member -NotePropertyName '$schema' -NotePropertyValue 'https://opencode.ai/config.json' -Force
    }
    if (-not $root.PSObject.Properties['provider'] -or -not $root.provider) {
        $root | Add-Member -NotePropertyName 'provider' -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $entry = [pscustomobject]@{
        npm     = '@ai-sdk/openai-compatible'
        name    = $DisplayName
        env     = @('LATINROUTER_API_KEY')
        options = [pscustomobject]@{ baseURL = $BaseUrl }
    }
    $root.provider | Add-Member -NotePropertyName $ProviderId -NotePropertyValue $entry -Force
    if ($ModelId) {
        $root | Add-Member -NotePropertyName 'model' -NotePropertyValue "$ProviderId/$ModelId" -Force
    }
    ($root | ConvertTo-Json -Depth 20) | Set-Content -Path $ConfigFile -Encoding utf8
    return $ConfigFile
}

function Save-AuthKey {
    param([string]$AuthFile, [string]$Key)
    $dir = Split-Path $AuthFile -Parent
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $code = @"
import json, os
path = r'$AuthFile'
pid, key = r'$ProviderId', r'$Key'
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {}
if os.path.isfile(path):
    try:
        data = json.load(open(path, encoding='utf-8')) or {}
    except Exception:
        data = {}
if not isinstance(data, dict):
    data = {}
data[pid] = {'type': 'api', 'key': key}
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"@
    if (Invoke-JsonPython -Code $code) { return }
    $root = $null
    if (Test-Path $AuthFile) {
        try { $root = Get-Content $AuthFile -Raw | ConvertFrom-Json } catch { $root = $null }
    }
    if (-not $root) { $root = [pscustomobject]@{} }
    $root | Add-Member -NotePropertyName $ProviderId -NotePropertyValue ([pscustomobject]@{ type = 'api'; key = $Key }) -Force
    ($root | ConvertTo-Json -Depth 5) | Set-Content -Path $AuthFile -Encoding utf8
}

function Get-FirstModel {
    param([string]$Key)
    try {
        $headers = @{ Authorization = "Bearer $Key"; Accept = "application/json" }
        $resp = Invoke-RestMethod -Uri "$BaseUrl/models" -Headers $headers -TimeoutSec 12
        $items = if ($resp.data) { $resp.data } else { $resp }
        $ids = @($items | ForEach-Object { $_.id } | Where-Object { $_ })
        if ($ids.Count -eq 0) { return $null }
        return @{ Count = $ids.Count; First = $ids[0] }
    } catch {
        return $null
    }
}

function Save-ModelState {
    param([string]$StateFile, [string]$ModelId)
    $dir = Split-Path $StateFile -Parent
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $data = @{ recent = @(@{ providerID = $ProviderId; modelID = $ModelId }) }
    ($data | ConvertTo-Json -Depth 5) | Set-Content -Path $StateFile -Encoding utf8
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$ConfigDir = Get-OpenCodeConfigDir
$DataDir = Get-OpenCodeDataDir
$StateDir = Get-OpenCodeStateDir
$PluginsDir = Join-Path $ConfigDir "plugins"
$ConfigFile = Join-Path $ConfigDir "opencode.json"
$AuthFile = Join-Path $DataDir "auth.json"
$ModelState = Join-Path $StateDir "model.json"

Write-Host (Get-Msg banner)
Write-Host (Get-Msg home -Args @($ConfigDir))

if (-not (Test-OpenCodeAvailable)) {
    Install-OpenCodeOfficial
} else {
    Write-Host (Get-Msg checking)
    $upd = Test-OpenCodeUpdateAvailable
    if ($upd) {
        if (Confirm-UpdateOpenCode -Current $upd.Current -Latest $upd.Latest) {
            Update-OpenCode
        } else {
            Write-Host (Get-Msg skip_update)
        }
    }
}

Write-Host (Get-Msg install_prov)
$PluginDest = Join-Path $PluginsDir "latinrouter.js"
Write-Plugin -Dest $PluginDest
Write-Host (Get-Msg plugin_ok -Args @($PluginDest))

$apiKey = ""
try {
    $apiKey = Read-Host (Get-Msg key_prompt)
} catch {
    $apiKey = ""
}
$apiKey = if ($apiKey) { $apiKey.Trim() } else { "" }

$defaultModel = ""
if ($apiKey) {
    Save-AuthKey -AuthFile $AuthFile -Key $apiKey
    Write-Host (Get-Msg key_saved)
    $fetched = Get-FirstModel -Key $apiKey
    if ($fetched) {
        $defaultModel = $fetched.First
        Write-Host (Get-Msg models_ok -Args @($fetched.Count, $defaultModel))
        Save-ModelState -StateFile $ModelState -ModelId $defaultModel
    } else {
        Write-Host (Get-Msg models_fail)
    }
} else {
    Write-Host (Get-Msg key_skip)
}

$cfgPath = Merge-Config -ConfigFile $ConfigFile -ModelId $defaultModel
Write-Host (Get-Msg config_ok -Args @($cfgPath))

Write-Host ""
Write-Host (Get-Msg next_title)
Write-Host (Get-Msg next_1 -Args @($SignupUrl))
Write-Host (Get-Msg next_2)
Write-Host (Get-Msg next_3)
Write-Host (Get-Msg next_4)
Write-Host ""
