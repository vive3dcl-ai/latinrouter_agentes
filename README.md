# latinrouter_agentes

Integraciones para usar **LatinRouter** (`https://llm.latinrouter.ai`) como proveedor de IA en agentes populares.

Repo: [github.com/vive3dcl-ai/latinrouter_agentes](https://github.com/vive3dcl-ai/latinrouter_agentes)

LatinRouter es **OpenAI-compatible** (`/v1`, `/v1/models`, chat completions). El usuario solo necesita su API key; los modelos se listan solos desde el gateway.

## Estado

| Agente | Estado | Instalación |
|--------|--------|-------------|
| [Hermes Agent](https://github.com/NousResearch/hermes-agent) | Listo (Linux / macOS / Windows) | [docs/install.md](docs/install.md#hermes-agent) |
| [OpenCode](https://opencode.ai) | Listo (Linux / macOS / Windows) | [docs/install.md](docs/install.md#opencode) |
| [OpenClaw](https://openclaw.ai) | Listo (Linux / macOS / Windows) | [docs/install.md](docs/install.md#openclaw) |
| [OpenAI Codex](https://github.com/openai/codex) | Config lista¹ | [docs/install.md](docs/install.md#openai-codex) |
| [Claude Code](https://code.claude.com) | Config lista² | [docs/install.md](docs/install.md#claude-code) |

¹ Codex requiere `POST /v1/responses` en el gateway (hoy OpenAI chat only).  
² Claude Code requiere `POST /v1/messages` Anthropic (hoy OpenAI chat only).

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

### OpenClaw — one-liner

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.sh | bash
```

```powershell
# Windows nativo
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.ps1)
```

Luego: `openclaw onboard` → **More…** → LatinRouter → API key → `openclaw models list`

Detalle: [docs/openclaw.md](docs/openclaw.md) · Instaladores: [docs/install.md](docs/install.md#openclaw) · Key: [latinrouter.ai](https://latinrouter.ai)

### OpenAI Codex — one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/codex/install.sh | bash
```

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/codex/install.ps1)
```

Luego: `codex --profile latinrouter`  
**Nota:** hace falta `POST /v1/responses` en el gateway. Detalle: [docs/codex.md](docs/codex.md)

### Claude Code — one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/claudecode/install.sh | bash
```

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/claudecode/install.ps1)
```

Luego: `claude`  
**Nota:** hace falta `POST /v1/messages` (Anthropic) en el gateway. Detalle: [docs/claudecode.md](docs/claudecode.md)


## Gateway

| Campo | Valor |
|-------|--------|
| Base URL | `https://llm.latinrouter.ai/v1` |
| Modelos | `GET /v1/models` |
| Auth | `Authorization: Bearer <LATINROUTER_API_KEY>` |
| OpenAI chat | `POST /v1/chat/completions` (Hermes, OpenCode, OpenClaw) |
| Codex | Requiere `POST /v1/responses` |
| Claude Code | Requiere `POST /v1/messages` |

## Estrategia multi-agente

Ver [docs/strategy.md](docs/strategy.md).
