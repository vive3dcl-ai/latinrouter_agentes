# Install LatinRouter as a named OpenAI Codex provider (Windows).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File codex\install.ps1
#   iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/codex/install.ps1)

$ErrorActionPreference = "Stop"

$ProviderId = "latinrouter"
$BaseUrl = "https://llm.latinrouter.ai/v1"
$SignupUrl = "https://latinrouter.ai"
$DisplayName = "LatinRouter (Gateway IA Centralizado para Latinoamérica)"
$OfficialInstallUrl = "https://chatgpt.com/codex/install.ps1"

function Get-InstallLang {
    try {
        if ([System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName -eq "es") { return "es" }
    } catch {}
    return "en"
}
$script:Lang = Get-InstallLang

function Get-Msg {
    param([string]$Key, [object[]]$Args = @())
    $es = @{
        banner = "==> LatinRouter + OpenAI Codex (Windows)"; home = "    CODEX_HOME={0}"
        no_bin = "==> Codex no encontrado — instalando…"; ok_bin = "✓ Codex instalado"
        path_err = "ERROR: 'codex' no está en el PATH."
        install_prov = "==> Configurando proveedor LatinRouter"; config_ok = "✓ Config → {0}"
        key_prompt = "API key de LatinRouter (Enter para omitir)"
        key_saved = "✓ API key → {0}"; key_skip = "==> Sin key — define LATINROUTER_API_KEY"
        models_ok = "✓ Modelos: {0} (default: {1})"; models_fail = "ADVERTENCIA: no se listó /v1/models"
        resp_warn = "ADVERTENCIA: falta POST /v1/responses en el gateway (Codex lo requiere)."
        resp_ok = "✓ Gateway /v1/responses OK"
        next_title = "Siguientes pasos:"; next_1 = "  1. Key en {0}"
        next_2 = "  2. codex --profile latinrouter"
    }
    $en = @{
        banner = "==> LatinRouter + OpenAI Codex (Windows)"; home = "    CODEX_HOME={0}"
        no_bin = "==> Codex not found — installing…"; ok_bin = "✓ Codex installed"
        path_err = "ERROR: 'codex' is not on PATH."
        install_prov = "==> Configuring LatinRouter provider"; config_ok = "✓ Config → {0}"
        key_prompt = "LatinRouter API key (Enter to skip)"
        key_saved = "✓ API key → {0}"; key_skip = "==> No key — set LATINROUTER_API_KEY"
        models_ok = "✓ Models: {0} (default: {1})"; models_fail = "WARNING: could not list /v1/models"
        resp_warn = "WARNING: gateway lacks POST /v1/responses (required by Codex)."
        resp_ok = "✓ Gateway /v1/responses OK"
        next_title = "Next steps:"; next_1 = "  1. Key at {0}"
        next_2 = "  2. codex --profile latinrouter"
    }
    $map = if ($script:Lang -eq "es") { $es } else { $en }
    $fmt = $map[$Key]; if (-not $fmt) { return $Key }
    if ($Args.Count -gt 0) { return ($fmt -f $Args) }
    return $fmt
}

$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$ConfigFile = Join-Path $CodexHome "config.toml"
$ProfileFile = Join-Path $CodexHome "latinrouter.config.toml"
$SecretFile = Join-Path $CodexHome "secrets\latinrouter"

function Test-Codex { return [bool](Get-Command codex -ErrorAction SilentlyContinue) }

Write-Host (Get-Msg banner)
Write-Host (Get-Msg home -Args @($CodexHome))

if (-not (Test-Codex)) {
    Write-Host (Get-Msg no_bin)
    try {
        iex (irm $OfficialInstallUrl)
    } catch {
        if (Get-Command npm -ErrorAction SilentlyContinue) { npm i -g @openai/codex }
        else { Write-Host "Install Codex: https://github.com/openai/codex"; exit 1 }
    }
    if (-not (Test-Codex)) { Write-Host (Get-Msg path_err); exit 1 }
    Write-Host (Get-Msg ok_bin)
}

Write-Host (Get-Msg install_prov)
New-Item -ItemType Directory -Force -Path (Split-Path $SecretFile -Parent) | Out-Null

$apiKey = ""
try { $apiKey = (Read-Host (Get-Msg key_prompt)).Trim() } catch { $apiKey = "" }

$defaultModel = ""
if ($apiKey) {
    Set-Content -Path $SecretFile -Value $apiKey -Encoding ascii -NoNewline
    icacls $SecretFile /inheritance:r /grant:r "$($env:USERNAME):(R)" 2>$null | Out-Null
    Write-Host (Get-Msg key_saved -Args @($SecretFile))
    $env:LATINROUTER_API_KEY = $apiKey
    try {
        $headers = @{ Authorization = "Bearer $apiKey"; Accept = "application/json" }
        $resp = Invoke-RestMethod -Uri "$BaseUrl/models" -Headers $headers -TimeoutSec 12
        $items = if ($resp.data) { $resp.data } else { $resp }
        $ids = @($items | ForEach-Object { $_.id } | Where-Object { $_ })
        if ($ids.Count -gt 0) {
            $defaultModel = $ids[0]
            Write-Host (Get-Msg models_ok -Args @($ids.Count, $defaultModel))
        } else { Write-Host (Get-Msg models_fail) }
    } catch { Write-Host (Get-Msg models_fail) }
} else {
    if (-not (Test-Path $SecretFile)) { Set-Content -Path $SecretFile -Value "" -Encoding ascii }
    Write-Host (Get-Msg key_skip)
}

# Write TOML via Python when available
$py = $null
foreach ($c in @("python", "python3", "py")) {
    if (Get-Command $c -ErrorAction SilentlyContinue) { $py = $c; break }
}
$secretPosix = $SecretFile -replace '\\', '/'
if ($py) {
    & $py -c @"
import os, re
config, profile, secret = r'$ConfigFile', r'$ProfileFile', r'$secretPosix'
pid, name, base, model_id = r'$ProviderId', r'$DisplayName', r'$BaseUrl', r'$defaultModel'
os.makedirs(os.path.dirname(config), exist_ok=True)
block = f'''
# LatinRouter — managed by latinrouter_agentes installer
[model_providers.{pid}]
name = "{name}"
base_url = "{base}"
wire_api = "responses"
env_key = "LATINROUTER_API_KEY"
env_key_instructions = "Get a key at https://latinrouter.ai"
requires_openai_auth = false
supports_websockets = false

[model_providers.{pid}.auth]
command = "type" if os.name == "nt" else "cat"
args = [r"{secret}"]
timeout_ms = 2000
refresh_interval_ms = 0
'''
# On Windows auth.command: use powershell Get-Content -Raw for reliability
block = f'''
# LatinRouter — managed by latinrouter_agentes installer
[model_providers.{pid}]
name = "{name}"
base_url = "{base}"
wire_api = "responses"
env_key = "LATINROUTER_API_KEY"
env_key_instructions = "Get a key at https://latinrouter.ai"
requires_openai_auth = false
supports_websockets = false

[model_providers.{pid}.auth]
command = "powershell"
args = ["-NoProfile", "-Command", "Get-Content -Raw '{SecretFile}'"]
timeout_ms = 5000
refresh_interval_ms = 0
'''
text = open(config, encoding='utf-8').read() if os.path.isfile(config) else ''
text = re.sub(rf'\n?# LatinRouter — managed by latinrouter_agentes installer[\s\S]*?(?=\n\[|\Z)', '\n', text)
text = text.rstrip() + '\n' + block
open(config, 'w', encoding='utf-8').write(text)
prof = f'# LatinRouter profile\nmodel_provider = "{pid}"\n'
if model_id:
    prof += f'model = "{model_id}"\n'
open(profile, 'w', encoding='utf-8').write(prof)
print(config)
"@
} else {
    $block = @"

# LatinRouter — managed by latinrouter_agentes installer
[model_providers.$ProviderId]
name = "$DisplayName"
base_url = "$BaseUrl"
wire_api = "responses"
env_key = "LATINROUTER_API_KEY"
requires_openai_auth = false
supports_websockets = false
"@
    Add-Content -Path $ConfigFile -Value $block -Encoding utf8
    $prof = "model_provider = `"$ProviderId`"`n"
    if ($defaultModel) { $prof += "model = `"$defaultModel`"`n" }
    Set-Content -Path $ProfileFile -Value $prof -Encoding utf8
}

Write-Host (Get-Msg config_ok -Args @($ConfigFile))

try {
    $code = (Invoke-WebRequest -Uri "$BaseUrl/responses" -Method POST -Headers @{ Authorization = "Bearer probe"; "Content-Type" = "application/json" } -Body '{}' -TimeoutSec 8 -SkipHttpErrorCheck).StatusCode
    if ($code -eq 404) { Write-Host (Get-Msg resp_warn) } else { Write-Host (Get-Msg resp_ok) }
} catch {
    Write-Host (Get-Msg resp_warn)
}

Write-Host ""
Write-Host (Get-Msg next_title)
Write-Host (Get-Msg next_1 -Args @($SignupUrl))
Write-Host (Get-Msg next_2)
Write-Host ""
