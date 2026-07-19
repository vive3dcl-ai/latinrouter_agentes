# LatinRouter + OpenAI Codex

Integración con el [Codex oficial de OpenAI](https://github.com/openai/codex) (`codex` CLI).

## Cómo funciona

Codex no tiene plugins de proveedores. El instalador escribe un proveedor nombrado en:

- `~/.codex/config.toml` → `[model_providers.latinrouter]`
- `~/.codex/latinrouter.config.toml` → perfil (`codex --profile latinrouter`)
- `~/.codex/secrets/latinrouter` → API key (chmod 600)

## Instalación

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/codex/install.sh | bash
```

```powershell
# Windows
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/codex/install.ps1)
```

## Uso

```bash
codex --profile latinrouter
# o:
export LATINROUTER_API_KEY=…
codex   # si model_provider=latinrouter está activo
```

## Modelos

El instalador llama `GET /v1/models` con tu key y fija el `model` del perfil.  
Codex no usa el listado OpenAI `{data:[…]}` como catálogo live nativo para providers custom; el default lo pone el instalador.

## Limitación importante: Responses API

| Endpoint LatinRouter | Estado típico |
|----------------------|---------------|
| `GET /v1/models` | OK |
| `POST /v1/chat/completions` | OK |
| `POST /v1/responses` | **Requerido por Codex** — si falta, el chat no funciona |

Codex eliminó `wire_api = "chat"`. Hasta que el gateway implemente Responses (o un bridge local), la integración queda **configurada pero el runtime falla**.

## Config de referencia

```toml
[model_providers.latinrouter]
name = "LatinRouter (Gateway IA Centralizado para Latinoamérica)"
base_url = "https://llm.latinrouter.ai/v1"
wire_api = "responses"
env_key = "LATINROUTER_API_KEY"
requires_openai_auth = false
```
