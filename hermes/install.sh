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
from typing import Any

from providers import register_provider
from providers.base import ProviderProfile

_DISPLAY_NAME = "LatinRouter"
# hermes model shows ProviderEntry.tui_desc for single (ungrouped) rows
_DESCRIPTION = "LatinRouter (Gateway IA Centralizado para Latinoamérica)"

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
    fallback_models=(),
)

register_provider(latinrouter)


class _PreferLatinRouterList(list):
    """List that keeps ``latinrouter`` at index 0 whenever Hermes iterates it."""

    _fixing: bool = False

    def _promote(self) -> None:
        if self._fixing:
            return
        if not any(getattr(p, "slug", None) == "latinrouter" for p in list.__iter__(self)):
            return

        self._fixing = True
        try:
            mod = sys.modules.get("hermes_cli.models")
            ProviderEntry = getattr(mod, "ProviderEntry", None) if mod else None
            current = [p for p in list.__iter__(self)]
            rest = [p for p in current if getattr(p, "slug", None) != "latinrouter"]
            if ProviderEntry is not None:
                entry: Any = ProviderEntry(
                    "latinrouter", _DISPLAY_NAME, _DESCRIPTION
                )
            else:
                entry = next(
                    p for p in current if getattr(p, "slug", None) == "latinrouter"
                )
            list.__setitem__(self, slice(None), [entry] + rest)
            if mod is not None:
                labels = getattr(mod, "_PROVIDER_LABELS", None)
                if isinstance(labels, dict):
                    labels["latinrouter"] = _DISPLAY_NAME
        finally:
            self._fixing = False

    def __iter__(self):  # type: ignore[override]
        self._promote()
        return list.__iter__(self)

    def __getitem__(self, index):  # type: ignore[override]
        self._promote()
        return list.__getitem__(self, index)

    def __len__(self):  # type: ignore[override]
        self._promote()
        return list.__len__(self)

    def copy(self):  # type: ignore[override]
        self._promote()
        return list(self)


def _wrap_canonical_providers() -> bool:
    mod = sys.modules.get("hermes_cli.models")
    if mod is None:
        return False
    providers = getattr(mod, "CANONICAL_PROVIDERS", None)
    if providers is None:
        return False
    if isinstance(providers, _PreferLatinRouterList):
        return True
    mod.CANONICAL_PROVIDERS = _PreferLatinRouterList(providers)
    return True


def _patch_group_providers() -> bool:
    mod = sys.modules.get("hermes_cli.models")
    if mod is None:
        return False
    gp = getattr(mod, "group_providers", None)
    if gp is None:
        return False
    if getattr(gp, "_latinrouter_patched", False):
        return True

    def group_providers(slugs):  # type: ignore[no-untyped-def]
        items: list[str] = []
        seen: set[str] = set()
        for raw in slugs:
            s = str(raw or "").strip().lower()
            if not s or s in seen:
                continue
            seen.add(s)
            items.append(s)
        if "latinrouter" in seen:
            items = ["latinrouter"] + [s for s in items if s != "latinrouter"]
        return gp(items)

    group_providers._latinrouter_patched = True  # type: ignore[attr-defined]
    mod.group_providers = group_providers  # type: ignore[method-assign]
    return True


def _apply_picker_hooks() -> None:
    """Best-effort: wrap list + patch group_providers + default selection."""
    try:
        _wrap_canonical_providers()
        _patch_group_providers()
        _patch_provider_choice_default()
    except Exception:
        pass


def _patch_provider_choice_default() -> bool:
    """Preselect LatinRouter in ``hermes model`` (instead of the active provider)."""
    patched_any = False

    def _prefer_index(choices) -> int | None:
        for i, choice in enumerate(choices or []):
            text = str(choice)
            if text.startswith("LatinRouter") or "LatinRouter (" in text:
                return i
        return None

    main = sys.modules.get("hermes_cli.main")
    if main is not None:
        orig = getattr(main, "_prompt_provider_choice", None)
        if orig is not None and not getattr(orig, "_latinrouter_default_patched", False):
            def _prompt_provider_choice(choices, *, default=0, title="Select provider:"):  # type: ignore[no-untyped-def]
                title_l = str(title or "").lower()
                if "provider" in title_l or title_l.strip() in {"", "select provider:"}:
                    idx = _prefer_index(choices)
                    if idx is not None:
                        default = idx
                return orig(choices, default=default, title=title)

            _prompt_provider_choice._latinrouter_default_patched = True  # type: ignore[attr-defined]
            main._prompt_provider_choice = _prompt_provider_choice  # type: ignore[method-assign]
            patched_any = True
        elif orig is not None:
            patched_any = True

        sel = getattr(main, "select_provider_and_model", None)
        if sel is not None and not getattr(sel, "_latinrouter_select_patched", False):
            def select_provider_and_model(*args, **kwargs):  # type: ignore[no-untyped-def]
                _apply_picker_hooks()
                return sel(*args, **kwargs)

            select_provider_and_model._latinrouter_select_patched = True  # type: ignore[attr-defined]
            main.select_provider_and_model = select_provider_and_model  # type: ignore[method-assign]
            patched_any = True

    setup = sys.modules.get("hermes_cli.setup")
    if setup is not None:
        curses_fn = getattr(setup, "_curses_prompt_choice", None)
        if curses_fn is not None and not getattr(curses_fn, "_latinrouter_default_patched", False):
            def _curses_prompt_choice(question, choices, default=0, description=None):  # type: ignore[no-untyped-def]
                q = str(question or "").lower()
                if "provider" in q:
                    idx = _prefer_index(choices)
                    if idx is not None:
                        default = idx
                if description is None:
                    return curses_fn(question, choices, default)
                return curses_fn(question, choices, default, description)

            _curses_prompt_choice._latinrouter_default_patched = True  # type: ignore[attr-defined]
            setup._curses_prompt_choice = _curses_prompt_choice  # type: ignore[method-assign]
            patched_any = True
        elif curses_fn is not None:
            patched_any = True

    return patched_any


def _patch_provider_discovery() -> None:
    """Re-apply hooks whenever Hermes discovers/lists providers.

    Discovery often runs *before* ``hermes_cli.models`` is imported. In that
    case a one-shot wrap fails. Patching ``list_providers`` /
    ``get_provider_profile`` re-runs the wrap when models later calls them
    during CANONICAL_PROVIDERS auto-extend — which is exactly when we need it.
    """
    import providers as providers_mod

    if getattr(providers_mod, "_latinrouter_discovery_patched", False):
        _apply_picker_hooks()
        return

    orig_list = providers_mod.list_providers
    orig_get = providers_mod.get_provider_profile

    def list_providers(*args, **kwargs):  # type: ignore[no-untyped-def]
        result = orig_list(*args, **kwargs)
        _apply_picker_hooks()
        return result

    def get_provider_profile(*args, **kwargs):  # type: ignore[no-untyped-def]
        result = orig_get(*args, **kwargs)
        _apply_picker_hooks()
        return result

    providers_mod.list_providers = list_providers  # type: ignore[assignment]
    providers_mod.get_provider_profile = get_provider_profile  # type: ignore[assignment]
    providers_mod._latinrouter_discovery_patched = True  # type: ignore[attr-defined]
    _apply_picker_hooks()


class _HermesImportHook:
    """After hermes_cli.main / setup load, install the preselect patch."""

    _loading: set[str] = set()

    def find_spec(self, fullname, path, target=None):  # noqa: ANN001
        if fullname not in {"hermes_cli.main", "hermes_cli.setup"}:
            return None
        if fullname in self._loading:
            return None

        self._loading.add(fullname)
        try:
            # Delegate to the rest of meta_path without recursing into ourselves.
            sys.meta_path.remove(self)
            try:
                import importlib.util

                spec = importlib.util.find_spec(fullname)
            finally:
                sys.meta_path.insert(0, self)
            if spec is None or spec.loader is None:
                return None

            loader = spec.loader
            orig_exec = getattr(loader, "exec_module", None)
            if orig_exec is None:
                return spec

            def exec_module(module, _orig=orig_exec):  # type: ignore[no-untyped-def]
                _orig(module)
                _apply_picker_hooks()

            try:
                loader.exec_module = exec_module  # type: ignore[method-assign]
            except Exception:
                pass
            return spec
        finally:
            self._loading.discard(fullname)


def _install_import_hook() -> None:
    for finder in sys.meta_path:
        if isinstance(finder, _HermesImportHook):
            return
    sys.meta_path.insert(0, _HermesImportHook())


_patch_provider_discovery()
_install_import_hook()
_apply_picker_hooks()
PY

  cat >"$dest/plugin.yaml" <<'YAML'
name: latinrouter
kind: model-provider
version: 1.0.0
description: LatinRouter (Gateway IA Centralizado para Latinoamérica)
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
