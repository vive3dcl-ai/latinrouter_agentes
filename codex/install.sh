#!/usr/bin/env bash
# Install LatinRouter as a named OpenAI Codex provider (config.toml).
#
# Behavior:
#   1. No Codex → official chatgpt.com/codex/install.sh
#   2. Prompt API key → ~/.codex/secrets/latinrouter + model_providers.latinrouter
#   3. Fetch /v1/models → set default model + latinrouter.config.toml profile
#   4. Warn if gateway lacks POST /v1/responses (required by current Codex)
#
# Language: auto es/en from LANG/LC_*.
#
# Usage:
#   bash codex/install.sh
#   curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/codex/install.sh | bash
set -euo pipefail

PROVIDER_ID="latinrouter"
BASE_URL="https://llm.latinrouter.ai/v1"
SIGNUP_URL="https://latinrouter.ai"
DISPLAY_NAME="LatinRouter (Gateway IA Centralizado para Latinoamérica)"
OFFICIAL_INSTALL_URL="https://chatgpt.com/codex/install.sh"

detect_lang() {
  local loc="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
  loc="$(printf '%s' "$loc" | tr '[:upper:]' '[:lower:]')"
  case "$loc" in
    es|es_*|*.es|*.es_*|*es_es*|*es_mx*|*es_ar*|*es_co*|*es_cl*|*es_pe*|*es_ve*) echo es ;;
    *) echo en ;;
  esac
}
LR_LANG="$(detect_lang)"

msg() {
  local key="$1"; shift || true
  local text=""
  case "$LR_LANG" in
    es)
      case "$key" in
        banner)       text="==> LatinRouter + OpenAI Codex" ;;
        home)         text="    CODEX_HOME=%s" ;;
        no_bin)       text="==> Codex no encontrado — instalando desde el instalador oficial" ;;
        ok_bin)       text="✓ Codex instalado" ;;
        path_err)     text="ERROR: 'codex' no está en el PATH. Abre una terminal nueva y re-ejecuta." ;;
        install_prov) text="==> Configurando proveedor LatinRouter" ;;
        config_ok)    text="✓ Config actualizada → %s" ;;
        key_prompt)   text="API key de LatinRouter (Enter para omitir): " ;;
        key_saved)    text="✓ API key guardada → %s" ;;
        key_skip)     text="==> Sin key — exporta LATINROUTER_API_KEY o edita ~/.codex/secrets/latinrouter" ;;
        models_ok)    text="✓ Modelos detectados: %s (default: %s)" ;;
        models_fail)  text="ADVERTENCIA: no se pudo listar /v1/models" ;;
        resp_warn)    text="ADVERTENCIA: el gateway aún no expone POST /v1/responses (Codex lo requiere). La config queda lista; el chat fallará hasta que LatinRouter agregue Responses." ;;
        resp_ok)      text="✓ Gateway responde en /v1/responses" ;;
        next_title)   text="Siguientes pasos:" ;;
        next_1)       text="  1. Key en %s" ;;
        next_2)       text="  2. Ejecuta:  codex --profile latinrouter" ;;
        next_3)       text="  3. O: export LATINROUTER_API_KEY=… && codex" ;;
        *)            text="$key" ;;
      esac ;;
    *)
      case "$key" in
        banner)       text="==> LatinRouter + OpenAI Codex" ;;
        home)         text="    CODEX_HOME=%s" ;;
        no_bin)       text="==> Codex not found — installing from official installer" ;;
        ok_bin)       text="✓ Codex installed" ;;
        path_err)     text="ERROR: 'codex' is not on PATH. Open a new terminal and re-run." ;;
        install_prov) text="==> Configuring LatinRouter provider" ;;
        config_ok)    text="✓ Config updated → %s" ;;
        key_prompt)   text="LatinRouter API key (Enter to skip): " ;;
        key_saved)    text="✓ API key saved → %s" ;;
        key_skip)     text="==> No key — export LATINROUTER_API_KEY or edit ~/.codex/secrets/latinrouter" ;;
        models_ok)    text="✓ Models found: %s (default: %s)" ;;
        models_fail)  text="WARNING: could not list /v1/models" ;;
        resp_warn)    text="WARNING: gateway still lacks POST /v1/responses (required by Codex). Config is ready; chat will fail until LatinRouter adds Responses." ;;
        resp_ok)      text="✓ Gateway responds on /v1/responses" ;;
        next_title)   text="Next steps:" ;;
        next_1)       text="  1. Key at %s" ;;
        next_2)       text="  2. Run:  codex --profile latinrouter" ;;
        next_3)       text="  3. Or: export LATINROUTER_API_KEY=… && codex" ;;
        *)            text="$key" ;;
      esac ;;
  esac
  # shellcheck disable=SC2059
  printf "$text" "$@"
}

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME/config.toml"
PROFILE_FILE="$CODEX_HOME/latinrouter.config.toml"
SECRET_FILE="$CODEX_HOME/secrets/latinrouter"

refresh_path() {
  export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
  hash -r 2>/dev/null || true
}

codex_available() {
  refresh_path
  command -v codex >/dev/null 2>&1
}

prompt_api_key() {
  local reply=""
  if { true >/dev/tty; } 2>/dev/null; then
    printf '%s' "$(msg key_prompt)" > /dev/tty
    IFS= read -r reply < /dev/tty || true
  elif [[ -t 0 && -t 1 ]]; then
    read -r -p "$(msg key_prompt)" reply || true
  fi
  printf '%s' "$(printf '%s' "$reply" | tr -d '[:space:]')"
}

fetch_models() {
  local key="$1"
  python3 - "$BASE_URL" "$key" <<'PY' 2>/dev/null || true
import json, sys, urllib.request
base, key = sys.argv[1:3]
req = urllib.request.Request(base.rstrip("/") + "/models", headers={
    "Authorization": f"Bearer {key}",
    "Accept": "application/json",
})
try:
    with urllib.request.urlopen(req, timeout=12) as resp:
        body = json.loads(resp.read().decode())
except Exception:
    sys.exit(1)
items = body if isinstance(body, list) else body.get("data", [])
ids = [m["id"] for m in items if isinstance(m, dict) and "id" in m]
if not ids:
    sys.exit(1)
print(len(ids))
print(ids[0])
PY
}

probe_responses() {
  # 404 = missing route; 401/400 = route exists
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "${BASE_URL}/responses" \
    -H "Authorization: Bearer probe" -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null || echo 000)"
  case "$code" in
    404|000) return 1 ;;
    *) return 0 ;;
  esac
}

write_config() {
  local model_id="${1:-}"
  python3 - "$CONFIG_FILE" "$PROFILE_FILE" "$SECRET_FILE" "$PROVIDER_ID" "$DISPLAY_NAME" "$BASE_URL" "$model_id" <<'PY'
import os, sys, re
config, profile, secret, pid, name, base, model_id = sys.argv[1:8]
os.makedirs(os.path.dirname(config), exist_ok=True)
os.makedirs(os.path.dirname(secret), exist_ok=True)

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
command = "cat"
args = ["{secret}"]
timeout_ms = 2000
refresh_interval_ms = 0
'''

text = ""
if os.path.isfile(config):
    text = open(config, encoding="utf-8").read()

# Strip previous latinrouter provider blocks (simple heuristic)
text = re.sub(
    rf"\n?# LatinRouter — managed by latinrouter_agentes installer\n\[model_providers\.{re.escape(pid)}\][\s\S]*?(?=\n\[|\Z)",
    "\n",
    text,
)
text = re.sub(
    rf"\n?\[model_providers\.{re.escape(pid)}\][\s\S]*?(?=\n\[|\Z)",
    "\n",
    text,
)
text = re.sub(
    rf"\n?\[model_providers\.{re.escape(pid)}\.auth\][\s\S]*?(?=\n\[|\Z)",
    "\n",
    text,
)
text = text.rstrip() + "\n" + block
open(config, "w", encoding="utf-8").write(text)

# Profile activation
prof = f'''# LatinRouter profile — managed by latinrouter_agentes
model_provider = "{pid}"
'''
if model_id:
    prof += f'model = "{model_id}"\n'
open(profile, "w", encoding="utf-8").write(prof)
print(config)
PY
}

# ---------------------------------------------------------------------------
echo "$(msg banner)"
echo "$(msg home "$CODEX_HOME")"

if ! codex_available; then
  echo "$(msg no_bin)"
  # Skip "Start Codex now?" and other prompts so our installer can continue.
  export CODEX_NON_INTERACTIVE=1
  curl -fsSL "$OFFICIAL_INSTALL_URL" | sh
  refresh_path
  # Standalone install puts binary in ~/.local/bin
  export PATH="${HOME}/.local/bin:${HOME}/.codex/bin:${PATH}"
  hash -r 2>/dev/null || true
  if ! codex_available; then
    echo "$(msg path_err)"
    exit 1
  fi
  echo "$(msg ok_bin)"
fi

echo "$(msg install_prov)"
mkdir -p "$CODEX_HOME/secrets"

API_KEY="$(prompt_api_key)"
DEFAULT_MODEL=""
if [[ -n "$API_KEY" ]]; then
  umask 077
  printf '%s' "$API_KEY" > "$SECRET_FILE"
  chmod 600 "$SECRET_FILE" 2>/dev/null || true
  echo "$(msg key_saved "$SECRET_FILE")"
  export LATINROUTER_API_KEY="$API_KEY"
  fetched="$(fetch_models "$API_KEY" || true)"
  if [[ -n "$fetched" ]]; then
    count="$(printf '%s\n' "$fetched" | sed -n '1p')"
    DEFAULT_MODEL="$(printf '%s\n' "$fetched" | sed -n '2p')"
    echo "$(msg models_ok "$count" "$DEFAULT_MODEL")"
  else
    echo "$(msg models_fail)"
  fi
else
  # Ensure secret file exists as placeholder so auth.command does not fail loudly
  if [[ ! -f "$SECRET_FILE" ]]; then
    umask 077
    : > "$SECRET_FILE"
    chmod 600 "$SECRET_FILE" 2>/dev/null || true
  fi
  echo "$(msg key_skip)"
fi

cfg="$(write_config "$DEFAULT_MODEL")"
echo "$(msg config_ok "$cfg")"

if probe_responses; then
  echo "$(msg resp_ok)"
else
  echo "$(msg resp_warn)"
fi

echo ""
echo "$(msg next_title)"
echo "$(msg next_1 "$SIGNUP_URL")"
echo "$(msg next_2)"
echo "$(msg next_3)"
echo ""
