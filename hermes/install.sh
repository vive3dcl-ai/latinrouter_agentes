#!/usr/bin/env bash
# Install LatinRouter as a Hermes model-provider plugin.
#
# Behavior:
#   1. No Hermes            → install from official NousResearch installer
#   2. Hermes outdated      → ask to update (default: Yes), then install plugin
#   3. Hermes up to date    → install LatinRouter provider quietly
#
# Platforms:
#   Linux / macOS / WSL2  → this script  (HERMES_HOME=~/.hermes)
#   Windows native        → hermes/install.ps1
#
# Usage:
#   bash hermes/install.sh
#   curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh | bash
set -euo pipefail

PROVIDER_NAME="latinrouter"
BASE_URL="https://llm.latinrouter.ai/v1"
SIGNUP_URL="https://latinrouter.ai"
OFFICIAL_INSTALL_URL="https://hermes-agent.nousresearch.com/install.sh"

# Quiet when Hermes is already current (plugin-only path)
QUIET=0
log()  { [[ "$QUIET" -eq 1 ]] || echo "$@"; }
logf() { echo "$@"; }  # always print (errors / final status)

is_interactive() {
  [[ -t 0 && -t 1 ]]
}

# ---------------------------------------------------------------------------
# Resolve HERMES_HOME (match Hermes platform defaults)
# ---------------------------------------------------------------------------
resolve_hermes_home() {
  if [[ -n "${HERMES_HOME:-}" ]]; then
    printf '%s' "$HERMES_HOME"
    return
  fi
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*)
      if [[ -n "${LOCALAPPDATA:-}" ]]; then
        if command -v cygpath >/dev/null 2>&1; then
          cygpath -u "$LOCALAPPDATA/hermes"
        else
          printf '%s' "${LOCALAPPDATA}//hermes" | sed 's|\\|/|g'
        fi
        return
      fi
      ;;
  esac
  printf '%s' "${HOME}/.hermes"
}

HERMES_HOME="$(resolve_hermes_home)"
export HERMES_HOME

# Ensure common Hermes bin dirs are on PATH (fresh install / new shell)
refresh_path() {
  export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
  hash -r 2>/dev/null || true
}

hermes_available() {
  refresh_path
  command -v hermes >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Locate plugin source (local clone vs curl | bash)
# ---------------------------------------------------------------------------
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

PLUGIN_SRC=""
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/plugin/${PROVIDER_NAME}/__init__.py" ]]; then
  PLUGIN_SRC="$SCRIPT_DIR/plugin/${PROVIDER_NAME}"
fi

write_embedded_plugin() {
  local dest="$1"
  mkdir -p "$dest"
  cat >"$dest/__init__.py" <<'PY'
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
PY

  cat >"$dest/plugin.yaml" <<'YAML'
name: latinrouter
kind: model-provider
version: 1.0.0
description: LatinRouter — gateway OpenAI-compatible para Latinoamérica
author: LatinRouter
YAML

  cat >"$dest/README.md" <<'MD'
# LatinRouter — Hermes model provider

| Campo | Valor |
|-------|--------|
| Provider id | `latinrouter` |
| Base URL | `https://llm.latinrouter.ai/v1` |
| Models | `GET /v1/models` (automático) |
| API key env | `LATINROUTER_API_KEY` |

```bash
hermes model
hermes
```

Key: https://latinrouter.ai
MD
}

install_plugin() {
  local dest="$HERMES_HOME/plugins/model-providers/${PROVIDER_NAME}"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  mkdir -p "$dest"

  if [[ -n "$PLUGIN_SRC" ]]; then
    log "==> Installing LatinRouter provider"
    cp -a "$PLUGIN_SRC/." "$dest/"
  else
    log "==> Installing LatinRouter provider"
    write_embedded_plugin "$dest"
  fi

  logf "✓ LatinRouter provider installed → $dest"
}

install_hermes_official() {
  logf "==> Hermes not found — installing from official installer"
  logf "    $OFFICIAL_INSTALL_URL"
  curl -fsSL "$OFFICIAL_INSTALL_URL" | bash -s -- --skip-setup
  refresh_path
  if ! hermes_available; then
    logf "ERROR: Hermes install finished but 'hermes' is not on PATH."
    logf "Open a new terminal and re-run this script, or add ~/.local/bin to PATH."
    exit 1
  fi
  logf "✓ Hermes installed"
}

# Returns 0 if update available, 1 if up to date, 2 if check failed
hermes_update_available() {
  local out
  if ! out="$(hermes update --check 2>&1)"; then
    # Some builds still print useful text on non-zero; fall through to parse
    :
  fi
  if printf '%s\n' "$out" | grep -qiE 'Update available|behind'; then
    printf '%s\n' "$out" | grep -iE 'Update available|behind' | head -5 >&2 || true
    return 0
  fi
  if printf '%s\n' "$out" | grep -qiE 'Already up to date|up to date'; then
    return 1
  fi
  # Ambiguous — treat as up to date to avoid surprising full upgrades
  return 1
}

prompt_update_hermes() {
  # Default Yes. Non-interactive → Yes.
  local reply
  if [[ "${LATINROUTER_SKIP_HERMES_UPDATE:-}" == "1" ]]; then
    return 1
  fi
  if ! is_interactive; then
    logf "==> Hermes is outdated — updating (non-interactive default: Yes)"
    return 0
  fi
  read -r -p "Hermes está desactualizado. ¿Actualizar ahora? [Y/n] " reply || true
  case "${reply:-Y}" in
    n|N|no|NO) return 1 ;;
    *) return 0 ;;
  esac
}

update_hermes() {
  logf "==> Updating Hermes…"
  # -y skips interactive migrate prompts; API keys are not wiped
  if hermes update -y; then
    refresh_path
    logf "✓ Hermes updated"
  else
    logf "WARNING: hermes update failed — continuing with LatinRouter provider install"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log "==> LatinRouter + Hermes"
log "    HERMES_HOME=$HERMES_HOME"

# 1) Ensure Hermes exists
if ! hermes_available; then
  install_hermes_official
  QUIET=0
else
  # 2) Check for updates
  log "==> Checking Hermes version…"
  set +e
  hermes_update_available
  status=$?
  set -e
  case "$status" in
    0)
      if prompt_update_hermes; then
        update_hermes
        QUIET=0
      else
        log "==> Skipping Hermes update"
        QUIET=0
      fi
      ;;
    *)
      # Up to date (or check inconclusive) → quiet plugin-only install
      QUIET=1
      ;;
  esac
fi

# Re-resolve home after possible Hermes install (may create ~/.hermes)
HERMES_HOME="$(resolve_hermes_home)"
export HERMES_HOME
mkdir -p "$HERMES_HOME"

# 3) Install LatinRouter provider
install_plugin

if [[ "$QUIET" -eq 1 ]]; then
  # Minimal next-step hint even in quiet mode
  logf "Next: hermes model  →  LatinRouter  →  paste API key  ($SIGNUP_URL)"
else
  echo ""
  echo "Next steps:"
  echo "  1. Get an API key at $SIGNUP_URL"
  echo "  2. Run:  hermes model"
  echo "  3. Select: LatinRouter"
  echo "  4. Paste your LATINROUTER_API_KEY when prompted"
  echo "  5. Models load automatically from $BASE_URL/models"
  echo "  6. Start chatting:  hermes"
  echo ""
fi
