#!/usr/bin/env bash
# Install LatinRouter as an OpenCode provider (plugin + config).
#
# Behavior:
#   1. No OpenCode     → install from official opencode.ai installer
#   2. Prompt API key  → optional; blank = configure later via /connect
#   3. Drop plugin + merge ~/.config/opencode/opencode.json
#
# Language: automatic from LANG/LC_* (es → Spanish, else English).
#
# Usage:
#   bash opencode/install.sh
#   curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
set -euo pipefail

PROVIDER_ID="latinrouter"
BASE_URL="https://llm.latinrouter.ai/v1"
SIGNUP_URL="https://latinrouter.ai"
DISPLAY_NAME="LatinRouter (Gateway IA Centralizado para Latinoamérica)"
OFFICIAL_INSTALL_URL="https://opencode.ai/install"

# ---------------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------------
detect_lang() {
  local loc="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
  loc="$(printf '%s' "$loc" | tr '[:upper:]' '[:lower:]')"
  case "$loc" in
    es|es_*|*.es|*.es_*|*es_es*|*es_mx*|*es_ar*|*es_co*|*es_cl*|*es_pe*|*es_ve*)
      echo es ;;
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
        banner)        text="==> LatinRouter + OpenCode" ;;
        home)          text="    Config: %s" ;;
        no_oc)         text="==> OpenCode no encontrado — instalando desde el instalador oficial" ;;
        oc_ok)         text="✓ OpenCode instalado" ;;
        oc_path_err)   text="ERROR: OpenCode instalado pero 'opencode' no está en el PATH. Abre una terminal nueva y re-ejecuta." ;;
        install_prov)  text="==> Instalando proveedor LatinRouter" ;;
        plugin_ok)     text="✓ Plugin instalado → %s" ;;
        config_ok)     text="✓ Config actualizada → %s" ;;
        key_prompt)    text="API key de LatinRouter (Enter para omitir y usar /connect después): " ;;
        key_saved)     text="✓ API key guardada" ;;
        key_skip)      text="==> Sin key — usa /connect → LatinRouter dentro de OpenCode" ;;
        models_ok)     text="✓ Modelos detectados: %s (default: %s)" ;;
        models_fail)   text="ADVERTENCIA: no se pudo listar /v1/models — configura la key y usa /models" ;;
        next_title)    text="Siguientes pasos:" ;;
        next_1)        text="  1. Obtén una key en %s (si aún no tienes)" ;;
        next_2)        text="  2. Ejecuta:  opencode" ;;
        next_3)        text="  3. /connect → LatinRouter → pega tu API key (si omitiste el paso)" ;;
        next_4)        text="  4. /models → elige un modelo del gateway" ;;
        *)             text="$key" ;;
      esac
      ;;
    *)
      case "$key" in
        banner)        text="==> LatinRouter + OpenCode" ;;
        home)          text="    Config: %s" ;;
        no_oc)         text="==> OpenCode not found — installing from official installer" ;;
        oc_ok)         text="✓ OpenCode installed" ;;
        oc_path_err)   text="ERROR: OpenCode installed but 'opencode' is not on PATH. Open a new terminal and re-run." ;;
        install_prov)  text="==> Installing LatinRouter provider" ;;
        plugin_ok)     text="✓ Plugin installed → %s" ;;
        config_ok)     text="✓ Config updated → %s" ;;
        key_prompt)    text="LatinRouter API key (Enter to skip and use /connect later): " ;;
        key_saved)     text="✓ API key saved" ;;
        key_skip)      text="==> No key — use /connect → LatinRouter inside OpenCode" ;;
        models_ok)     text="✓ Models found: %s (default: %s)" ;;
        models_fail)   text="WARNING: could not list /v1/models — set the key and use /models" ;;
        next_title)    text="Next steps:" ;;
        next_1)        text="  1. Get a key at %s (if you don't have one)" ;;
        next_2)        text="  2. Run:  opencode" ;;
        next_3)        text="  3. /connect → LatinRouter → paste your API key (if you skipped)" ;;
        next_4)        text="  4. /models → pick a model from the gateway" ;;
        *)             text="$key" ;;
      esac
      ;;
  esac
  # shellcheck disable=SC2059
  printf "$text" "$@"
}

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
resolve_config_dir() {
  if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    printf '%s' "$XDG_CONFIG_HOME/opencode"
  else
    printf '%s' "${HOME}/.config/opencode"
  fi
}

resolve_data_dir() {
  if [[ -n "${XDG_DATA_HOME:-}" ]]; then
    printf '%s' "$XDG_DATA_HOME/opencode"
  else
    printf '%s' "${HOME}/.local/share/opencode"
  fi
}

resolve_state_dir() {
  if [[ -n "${XDG_STATE_HOME:-}" ]]; then
    printf '%s' "$XDG_STATE_HOME/opencode"
  else
    printf '%s' "${HOME}/.local/state/opencode"
  fi
}

CONFIG_DIR="$(resolve_config_dir)"
DATA_DIR="$(resolve_data_dir)"
STATE_DIR="$(resolve_state_dir)"
PLUGINS_DIR="$CONFIG_DIR/plugins"
CONFIG_FILE="$CONFIG_DIR/opencode.json"
AUTH_FILE="$DATA_DIR/auth.json"
MODEL_STATE="$STATE_DIR/model.json"

refresh_path() {
  export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
  hash -r 2>/dev/null || true
}

opencode_available() {
  refresh_path
  command -v opencode >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Plugin source
# ---------------------------------------------------------------------------
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
PLUGIN_SRC=""
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/plugin/latinrouter.js" ]]; then
  PLUGIN_SRC="$SCRIPT_DIR/plugin/latinrouter.js"
fi

write_embedded_plugin() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  if [[ -n "$PLUGIN_SRC" ]]; then
    cp -a "$PLUGIN_SRC" "$dest"
  else
    # curl | bash: fetch from GitHub raw
    curl -fsSL \
      "https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/plugin/latinrouter.js" \
      -o "$dest"
  fi
}

# ---------------------------------------------------------------------------
# JSON helpers (python3)
# ---------------------------------------------------------------------------
merge_config() {
  local model_id="${1:-}"
  python3 - "$CONFIG_FILE" "$PROVIDER_ID" "$DISPLAY_NAME" "$BASE_URL" "$model_id" <<'PY'
import json, sys, os
path, pid, name, base, model_id = sys.argv[1:6]
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {}
if os.path.isfile(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f) or {}
    except Exception:
        data = {}
if not isinstance(data, dict):
    data = {}
data.setdefault("$schema", "https://opencode.ai/config.json")
providers = data.setdefault("provider", {})
if not isinstance(providers, dict):
    providers = {}
    data["provider"] = providers
entry = providers.get(pid) if isinstance(providers.get(pid), dict) else {}
entry.update({
    "npm": "@ai-sdk/openai-compatible",
    "name": name,
    "env": ["LATINROUTER_API_KEY"],
    "options": {
        **(entry.get("options") if isinstance(entry.get("options"), dict) else {}),
        "baseURL": base,
    },
})
providers[pid] = entry
if model_id:
    data["model"] = f"{pid}/{model_id}"
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(path)
PY
}

save_auth_key() {
  local key="$1"
  python3 - "$AUTH_FILE" "$PROVIDER_ID" "$key" <<'PY'
import json, sys, os
path, pid, key = sys.argv[1:4]
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {}
if os.path.isfile(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f) or {}
    except Exception:
        data = {}
if not isinstance(data, dict):
    data = {}
data[pid] = {"type": "api", "key": key}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
}

fetch_first_model() {
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

save_model_state() {
  local model_id="$1"
  python3 - "$MODEL_STATE" "$PROVIDER_ID" "$model_id" <<'PY'
import json, sys, os
path, pid, mid = sys.argv[1:4]
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {"recent": [{"providerID": pid, "modelID": mid}]}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

prompt_api_key() {
  local reply=""
  if [[ -r /dev/tty && -w /dev/tty ]]; then
    printf '%s' "$(msg key_prompt)" > /dev/tty
    IFS= read -r reply < /dev/tty || true
  elif [[ -t 0 && -t 1 ]]; then
    read -r -p "$(msg key_prompt)" reply || true
  else
    reply=""
  fi
  printf '%s' "$(printf '%s' "$reply" | tr -d '[:space:]')"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "$(msg banner)"
echo "$(msg home "$CONFIG_DIR")"

if ! opencode_available; then
  echo "$(msg no_oc)"
  echo "    $OFFICIAL_INSTALL_URL"
  curl -fsSL "$OFFICIAL_INSTALL_URL" | bash
  refresh_path
  if ! opencode_available; then
    echo "$(msg oc_path_err)"
    exit 1
  fi
  echo "$(msg oc_ok)"
fi

echo "$(msg install_prov)"
mkdir -p "$PLUGINS_DIR" "$DATA_DIR" "$STATE_DIR"
PLUGIN_DEST="$PLUGINS_DIR/latinrouter.js"
write_embedded_plugin "$PLUGIN_DEST"
echo "$(msg plugin_ok "$PLUGIN_DEST")"

API_KEY="$(prompt_api_key)"
DEFAULT_MODEL=""
if [[ -n "$API_KEY" ]]; then
  save_auth_key "$API_KEY"
  echo "$(msg key_saved)"
  fetched="$(fetch_first_model "$API_KEY" || true)"
  if [[ -n "$fetched" ]]; then
    count="$(printf '%s\n' "$fetched" | sed -n '1p')"
    DEFAULT_MODEL="$(printf '%s\n' "$fetched" | sed -n '2p')"
    echo "$(msg models_ok "$count" "$DEFAULT_MODEL")"
    save_model_state "$DEFAULT_MODEL"
  else
    echo "$(msg models_fail)"
  fi
else
  echo "$(msg key_skip)"
fi

cfg_path="$(merge_config "$DEFAULT_MODEL")"
echo "$(msg config_ok "$cfg_path")"

echo ""
echo "$(msg next_title)"
echo "$(msg next_1 "$SIGNUP_URL")"
echo "$(msg next_2)"
echo "$(msg next_3)"
echo "$(msg next_4)"
echo ""
