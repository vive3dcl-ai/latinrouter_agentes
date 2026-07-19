# latinrouter_agentes

Integraciones para usar **LatinRouter** (`https://llm.latinrouter.ai`) como proveedor de IA en agentes populares.

Repo: [github.com/vive3dcl-ai/latinrouter_agentes](https://github.com/vive3dcl-ai/latinrouter_agentes)

LatinRouter es **OpenAI-compatible** (`/v1`, `/v1/models`, chat completions). El usuario solo necesita su API key; los modelos se listan solos desde el gateway.

## Estado

| Agente | Estado | Instalación |
|--------|--------|-------------|
| [Hermes Agent](https://github.com/NousResearch/hermes-agent) | Listo (Linux / macOS / Windows) | [docs/install.md](docs/install.md#hermes-agent) |
| [OpenCode](https://opencode.ai) | Listo (Linux / macOS / Windows) | [docs/install.md](docs/install.md#opencode) |
| OpenCodex | Pendiente | — |
| Claude Code | Pendiente | — |
| OpenClaw | Pendiente | — |

## Instalación (todos los agentes / distros)

Comandos listos para copiar: **[docs/install.md](docs/install.md)**

### Hermes — one-liner

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh | bash
```

```powershell
# Windows nativo
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.ps1)
```

Luego: `hermes model` → LatinRouter (preseleccionado) → API key → `hermes`

Detalle: [docs/hermes.md](docs/hermes.md) · Key: [latinrouter.ai](https://latinrouter.ai)

### OpenCode — one-liner

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
```

```powershell
# Windows nativo
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.ps1)
```

Luego: `opencode` → `/connect` → LatinRouter (**primero** en Providers) → API key → `/models`

Detalle: [docs/opencode.md](docs/opencode.md) · Instaladores: [docs/install.md](docs/install.md#opencode) · Key: [latinrouter.ai](https://latinrouter.ai)


## Gateway

| Campo | Valor |
|-------|--------|
| Base URL | `https://llm.latinrouter.ai/v1` |
| Modelos | `GET /v1/models` (automático en Hermes y OpenCode) |
| Auth | `Authorization: Bearer <LATINROUTER_API_KEY>` |

## Estrategia multi-agente

Ver [docs/strategy.md](docs/strategy.md) para el patrón reutilizable (OpenCodex, Claude Code, OpenClaw).
