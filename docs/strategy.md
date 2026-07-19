# Estrategia multi-agente — LatinRouter

Patrón para integrar LatinRouter en agentes populares. Hermes / OpenCode / OpenClaw son drop-in completos; Codex y Claude Code dependen de rutas extra en el gateway.

## Contrato LatinRouter (común)

| Campo | Valor |
|-------|--------|
| Base URL | `https://llm.latinrouter.ai/v1` |
| Chat OpenAI | `POST /v1/chat/completions` |
| Modelos | `GET /v1/models` |
| Auth | `Authorization: Bearer <key>` |
| Env sugerida | `LATINROUTER_API_KEY` |
| Signup | https://latinrouter.ai |

## Objetivos de UX

1. Aparecer como **LatinRouter** (no solo “custom”)
2. Instalación one-liner
3. Usuario solo pega API key
4. Modelos desde el gateway

## Matriz

| Agente | Mecanismo | Estado |
|--------|-----------|--------|
| **Hermes** | Plugin `model-providers` | Listo — [hermes.md](hermes.md) |
| **OpenCode** | Plugin + `opencode.json` | Listo — [opencode.md](opencode.md) |
| **OpenClaw** | Provider plugin + wizard More… | Listo — [openclaw.md](openclaw.md) |
| **OpenAI Codex** | `~/.codex/config.toml` `model_providers` | Config lista; runtime necesita `/v1/responses` — [codex.md](codex.md) |
| **Claude Code** | `~/.claude/settings.json` `ANTHROPIC_*` | Config lista; runtime necesita `/v1/messages` — [claudecode.md](claudecode.md) |

## Gaps del gateway (bloquean Codex / Claude Code)

| Ruta | Quién la necesita |
|------|-------------------|
| `POST /v1/responses` (+ SSE Responses) | OpenAI Codex |
| `POST /v1/messages` (+ SSE Anthropic tools) | Claude Code |

Hasta que existan, los instaladores de Codex/Claude Code dejan la config lista y avisan en la instalación.

## Plantilla

```
latinrouter_agentes/
├── hermes/ opencode/ openclaw/   # listos end-to-end
├── codex/ claudecode/            # instaladores + config; gateway P0
└── docs/
```
