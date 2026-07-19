#!/usr/bin/env bash
# Install LatinRouter as a Hermes model-provider plugin.
#
# Behavior:
#   1. No Hermes            → install from official NousResearch installer
#   2. Hermes outdated      → ask to update (default: Yes), then install plugin
#   3. Hermes up to date    → install LatinRouter provider quietly
#
# Language: automatic from LANG/LC_* (es → Spanish, else English).
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

# ---------------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------------
detect_lang() {
  local loc="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
  loc="$(printf '%s' "$loc" | tr '[:upper:]' '[:lower:]')"
  case "$loc" in
    es|es_*|*.es|*.es_*|*es_es*|*es_mx*|*es_ar*|*es_co*|*es_cl*|*es_pe*|*es_ve*|*es_uy*|*es_py*|*es_bo*|*es_ec*|*es_cr*|*es_pa*|*es_gt*|*es_hn*|*es_sv*|*es_ni*|*es_do*|*es_pr*|*es_cu*)
      echo es
      ;;
    *)
      echo en
      ;;
  esac
}

LR_LANG="$(detect_lang)"

# msg KEY [printf args...]
msg() {
  local key="$1"
  shift || true
  local text=""
  case "$LR_LANG" in
    es)
      case "$key" in
        banner)              text="==> LatinRouter + Hermes" ;;
        home)                text="    HERMES_HOME=%s" ;;
        checking)            text="==> Comprobando versión de Hermes…" ;;
        install_provider)    text="==> Instalando proveedor LatinRouter" ;;
        provider_ok)         text="✓ Proveedor LatinRouter instalado → %s" ;;
        hermes_missing)      text="==> Hermes no encontrado — instalando desde el instalador oficial" ;;
        hermes_ok)           text="✓ Hermes instalado" ;;
        hermes_path_err)     text="ERROR: la instalación de Hermes terminó pero 'hermes' no está en el PATH." ;;
        hermes_path_hint)    text="Abre una terminal nueva y vuelve a ejecutar este script, o añade ~/.local/bin al PATH." ;;
        update_prompt)       text="Hermes está desactualizado. ¿Actualizar ahora? [S/n] " ;;
        updating)            text="==> Actualizando Hermes…" ;;
        updated)             text="✓ Hermes actualizado" ;;
        update_fail)         text="ADVERTENCIA: falló 'hermes update' — se continúa con la instalación del proveedor LatinRouter" ;;
        skip_update)         text="==> Se omite la actualización de Hermes" ;;
        no_tty_update)       text="==> No hay terminal interactiva; se omite la actualización de Hermes" ;;
        next_quiet)          text="Siguiente: hermes model  →  LatinRouter  →  pega tu API key  (%s)" ;;
        next_title)          text="Siguientes pasos:" ;;
        next_1)              text="  1. Obtén una API key en %s" ;;
        next_2)              text="  2. Ejecuta:  hermes model" ;;
        next_3)              text="  3. Elige: LatinRouter" ;;
        next_4)              text="  4. Pega tu LATINROUTER_API_KEY cuando te la pida" ;;
        next_5)              text="  5. Los modelos se cargan solos desde %s/models" ;;
        next_6)              text="  6. Empieza a chatear:  hermes" ;;
        *)                   text="$key" ;;
      esac
      ;;
    *)
      case "$key" in
        banner)              text="==> LatinRouter + Hermes" ;;
        home)                text="    HERMES_HOME=%s" ;;
        checking)            text="==> Checking Hermes version…" ;;
        install_provider)    text="==> Installing LatinRouter provider" ;;
        provider_ok)         text="✓ LatinRouter provider installed → %s" ;;
        hermes_missing)      text="==> Hermes not found — installing from official installer" ;;
        hermes_ok)           text="✓ Hermes installed" ;;
        hermes_path_err)     text="ERROR: Hermes install finished but 'hermes' is not on PATH." ;;
        hermes_path_hint)    text="Open a new terminal and re-run this script, or add ~/.local/bin to PATH." ;;
        update_prompt)       text="Hermes is outdated. Update now? [Y/n] " ;;
        updating)            text="==> Updating Hermes…" ;;
        updated)             text="✓ Hermes updated" ;;
        update_fail)         text="WARNING: hermes update failed — continuing with LatinRouter provider install" ;;
        skip_update)         text="==> Skipping Hermes update" ;;
        no_tty_update)       text="==> No interactive terminal; skipping Hermes update" ;;
        next_quiet)          text="Next: hermes model  →  LatinRouter  →  paste API key  (%s)" ;;
        next_title)          text="Next steps:" ;;
        next_1)              text="  1. Get an API key at %s" ;;
        next_2)              text="  2. Run:  hermes model" ;;
        next_3)              text="  3. Select: LatinRouter" ;;
        next_4)              text="  4. Paste your LATINROUTER_API_KEY when prompted" ;;
        next_5)              text="  5. Models load automatically from %s/models" ;;
        next_6)              text="  6. Start chatting:  hermes" ;;
        *)                   text="$key" ;;
      esac
      ;;
  esac
  # shellcheck disable=SC2059
  printf "$text" "$@"
}

# Quiet when Hermes is already current (plugin-only path)
QUIET=0
log()  { [[ "$QUIET" -eq 1 ]] || echo "$@"; }
logf() { echo "$@"; }

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

from __future__ import annotations

import sys
import threading
import time

from providers import register_provider
from providers.base import ProviderProfile

_DISPLAY_NAME = "LatinRouter"
_DESCRIPTION = "Gateway IA Centralizado para Latinoamérica"

latinrouter = ProviderProfile(
    name="latinrouter",
    aliases=("latin-router", "lr"),
    env_vars=("LATINROUTER_API_KEY", "LATINROUTER_BASE_URL"),
    display_name=_DISPLAY_NAME,
    description=_DESCRIPTION,
    signup_url="https://latinrouter.ai",
    base_url="https://llm.latinrouter.ai/v1",
    models_url="https://llm.latinrouter.ai/v1/models",
    auth_type="api_key",
    # Empty: picker uses the live catalog from models_url after the user
    # enters LATINROUTER_API_KEY. Hermes falls back to this tuple only if
    # the /models request fails.
    fallback_models=(),
)

register_provider(latinrouter)


def _ensure_latinrouter_first() -> bool:
    """Move LatinRouter to index 0 in ``CANONICAL_PROVIDERS`` when present."""
    mod = sys.modules.get("hermes_cli.models")
    if mod is None:
        return False

    providers = getattr(mod, "CANONICAL_PROVIDERS", None)
    ProviderEntry = getattr(mod, "ProviderEntry", None)
    if providers is None or ProviderEntry is None:
        return False

    if not any(getattr(p, "slug", None) == "latinrouter" for p in providers):
        return False

    entry = ProviderEntry("latinrouter", _DISPLAY_NAME, _DESCRIPTION)
    rest = [p for p in providers if getattr(p, "slug", None) != "latinrouter"]
    providers[:] = [entry] + rest

    labels = getattr(mod, "_PROVIDER_LABELS", None)
    if isinstance(labels, dict):
        labels["latinrouter"] = _DISPLAY_NAME
    return True


def _prefer_latinrouter_first() -> None:
    """Hermes appends user plugins at the end; promote LatinRouter to the top.

    During ``hermes_cli.models`` import, this plugin loads *before* the
    auto-extend ``append`` loop finishes, so we poll briefly until the
    entry exists and then move it to the front.
    """
    if _ensure_latinrouter_first():
        return

    def _poll() -> None:
        for _ in range(200):
            try:
                if _ensure_latinrouter_first():
                    return
            except Exception:
                return
            time.sleep(0.005)

    try:
        threading.Thread(
            target=_poll, name="latinrouter-prefer-first", daemon=True
        ).start()
    except Exception:
        pass


_prefer_latinrouter_first()
PY

  cat >"$dest/plugin.yaml" <<'YAML'
name: latinrouter
kind: model-provider
version: 1.0.0
description: Gateway IA Centralizado para Latinoamérica
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

  log "$(msg install_provider)"
  if [[ -n "$PLUGIN_SRC" ]]; then
    cp -a "$PLUGIN_SRC/." "$dest/"
  else
    write_embedded_plugin "$dest"
  fi
  logf "$(msg provider_ok "$dest")"
}

install_hermes_official() {
  logf "$(msg hermes_missing)"
  logf "    $OFFICIAL_INSTALL_URL"
  curl -fsSL "$OFFICIAL_INSTALL_URL" | bash -s -- --skip-setup
  refresh_path
  if ! hermes_available; then
    logf "$(msg hermes_path_err)"
    logf "$(msg hermes_path_hint)"
    exit 1
  fi
  logf "$(msg hermes_ok)"
}

# Returns 0 if update available, 1 if up to date
hermes_update_available() {
  local out
  if ! out="$(hermes update --check 2>&1)"; then
    :
  fi
  if printf '%s\n' "$out" | grep -qiE 'Update available|behind'; then
    printf '%s\n' "$out" | grep -iE 'Update available|behind' | head -5 >&2 || true
    return 0
  fi
  if printf '%s\n' "$out" | grep -qiE 'Already up to date|up to date'; then
    return 1
  fi
  return 1
}

prompt_update_hermes() {
  # Always interactive. Blank answer = Yes.
  local reply=""
  if [[ "${LATINROUTER_SKIP_HERMES_UPDATE:-}" == "1" ]]; then
    return 1
  fi

  if [[ -r /dev/tty && -w /dev/tty ]]; then
    # Works even under `curl | bash` (stdin is the pipe; prompt on the real TTY)
    printf '%s' "$(msg update_prompt)" > /dev/tty
    IFS= read -r reply < /dev/tty || true
  elif [[ -t 0 && -t 1 ]]; then
    read -r -p "$(msg update_prompt)" reply || true
  else
    logf "$(msg no_tty_update)"
    return 1
  fi

  # Empty / whitespace → Yes (default)
  reply="$(printf '%s' "$reply" | tr -d '[:space:]')"
  case "$reply" in
    n|N|no|NO) return 1 ;;
    *) return 0 ;;
  esac
}

update_hermes() {
  logf "$(msg updating)"
  if hermes update -y; then
    refresh_path
    logf "$(msg updated)"
  else
    logf "$(msg update_fail)"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log "$(msg banner)"
log "$(msg home "$HERMES_HOME")"

if ! hermes_available; then
  install_hermes_official
  QUIET=0
else
  log "$(msg checking)"
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
        log "$(msg skip_update)"
        QUIET=0
      fi
      ;;
    *)
      QUIET=1
      ;;
  esac
fi

HERMES_HOME="$(resolve_hermes_home)"
export HERMES_HOME
mkdir -p "$HERMES_HOME"

install_plugin

if [[ "$QUIET" -eq 1 ]]; then
  logf "$(msg next_quiet "$SIGNUP_URL")"
else
  echo ""
  echo "$(msg next_title)"
  echo "$(msg next_1 "$SIGNUP_URL")"
  echo "$(msg next_2)"
  echo "$(msg next_3)"
  echo "$(msg next_4)"
  echo "$(msg next_5 "$BASE_URL")"
  echo "$(msg next_6)"
  echo ""
fi
