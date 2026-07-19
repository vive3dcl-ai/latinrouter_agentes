# Install LatinRouter as a Hermes model-provider plugin (Windows native).
#
# Behavior:
#   1. No Hermes            → install from official NousResearch installer
#   2. Hermes outdated      → ask to update (default: Yes), then install plugin
#   3. Hermes up to date    → install LatinRouter provider quietly
#
# Language: automatic from Windows UI culture (es → Spanish, else English).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File hermes\install.ps1
#   iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.ps1)
#
# Hermes on native Windows uses %LOCALAPPDATA%\hermes (not ~/.hermes).
# For WSL2, use the Linux installer instead: bash hermes/install.sh

$ErrorActionPreference = "Stop"

$ProviderName = "latinrouter"
$BaseUrl = "https://llm.latinrouter.ai/v1"
$SignupUrl = "https://latinrouter.ai"
$OfficialInstallUrl = "https://hermes-agent.nousresearch.com/install.ps1"
$script:Quiet = $false

function Get-InstallLang {
    try {
        $culture = [System.Globalization.CultureInfo]::CurrentUICulture
        if ($culture.TwoLetterISOLanguageName -eq "es") { return "es" }
        if ($culture.Name -match '^es') { return "es" }
    } catch {}
    try {
        $culture = Get-Culture
        if ($culture.TwoLetterISOLanguageName -eq "es") { return "es" }
    } catch {}
    if ($env:LANG -match '(?i)^es') { return "es" }
    return "en"
}

$script:Lang = Get-InstallLang

function Get-Msg {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [object[]]$Args = @()
    )
    $mapEs = @{
        banner           = "==> LatinRouter + Hermes (Windows)"
        home             = "    HERMES_HOME={0}"
        checking         = "==> Comprobando versión de Hermes…"
        install_provider = "==> Instalando proveedor LatinRouter"
        provider_ok      = "✓ Proveedor LatinRouter instalado → {0}"
        hermes_missing   = "==> Hermes no encontrado — instalando desde el instalador oficial"
        hermes_ok        = "✓ Hermes instalado"
        hermes_path_err  = "ERROR: la instalación de Hermes terminó pero 'hermes' no está en el PATH."
        hermes_path_hint = "Abre una ventana nueva de PowerShell y vuelve a ejecutar este script."
        update_prompt    = "Hermes está desactualizado. ¿Actualizar ahora? [S/n]"
        updating         = "==> Actualizando Hermes…"
        updated          = "✓ Hermes actualizado"
        update_fail      = "ADVERTENCIA: falló 'hermes update' — se continúa con la instalación del proveedor LatinRouter"
        skip_update      = "==> Se omite la actualización de Hermes"
        no_tty_update    = "==> No hay terminal interactiva; se omite la actualización de Hermes"
        next_quiet       = "Siguiente: hermes model  →  LatinRouter  →  pega tu API key  ({0})"
        next_title       = "Siguientes pasos:"
        next_1           = "  1. Obtén una API key en {0}"
        next_2           = "  2. Ejecuta:  hermes model"
        next_3           = "  3. Elige: LatinRouter"
        next_4           = "  4. Pega tu LATINROUTER_API_KEY cuando te la pida"
        next_5           = "  5. Los modelos se cargan solos desde {0}/models"
        next_6           = "  6. Empieza a chatear:  hermes"
    }
    $mapEn = @{
        banner           = "==> LatinRouter + Hermes (Windows)"
        home             = "    HERMES_HOME={0}"
        checking         = "==> Checking Hermes version…"
        install_provider = "==> Installing LatinRouter provider"
        provider_ok      = "✓ LatinRouter provider installed → {0}"
        hermes_missing   = "==> Hermes not found — installing from official installer"
        hermes_ok        = "✓ Hermes installed"
        hermes_path_err  = "ERROR: Hermes install finished but 'hermes' is not on PATH."
        hermes_path_hint = "Open a new PowerShell window and re-run this script."
        update_prompt    = "Hermes is outdated. Update now? [Y/n]"
        updating         = "==> Updating Hermes…"
        updated          = "✓ Hermes updated"
        update_fail      = "WARNING: hermes update failed — continuing with LatinRouter provider install"
        skip_update      = "==> Skipping Hermes update"
        no_tty_update    = "==> No interactive terminal; skipping Hermes update"
        next_quiet       = "Next: hermes model  →  LatinRouter  →  paste API key  ({0})"
        next_title       = "Next steps:"
        next_1           = "  1. Get an API key at {0}"
        next_2           = "  2. Run:  hermes model"
        next_3           = "  3. Select: LatinRouter"
        next_4           = "  4. Paste your LATINROUTER_API_KEY when prompted"
        next_5           = "  5. Models load automatically from {0}/models"
        next_6           = "  6. Start chatting:  hermes"
    }
    $map = if ($script:Lang -eq "es") { $mapEs } else { $mapEn }
    $fmt = $map[$Key]
    if (-not $fmt) { return $Key }
    if ($Args.Count -gt 0) {
        return ($fmt -f $Args)
    }
    return $fmt
}

function Write-Log {
    param([string]$Message)
    if (-not $script:Quiet) { Write-Host $Message }
}

function Write-LogAlways {
    param([string]$Message)
    Write-Host $Message
}

function Get-HermesHome {
    if ($env:HERMES_HOME -and $env:HERMES_HOME.Trim()) {
        return $env:HERMES_HOME.Trim()
    }
    $localAppData = $env:LOCALAPPDATA
    if (-not $localAppData) {
        $localAppData = Join-Path $HOME "AppData\Local"
    }
    return (Join-Path $localAppData "hermes")
}

function Refresh-Path {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($machine -or $user) {
        $env:Path = @($machine, $user) -join ";"
    }
    $localBin = Join-Path $env:LOCALAPPDATA "hermes\bin"
    if (Test-Path $localBin) {
        $env:Path = "$localBin;$env:Path"
    }
}

function Test-HermesAvailable {
    Refresh-Path
    return [bool](Get-Command hermes -ErrorAction SilentlyContinue)
}

function Write-EmbeddedPlugin {
    param([string]$Dest)

    New-Item -ItemType Directory -Force -Path $Dest | Out-Null

    @'
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

'@ | Set-Content -Path (Join-Path $Dest "__init__.py") -Encoding utf8

    @'
name: latinrouter
kind: model-provider
version: 1.0.0
description: LatinRouter (Gateway IA Centralizado para Latinoamérica)
author: LatinRouter

'@ | Set-Content -Path (Join-Path $Dest "plugin.yaml") -Encoding utf8

    @'
# LatinRouter — Hermes model provider

| Campo | Valor |
|-------|--------|
| Provider id | `latinrouter` |
| Base URL | `https://llm.latinrouter.ai/v1` |
| Models | `GET /v1/models` (automático) |
| API key env | `LATINROUTER_API_KEY` |

```powershell
hermes model
hermes
```

Key: https://latinrouter.ai
'@ | Set-Content -Path (Join-Path $Dest "README.md") -Encoding utf8
}

function Install-LatinRouterPlugin {
    param([string]$HermesHome)

    $Dest = Join-Path $HermesHome "plugins\model-providers\$ProviderName"
    $PluginSrc = $null
    if ($PSScriptRoot) {
        $candidate = Join-Path $PSScriptRoot "plugin\$ProviderName"
        if (Test-Path (Join-Path $candidate "__init__.py")) {
            $PluginSrc = $candidate
        }
    }

    New-Item -ItemType Directory -Force -Path (Split-Path $Dest -Parent) | Out-Null
    if (Test-Path $Dest) {
        Remove-Item -Recurse -Force $Dest
    }

    Write-Log (Get-Msg install_provider)
    if ($PluginSrc) {
        Copy-Item -Recurse -Force $PluginSrc $Dest
    } else {
        Write-EmbeddedPlugin -Dest $Dest
    }
    Write-LogAlways (Get-Msg provider_ok -Args @($Dest))
}

function Install-HermesOfficial {
    Write-LogAlways (Get-Msg hermes_missing)
    Write-LogAlways "    $OfficialInstallUrl"
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "hermes-official-install.ps1"
    Invoke-WebRequest -Uri $OfficialInstallUrl -OutFile $tmp -UseBasicParsing
    try {
        & $tmp -SkipSetup
    } finally {
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    }
    Refresh-Path
    if (-not (Test-HermesAvailable)) {
        Write-LogAlways (Get-Msg hermes_path_err)
        Write-LogAlways (Get-Msg hermes_path_hint)
        exit 1
    }
    Write-LogAlways (Get-Msg hermes_ok)
}

function Test-HermesUpdateAvailable {
    Refresh-Path
    try {
        $out = & hermes update --check 2>&1 | Out-String
    } catch {
        $out = "$_"
    }
    if ($out -match '(?i)Update available|behind') {
        ($out -split "`n" | Where-Object { $_ -match '(?i)Update available|behind' } | Select-Object -First 5) | ForEach-Object { Write-Host $_ }
        return 'available'
    }
    return 'current'
}

function Confirm-UpdateHermes {
    # Always interactive. Blank answer = Yes.
    if ($env:LATINROUTER_SKIP_HERMES_UPDATE -eq "1") {
        return $false
    }

    try {
        $reply = Read-Host (Get-Msg update_prompt)
    } catch {
        Write-LogAlways (Get-Msg no_tty_update)
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($reply)) {
        return $true
    }
    return ($reply.Trim() -notmatch '^(n|no)$')
}

function Update-Hermes {
    Write-LogAlways (Get-Msg updating)
    try {
        & hermes update -y
        Refresh-Path
        Write-LogAlways (Get-Msg updated)
    } catch {
        Write-LogAlways (Get-Msg update_fail)
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$HermesHome = Get-HermesHome
Write-Log (Get-Msg banner)
Write-Log (Get-Msg home -Args @($HermesHome))

if (-not (Test-HermesAvailable)) {
    Install-HermesOfficial
    $script:Quiet = $false
} else {
    Write-Log (Get-Msg checking)
    $status = Test-HermesUpdateAvailable
    if ($status -eq 'available') {
        if (Confirm-UpdateHermes) {
            Update-Hermes
            $script:Quiet = $false
        } else {
            Write-Log (Get-Msg skip_update)
            $script:Quiet = $false
        }
    } else {
        $script:Quiet = $true
    }
}

$HermesHome = Get-HermesHome
New-Item -ItemType Directory -Force -Path $HermesHome | Out-Null
Install-LatinRouterPlugin -HermesHome $HermesHome

if ($script:Quiet) {
    Write-LogAlways (Get-Msg next_quiet -Args @($SignupUrl))
} else {
    Write-Host ""
    Write-Host (Get-Msg next_title)
    Write-Host (Get-Msg next_1 -Args @($SignupUrl))
    Write-Host (Get-Msg next_2)
    Write-Host (Get-Msg next_3)
    Write-Host (Get-Msg next_4)
    Write-Host (Get-Msg next_5 -Args @($BaseUrl))
    Write-Host (Get-Msg next_6)
    Write-Host ""
}
