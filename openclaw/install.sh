#!/usr/bin/env bash
# Install LatinRouter as an OpenClaw provider plugin.
#
# Behavior:
#   1. No OpenClaw     → install from official openclaw.ai installer (--no-onboard)
#   2. OpenClaw outdated → ask to update (default: Yes) when check is available
#   3. Install/link plugin → ~/.openclaw/extensions/latinrouter
#   4. Prompt API key → optional; blank = configure later in onboard wizard
#
# Language: automatic from LANG/LC_* (es → Spanish, else English).
# Skip update: LATINROUTER_SKIP_OPENCLAW_UPDATE=1
#
# Usage:
#   bash openclaw/install.sh
#   curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.sh | bash
set -euo pipefail

PROVIDER_ID="latinrouter"
BASE_URL="https://llm.latinrouter.ai/v1"
SIGNUP_URL="https://latinrouter.ai"
DISPLAY_NAME="LatinRouter (Gateway IA Centralizado para Latinoamérica)"
OFFICIAL_INSTALL_URL="https://openclaw.ai/install.sh"
PLUGIN_RAW_BASE="https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/plugin"

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
        banner)        text="==> LatinRouter + OpenClaw" ;;
        home)          text="    Home: %s" ;;
        no_oc)         text="==> OpenClaw no encontrado — instalando desde el instalador oficial" ;;
        oc_ok)         text="✓ OpenClaw instalado" ;;
        oc_path_err)   text="ERROR: OpenClaw instalado pero 'openclaw' no está en el PATH. Abre una terminal nueva y re-ejecuta." ;;
        checking)      text="==> Comprobando actualizaciones de OpenClaw…" ;;
        update_prompt) text="OpenClaw puede tener actualizaciones. ¿Actualizar ahora? [S/n] " ;;
        updating)      text="==> Actualizando OpenClaw…" ;;
        updated)       text="✓ OpenClaw actualizado" ;;
        update_fail)   text="ADVERTENCIA: falló la actualización — se continúa con LatinRouter" ;;
        skip_update)   text="==> Se omite la actualización de OpenClaw" ;;
        no_tty_update) text="==> No hay terminal interactiva; se omite la actualización de OpenClaw" ;;
        install_prov)  text="==> Instalando proveedor LatinRouter" ;;
        plugin_ok)     text="✓ Plugin instalado → %s" ;;
        key_prompt)    text="API key de LatinRouter (Enter para omitir y usar el wizard después): " ;;
        key_saved)     text="✓ API key guardada en ~/.openclaw/.env" ;;
        key_skip)      text="==> Sin key — usa: openclaw onboard → More… → LatinRouter" ;;
        auth_ok)       text="✓ Auth LatinRouter configurada (onboard non-interactive)" ;;
        auth_fail)     text="ADVERTENCIA: no se pudo aplicar auth automática — completa con openclaw onboard" ;;
        next_title)    text="Siguientes pasos:" ;;
        next_1)        text="  1. Obtén una key en %s (si aún no tienes)" ;;
        next_2)        text="  2. Ejecuta:  openclaw onboard" ;;
        next_3)        text="  3. More… → LatinRouter → pega tu API key" ;;
        next_4)        text="  4. Los modelos se cargan desde %s/models" ;;
        next_5)        text="  5. Verifica:  openclaw models list" ;;
        *)             text="$key" ;;
      esac
      ;;
    *)
      case "$key" in
        banner)        text="==> LatinRouter + OpenClaw" ;;
        home)          text="    Home: %s" ;;
        no_oc)         text="==> OpenClaw not found — installing from official installer" ;;
        oc_ok)         text="✓ OpenClaw installed" ;;
        oc_path_err)   text="ERROR: OpenClaw installed but 'openclaw' is not on PATH. Open a new terminal and re-run." ;;
        checking)      text="==> Checking OpenClaw updates…" ;;
        update_prompt) text="OpenClaw may have updates. Update now? [Y/n] " ;;
        updating)      text="==> Updating OpenClaw…" ;;
        updated)       text="✓ OpenClaw updated" ;;
        update_fail)   text="WARNING: update failed — continuing with LatinRouter" ;;
        skip_update)   text="==> Skipping OpenClaw update" ;;
        no_tty_update) text="==> No interactive terminal; skipping OpenClaw update" ;;
        install_prov)  text="==> Installing LatinRouter provider" ;;
        plugin_ok)     text="✓ Plugin installed → %s" ;;
        key_prompt)    text="LatinRouter API key (Enter to skip and use the wizard later): " ;;
        key_saved)     text="✓ API key saved to ~/.openclaw/.env" ;;
        key_skip)      text="==> No key — run: openclaw onboard → More… → LatinRouter" ;;
        auth_ok)       text="✓ LatinRouter auth configured (non-interactive onboard)" ;;
        auth_fail)     text="WARNING: could not apply auth automatically — finish with openclaw onboard" ;;
        next_title)    text="Next steps:" ;;
        next_1)        text="  1. Get a key at %s (if you don't have one)" ;;
        next_2)        text="  2. Run:  openclaw onboard" ;;
        next_3)        text="  3. More… → LatinRouter → paste your API key" ;;
        next_4)        text="  4. Models load from %s/models" ;;
        next_5)        text="  5. Check:  openclaw models list" ;;
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
resolve_state_dir() {
  if [[ -n "${OPENCLAW_STATE_DIR:-}" ]]; then
    printf '%s' "$OPENCLAW_STATE_DIR"
  elif [[ -n "${OPENCLAW_HOME:-}" ]]; then
    printf '%s' "$OPENCLAW_HOME"
  else
    printf '%s' "${HOME}/.openclaw"
  fi
}

STATE_DIR="$(resolve_state_dir)"
EXT_DIR="$STATE_DIR/extensions/$PROVIDER_ID"
ENV_FILE="$STATE_DIR/.env"

refresh_path() {
  export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
  # npm global
  if command -v npm >/dev/null 2>&1; then
    local np
    np="$(npm prefix -g 2>/dev/null)/bin" || true
    [[ -n "${np:-}" && -d "$np" ]] && export PATH="$np:$PATH"
  fi
  hash -r 2>/dev/null || true
}

openclaw_available() {
  refresh_path
  command -v openclaw >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Plugin source
# ---------------------------------------------------------------------------
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
PLUGIN_SRC=""
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/plugin/index.ts" ]]; then
  PLUGIN_SRC="$SCRIPT_DIR/plugin"
fi

install_plugin_files() {
  mkdir -p "$EXT_DIR"
  if [[ -n "$PLUGIN_SRC" ]]; then
    cp -a "$PLUGIN_SRC/index.ts" "$EXT_DIR/"
    cp -a "$PLUGIN_SRC/package.json" "$EXT_DIR/"
    cp -a "$PLUGIN_SRC/openclaw.plugin.json" "$EXT_DIR/"
  else
    curl -fsSL "$PLUGIN_RAW_BASE/index.ts" -o "$EXT_DIR/index.ts"
    curl -fsSL "$PLUGIN_RAW_BASE/package.json" -o "$EXT_DIR/package.json"
    curl -fsSL "$PLUGIN_RAW_BASE/openclaw.plugin.json" -o "$EXT_DIR/openclaw.plugin.json"
  fi
}

register_plugin() {
  # Prefer official install --link so allowlists / records are updated.
  if openclaw plugins install --link "$EXT_DIR" >/dev/null 2>&1; then
    openclaw plugins enable "$PROVIDER_ID" >/dev/null 2>&1 || true
    return 0
  fi
  # Fallback: ensure load path + allow
  openclaw plugins enable "$PROVIDER_ID" >/dev/null 2>&1 || true
  return 0
}

prompt_update() {
  local reply=""
  if [[ "${LATINROUTER_SKIP_OPENCLAW_UPDATE:-}" == "1" ]]; then
    return 1
  fi
  if { true >/dev/tty; } 2>/dev/null; then
    printf '%s' "$(msg update_prompt)" > /dev/tty
    IFS= read -r reply < /dev/tty || true
  elif [[ -t 0 && -t 1 ]]; then
    read -r -p "$(msg update_prompt)" reply || true
  else
    echo "$(msg no_tty_update)"
    return 1
  fi
  reply="$(printf '%s' "$reply" | tr -d '[:space:]')"
  case "$reply" in
    n|N|no|NO) return 1 ;;
    *) return 0 ;;
  esac
}

maybe_update_openclaw() {
  echo "$(msg checking)"
  # Soft check: if `openclaw update --help` exists, ask (no reliable --check on all versions)
  if ! openclaw update --help >/dev/null 2>&1; then
    return 0
  fi
  if prompt_update; then
    echo "$(msg updating)"
    if openclaw update; then
      refresh_path
      echo "$(msg updated)"
    else
      echo "$(msg update_fail)"
    fi
  else
    echo "$(msg skip_update)"
  fi
}

prompt_api_key() {
  local reply=""
  if { true >/dev/tty; } 2>/dev/null; then
    printf '%s' "$(msg key_prompt)" > /dev/tty
    IFS= read -r reply < /dev/tty || true
  elif [[ -t 0 && -t 1 ]]; then
    read -r -p "$(msg key_prompt)" reply || true
  else
    reply=""
  fi
  printf '%s' "$(printf '%s' "$reply" | tr -d '[:space:]')"
}

save_env_key() {
  local key="$1"
  mkdir -p "$STATE_DIR"
  touch "$ENV_FILE"
  if grep -q '^LATINROUTER_API_KEY=' "$ENV_FILE" 2>/dev/null; then
    # portable in-place replace
    python3 - "$ENV_FILE" "$key" <<'PY'
import sys
path, key = sys.argv[1:3]
lines = open(path, encoding="utf-8").read().splitlines()
out, seen = [], False
for line in lines:
    if line.startswith("LATINROUTER_API_KEY="):
        out.append(f"LATINROUTER_API_KEY={key}")
        seen = True
    else:
        out.append(line)
if not seen:
    out.append(f"LATINROUTER_API_KEY={key}")
open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
  else
    printf 'LATINROUTER_API_KEY=%s\n' "$key" >> "$ENV_FILE"
  fi
  export LATINROUTER_API_KEY="$key"
}

apply_auth_noninteractive() {
  local key="$1"
  # Prefer non-interactive onboard auth so user never needs the picker.
  if openclaw onboard --help 2>&1 | grep -q 'latinrouter-api-key\|non-interactive\|auth-choice'; then
    if openclaw onboard --non-interactive --accept-risk \
      --auth-choice latinrouter-api-key \
      --latinrouter-api-key "$key" \
      >/dev/null 2>&1; then
      echo "$(msg auth_ok)"
      return 0
    fi
  fi
  echo "$(msg auth_fail)"
  return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "$(msg banner)"
echo "$(msg home "$STATE_DIR")"

if ! openclaw_available; then
  echo "$(msg no_oc)"
  echo "    $OFFICIAL_INSTALL_URL"
  curl -fsSL "$OFFICIAL_INSTALL_URL" | bash -s -- --no-onboard
  refresh_path
  if ! openclaw_available; then
    echo "$(msg oc_path_err)"
    exit 1
  fi
  echo "$(msg oc_ok)"
else
  maybe_update_openclaw
fi

echo "$(msg install_prov)"
install_plugin_files
register_plugin
echo "$(msg plugin_ok "$EXT_DIR")"

API_KEY="$(prompt_api_key)"
if [[ -n "$API_KEY" ]]; then
  save_env_key "$API_KEY"
  echo "$(msg key_saved)"
  apply_auth_noninteractive "$API_KEY"
else
  echo "$(msg key_skip)"
fi

echo ""
echo "$(msg next_title)"
echo "$(msg next_1 "$SIGNUP_URL")"
echo "$(msg next_2)"
echo "$(msg next_3)"
echo "$(msg next_4 "$BASE_URL")"
echo "$(msg next_5)"
echo ""
