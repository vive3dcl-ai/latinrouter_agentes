# LatinRouter + Claude Code

Integración con [Claude Code](https://code.claude.com/docs/en/setup) (Anthropic).

## Cómo funciona

Claude Code **no** registra proveedores OpenAI-compat como Hermes/OpenCode.  
Habla el protocolo **Anthropic Messages**. El instalador escribe en `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://llm.latinrouter.ai",
    "ANTHROPIC_AUTH_TOKEN": "<key>",
    "ANTHROPIC_API_KEY": "<key>",
    "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1"
  }
}
```

`ANTHROPIC_BASE_URL` **no** debe incluir `/v1` (Claude Code añade `/v1/messages`).

## Instalación

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/claudecode/install.sh | bash
```

```powershell
# Windows
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/claudecode/install.ps1)
```

## Uso

```bash
claude
# /status
```

## Limitación importante: Anthropic Messages

| Endpoint LatinRouter | Estado típico |
|----------------------|---------------|
| `GET /v1/models` | OK |
| `POST /v1/chat/completions` | OK (OpenAI) |
| `POST /v1/messages` | **Requerido por Claude Code** — si falta, el chat no funciona |

OpenAI Chat Completions **no** sirve apuntando `ANTHROPIC_BASE_URL` al gateway. Hace falta:

1. **Preferido:** LatinRouter implementa `POST /v1/messages` (+ streaming/tools), o  
2. Un bridge local Anthropic↔OpenAI (fuera del alcance de este instalador).

## Model discovery

Con `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1`, Claude Code lista modelos vía `GET /v1/models`, pero suele filtrar IDs que empiezan por `claude` / `anthropic`. Modelos con otros nombres pueden requerir `--model` o env `ANTHROPIC_MODEL`.

## Plugins

El marketplace de Claude Code **no** registra proveedores LLM; solo skills/MCP/hooks.
