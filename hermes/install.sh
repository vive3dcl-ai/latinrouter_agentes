#!/usr/bin/env bash
# Install LatinRouter as a Hermes model-provider plugin.
#
# Platforms:
#   Linux / macOS / WSL2  → bash hermes/install.sh  (HERMES_HOME=~/.hermes)
#   Windows native        → use hermes/install.ps1  (%LOCALAPPDATA%\hermes)
#   Git Bash on Windows   → this script auto-detects LOCALAPPDATA\hermes
#
# Usage:
#   bash hermes/install.sh
#   curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh | bash
set -euo pipefail

PROVIDER_NAME="latinrouter"
BASE_URL="https://llm.latinrouter.ai/v1"
SIGNUP_URL="https://latinrouter.ai"

# ---------------------------------------------------------------------------
# Resolve HERMES_HOME (match Hermes platform defaults)
# ---------------------------------------------------------------------------
resolve_hermes_home() {
  if [[ -n "${HERMES_HOME:-}" ]]; then
    printf '%s' "$HERMES_HOME"
    return
  fi
  # Native Windows Hermes (Git Bash / MSYS / Cygwin) — not WSL
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*)
      if [[ -n "${LOCALAPPDATA:-}" ]]; then
        # Convert Windows path if cygpath exists; else use as-is / forward slashes
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

# Hint if someone runs bash installer on Windows without Git Bash paths
if [[ "$(uname -s 2>/dev/null || true)" == MINGW* ]] || [[ "$(uname -s 2>/dev/null || true)" == MSYS* ]]; then
  :
elif [[ -n "${WINDIR:-}" && -z "${WSL_DISTRO_NAME:-}" && -z "${HERMES_HOME_SET_BY_USER:-}" ]]; then
  # Rare: bash inside some Windows env — prefer PowerShell installer messaging later
  true
fi

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

# When piped via curl, BASH_SOURCE may be empty or /dev/fd/* — write embedded copy.
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
hermes model   # elegir LatinRouter → pegar API key → lista de modelos
hermes
```

Key: https://latinrouter.ai
MD
}

# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------
echo "==> LatinRouter provider for Hermes"
echo "    HERMES_HOME=$HERMES_HOME"
echo "    Platforms: Linux / macOS / WSL2 (this script); Windows native → install.ps1"

if [[ ! -d "$HERMES_HOME" ]]; then
  echo ""
  echo "WARNING: $HERMES_HOME does not exist."
  echo "Install Hermes first:"
  echo "  Linux/macOS/WSL: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
  echo "  Windows native:  iex (irm https://hermes-agent.nousresearch.com/install.ps1)"
  echo ""
  # Non-interactive (curl | bash): create dir and continue
  if [[ ! -t 0 ]]; then
    echo "Non-interactive mode: creating $HERMES_HOME"
    mkdir -p "$HERMES_HOME"
  else
    read -r -p "Create $HERMES_HOME and continue anyway? [y/N] " reply || true
    case "${reply:-}" in
      y|Y|yes|YES) mkdir -p "$HERMES_HOME" ;;
      *)
        echo "Aborted. Install Hermes, then re-run this script."
        exit 1
        ;;
    esac
  fi
fi

if ! command -v hermes >/dev/null 2>&1; then
  echo "WARNING: 'hermes' not found in PATH. Plugin will still be installed;"
  echo "         open a new shell after installing Hermes."
fi

# ---------------------------------------------------------------------------
# Install plugin
# ---------------------------------------------------------------------------
DEST="$HERMES_HOME/plugins/model-providers/${PROVIDER_NAME}"
mkdir -p "$(dirname "$DEST")"

if [[ -n "$PLUGIN_SRC" ]]; then
  echo "==> Copying plugin from $PLUGIN_SRC"
  rm -rf "$DEST"
  mkdir -p "$DEST"
  cp -a "$PLUGIN_SRC/." "$DEST/"
else
  echo "==> Writing embedded plugin (curl | bash mode)"
  rm -rf "$DEST"
  write_embedded_plugin "$DEST"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "Installed: $DEST"
echo ""
echo "Next steps:"
echo "  1. Get an API key at $SIGNUP_URL"
echo "  2. Run:  hermes model"
echo "  3. Select: LatinRouter"
echo "  4. Paste your LATINROUTER_API_KEY when prompted"
echo "  5. Hermes lista modelos automáticamente desde $BASE_URL/models"
echo "  6. Start chatting:  hermes"
echo ""
echo "Optional: set the key manually in $HERMES_HOME/.env"
echo "  LATINROUTER_API_KEY=sk-..."
echo ""
echo "Windows native users: prefer  powershell -File hermes/install.ps1"
echo ""
