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
