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
    """Best-effort: wrap list + patch group_providers if models is loaded."""
    try:
        _wrap_canonical_providers()
        _patch_group_providers()
    except Exception:
        pass


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


# Also catch late imports of hermes_cli.models (after discovery already ran).
class _ModelsImportHook:
    def find_spec(self, fullname, path, target=None):  # noqa: ANN001
        if fullname == "hermes_cli.models":
            # Defer hook install until after the real loader finishes.
            existing = sys.modules.get(fullname)
            if existing is not None and getattr(existing, "group_providers", None):
                _apply_picker_hooks()
        return None


def _install_import_hook() -> None:
    for finder in sys.meta_path:
        if isinstance(finder, _ModelsImportHook):
            return
    sys.meta_path.insert(0, _ModelsImportHook())


_patch_provider_discovery()
_install_import_hook()
_apply_picker_hooks()
