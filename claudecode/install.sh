#!/usr/bin/env bash
# Install LatinRouter for Anthropic Claude Code (settings.json env).
#
# Behavior:
#   1. No Claude Code → official claude.ai/install.sh
#   2. Prompt API key → ~/.claude/settings.json env (ANTHROPIC_BASE_URL + AUTH_TOKEN)
#   3. Warn if gateway lacks POST /v1/messages (required by Claude Code)
#
# Note: Claude Code speaks Anthropic Messages, not OpenAI Chat Completions.
# LatinRouter must expose /v1/messages (or use a bridge) for chat to work.
#
# Usage:
#   bash claudecode/install.sh
#   curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/claudecode/install.sh | bash
set -euo pipefail

BASE_ROOT="https://llm.latinrouter.ai"
SIGNUP_URL="https://latinrouter.ai"
OFFICIAL_INSTALL_URL="https://claude.ai/install.sh"

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
        banner)       text="==> LatinRouter + Claude Code" ;;
        home)         text="    Config: %s" ;;
        no_bin)       text="==> Claude Code no encontrado — instalando desde el oficial" ;;
        ok_bin)       text="✓ Claude Code instalado" ;;
        path_err)     text="ERROR: 'claude' no está en el PATH. Abre una terminal nueva y re-ejecuta." ;;
        install_prov) text="==> Configurando LatinRouter en settings.json" ;;
        config_ok)    text="✓ Settings actualizados → %s" ;;
        key_prompt)   text="API key de LatinRouter (Enter para omitir): " ;;
        key_saved)    text="✓ API key escrita en settings (ANTHROPIC_AUTH_TOKEN)" ;;
        key_skip)     text="==> Sin key — edita ~/.claude/settings.json o exporta ANTHROPIC_AUTH_TOKEN" ;;
        msg_warn)     text="ADVERTENCIA: el gateway aún no expone POST /v1/messages (Claude Code lo requiere). La config queda lista; el chat fallará hasta que LatinRouter agregue Anthropic Messages." ;;
        msg_ok)       text="✓ Gateway responde en /v1/messages" ;;
        next_title)   text="Siguientes pasos:" ;;
        next_1)       text="  1. Key en %s" ;;
        next_2)       text="  2. Ejecuta:  claude" ;;
        next_3)       text="  3. /status  (verifica base URL / auth)" ;;
        *)            text="$key" ;;
      esac ;;
    *)
      case "$key" in
        banner)       text="==> LatinRouter + Claude Code" ;;
        home)         text="    Config: %s" ;;
        no_bin)       text="==> Claude Code not found — installing from official installer" ;;
        ok_bin)       text="✓ Claude Code installed" ;;
        path_err)     text="ERROR: 'claude' is not on PATH. Open a new terminal and re-run." ;;
        install_prov) text="==> Configuring LatinRouter in settings.json" ;;
        config_ok)    text="✓ Settings updated → %s" ;;
        key_prompt)   text="LatinRouter API key (Enter to skip): " ;;
        key_saved)    text="✓ API key written to settings (ANTHROPIC_AUTH_TOKEN)" ;;
        key_skip)     text="==> No key — edit ~/.claude/settings.json or export ANTHROPIC_AUTH_TOKEN" ;;
        msg_warn)     text="WARNING: gateway still lacks POST /v1/messages (required by Claude Code). Config is ready; chat will fail until LatinRouter adds Anthropic Messages." ;;
        msg_ok)       text="✓ Gateway responds on /v1/messages" ;;
        next_title)   text="Next steps:" ;;
        next_1)       text="  1. Key at %s" ;;
        next_2)       text="  2. Run:  claude" ;;
        next_3)       text="  3. /status  (verify base URL / auth)" ;;
        *)            text="$key" ;;
      esac ;;
  esac
  # shellcheck disable=SC2059
  printf "$text" "$@"
}

CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

refresh_path() {
  export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
  hash -r 2>/dev/null || true
}

claude_available() {
  refresh_path
  command -v claude >/dev/null 2>&1
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

probe_messages() {
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "${BASE_ROOT}/v1/messages" \
    -H "Authorization: Bearer probe" -H "Content-Type: application/json" \
    -H "anthropic-version: 2023-06-01" \
    -d '{}' 2>/dev/null || echo 000)"
  case "$code" in
    404|000) return 1 ;;
    *) return 0 ;;
  esac
}

merge_settings() {
  local key="${1:-}"
  python3 - "$SETTINGS_FILE" "$BASE_ROOT" "$key" <<'PY'
import json, os, sys
path, base, key = sys.argv[1:4]
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {}
if os.path.isfile(path):
    try:
        data = json.load(open(path, encoding="utf-8")) or {}
    except Exception:
        data = {}
if not isinstance(data, dict):
    data = {}
env = data.setdefault("env", {})
if not isinstance(env, dict):
    env = {}
    data["env"] = env
# Claude Code appends /v1/messages — base URL must NOT include /v1
env["ANTHROPIC_BASE_URL"] = base.rstrip("/")
env["CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY"] = "1"
if key:
    env["ANTHROPIC_AUTH_TOKEN"] = key
    # Also set API_KEY for clients that prefer x-api-key
    env["ANTHROPIC_API_KEY"] = key
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(path)
PY
}

echo "$(msg banner)"
echo "$(msg home "$SETTINGS_FILE")"

if ! claude_available; then
  echo "$(msg no_bin)"
  curl -fsSL "$OFFICIAL_INSTALL_URL" | bash
  refresh_path
  if ! claude_available; then
    echo "$(msg path_err)"
    exit 1
  fi
  echo "$(msg ok_bin)"
fi

echo "$(msg install_prov)"
API_KEY="$(prompt_api_key)"
if [[ -n "$API_KEY" ]]; then
  echo "$(msg key_saved)"
else
  echo "$(msg key_skip)"
fi

cfg="$(merge_settings "$API_KEY")"
echo "$(msg config_ok "$cfg")"

if probe_messages; then
  echo "$(msg msg_ok)"
else
  echo "$(msg msg_warn)"
fi

echo ""
echo "$(msg next_title)"
echo "$(msg next_1 "$SIGNUP_URL")"
echo "$(msg next_2)"
echo "$(msg next_3)"
echo ""
