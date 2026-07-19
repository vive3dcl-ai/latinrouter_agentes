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
