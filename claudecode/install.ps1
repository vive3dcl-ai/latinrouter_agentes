# Install LatinRouter for Anthropic Claude Code (Windows).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File claudecode\install.ps1
#   iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/claudecode/install.ps1)

$ErrorActionPreference = "Stop"

$BaseRoot = "https://llm.latinrouter.ai"
$SignupUrl = "https://latinrouter.ai"
$OfficialInstallUrl = "https://claude.ai/install.ps1"

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
        banner = "==> LatinRouter + Claude Code (Windows)"; home = "    Config: {0}"
        no_bin = "==> Claude Code no encontrado — instalando…"; ok_bin = "✓ Claude Code instalado"
        path_err = "ERROR: 'claude' no está en el PATH."
        install_prov = "==> Configurando LatinRouter"; config_ok = "✓ Settings → {0}"
        key_prompt = "API key de LatinRouter (Enter para omitir)"
        key_saved = "✓ API key en settings"; key_skip = "==> Sin key — edita settings.json"
        msg_warn = "ADVERTENCIA: falta POST /v1/messages en el gateway (Claude Code lo requiere)."
        msg_ok = "✓ Gateway /v1/messages OK"
        next_title = "Siguientes pasos:"; next_1 = "  1. Key en {0}"; next_2 = "  2. claude"
    }
    $en = @{
        banner = "==> LatinRouter + Claude Code (Windows)"; home = "    Config: {0}"
        no_bin = "==> Claude Code not found — installing…"; ok_bin = "✓ Claude Code installed"
        path_err = "ERROR: 'claude' is not on PATH."
        install_prov = "==> Configuring LatinRouter"; config_ok = "✓ Settings → {0}"
        key_prompt = "LatinRouter API key (Enter to skip)"
        key_saved = "✓ API key in settings"; key_skip = "==> No key — edit settings.json"
        msg_warn = "WARNING: gateway lacks POST /v1/messages (required by Claude Code)."
        msg_ok = "✓ Gateway /v1/messages OK"
        next_title = "Next steps:"; next_1 = "  1. Key at {0}"; next_2 = "  2. claude"
    }
    $map = if ($script:Lang -eq "es") { $es } else { $en }
    $fmt = $map[$Key]; if (-not $fmt) { return $Key }
    if ($Args.Count -gt 0) { return ($fmt -f $Args) }
    return $fmt
}

$ClaudeDir = Join-Path $HOME ".claude"
$SettingsFile = Join-Path $ClaudeDir "settings.json"

function Test-Claude { return [bool](Get-Command claude -ErrorAction SilentlyContinue) }

Write-Host (Get-Msg banner)
Write-Host (Get-Msg home -Args @($SettingsFile))

if (-not (Test-Claude)) {
    Write-Host (Get-Msg no_bin)
    try { iex (irm $OfficialInstallUrl) }
    catch {
        if (Get-Command npm -ErrorAction SilentlyContinue) { npm i -g @anthropic-ai/claude-code }
        else { Write-Host "Install Claude Code: https://code.claude.com/docs/en/setup"; exit 1 }
    }
    if (-not (Test-Claude)) { Write-Host (Get-Msg path_err); exit 1 }
    Write-Host (Get-Msg ok_bin)
}

Write-Host (Get-Msg install_prov)
New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

$apiKey = ""
try { $apiKey = (Read-Host (Get-Msg key_prompt)).Trim() } catch { $apiKey = "" }

$data = @{ env = @{} }
if (Test-Path $SettingsFile) {
    try { $data = Get-Content $SettingsFile -Raw | ConvertFrom-Json } catch { $data = @{ env = @{} } }
}
if (-not $data.env) { $data | Add-Member -NotePropertyName env -NotePropertyValue (@{}) -Force }

# Convert to mutable hashtable for env
$envMap = @{}
if ($data.env) {
    $data.env.PSObject.Properties | ForEach-Object { $envMap[$_.Name] = $_.Value }
}
$envMap["ANTHROPIC_BASE_URL"] = $BaseRoot
$envMap["CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY"] = "1"
if ($apiKey) {
    $envMap["ANTHROPIC_AUTH_TOKEN"] = $apiKey
    $envMap["ANTHROPIC_API_KEY"] = $apiKey
    Write-Host (Get-Msg key_saved)
} else {
    Write-Host (Get-Msg key_skip)
}

$out = [ordered]@{}
# Preserve other top-level keys
if ($data.PSObject) {
    foreach ($p in $data.PSObject.Properties) {
        if ($p.Name -ne "env") { $out[$p.Name] = $p.Value }
    }
}
$out["env"] = $envMap
($out | ConvertTo-Json -Depth 10) | Set-Content -Path $SettingsFile -Encoding utf8
Write-Host (Get-Msg config_ok -Args @($SettingsFile))

try {
    $code = (Invoke-WebRequest -Uri "$BaseRoot/v1/messages" -Method POST `
        -Headers @{ Authorization = "Bearer probe"; "Content-Type" = "application/json"; "anthropic-version" = "2023-06-01" } `
        -Body '{}' -TimeoutSec 8 -SkipHttpErrorCheck).StatusCode
    if ($code -eq 404) { Write-Host (Get-Msg msg_warn) } else { Write-Host (Get-Msg msg_ok) }
} catch {
    Write-Host (Get-Msg msg_warn)
}

Write-Host ""
Write-Host (Get-Msg next_title)
Write-Host (Get-Msg next_1 -Args @($SignupUrl))
Write-Host (Get-Msg next_2)
Write-Host ""
