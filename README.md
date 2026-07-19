# latinrouter_agentes

Integraciones para usar **LatinRouter** (`https://llm.latinrouter.ai`) como proveedor de IA en agentes populares.

Repo: [github.com/vive3dcl-ai/latinrouter_agentes](https://github.com/vive3dcl-ai/latinrouter_agentes)

LatinRouter es **OpenAI-compatible** (`/v1`, `/v1/models`, chat completions). El usuario solo necesita su API key; los modelos se listan solos desde el gateway.

## Estado

| Agente | Estado | Instalación |
|--------|--------|-------------|
| [Hermes Agent](https://github.com/NousResearch/hermes-agent) | Listo (Linux / macOS / Windows) | ver abajo |
| OpenCodex | Pendiente | — |
| Claude Code | Pendiente | — |
| OpenClaw | Pendiente | — |

## Hermes — quickstart

Un solo comando. El instalador:

1. **Sin Hermes** → lo instala desde el instalador oficial de NousResearch  
2. **Hermes desactualizado** → pregunta si actualizar (**default: Sí**)  
3. **Hermes al día** → solo instala LatinRouter (silencioso)

| Plataforma | Comando |
|------------|---------|
| Linux / macOS / WSL2 | one-liner abajo |
| Windows nativo | one-liner PowerShell abajo |

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh | bash
```

```powershell
# Windows nativo
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.ps1)
```

Luego:

```bash
hermes model    # elige LatinRouter → pega tu API key → modelos automáticos
hermes          # chatea
```

Key: [latinrouter.ai](https://latinrouter.ai)

Documentación detallada: [docs/hermes.md](docs/hermes.md)

## Gateway

| Campo | Valor |
|-------|--------|
| Base URL | `https://llm.latinrouter.ai/v1` |
| Modelos | `GET /v1/models` (automático en Hermes) |
| Auth | `Authorization: Bearer <LATINROUTER_API_KEY>` |

## Estrategia multi-agente

Ver [docs/strategy.md](docs/strategy.md) para el patrón reutilizable (OpenCodex, Claude Code, OpenClaw).
