# Estrategia multi-agente — LatinRouter

Patrón para integrar LatinRouter en agentes populares. Hermes es el primer caso; el resto reutiliza el mismo contrato de API.

## Contrato LatinRouter (común a todos)

| Campo | Valor |
|-------|--------|
| Base URL | `https://llm.latinrouter.ai/v1` |
| Chat | `POST /v1/chat/completions` |
| Modelos | `GET /v1/models` |
| Auth | `Authorization: Bearer <key>` |
| Env sugerida | `LATINROUTER_API_KEY` |
| Signup | https://latinrouter.ai |

Si el agente ya soporta “OpenAI-compatible / custom base URL”, la integración mínima es: base URL + key + (idealmente) listado de modelos.

## Objetivos de UX (igual en todos)

1. Aparecer como **LatinRouter** en la lista de proveedores (no solo “custom”)
2. Instalación simple (idealmente un comando)
3. El usuario solo pega la API key
4. Modelos se cargan del gateway (no hardcodear el catálogo completo)

## Matriz por agente

| Agente | Mecanismo típico | Enfoque previsto | Estado |
|--------|------------------|------------------|--------|
| **Hermes** | Plugin `model-providers` en `$HERMES_HOME` | Drop-in + `install.sh` (Linux/macOS/WSL) + `install.ps1` (Windows); modelos vía `/v1/models` | Hecho — [hermes.md](hermes.md) |
| **OpenCode** | Plugin local (`auth` + `provider.models`) + `opencode.json` | Drop-in + `install.sh` / `install.ps1`; modelos live desde `/v1/models` | Hecho — [opencode.md](opencode.md) |
| **OpenClaw** | Provider plugin SDK (`registerProvider` + wizard auth choices) | Drop-in en `~/.openclaw/extensions` + instaladores; live `/v1/models`; wizard **More…** | Hecho — [openclaw.md](openclaw.md) |
| **OpenCodex** | Config / providers OpenAI-compat | Proveedor nombrado o script de config | Pendiente |
| **Claude Code** | `ANTHROPIC_*` / providers custom / settings | Endpoint compatible o capa de settings | Pendiente |

## Checklist al agregar un agente nuevo

Para cada producto en `latinrouter_agentes/<agente>/`:

1. **Investigar** cómo registra proveedores nativos (plugins, settings JSON, env, marketplace).
2. **Elegir** la vía con mejor UX y menor fricción (plugin > patch de config > solo docs de custom URL).
3. **Implementar**
   - Artefacto instalable (plugin, snippet, script)
   - `install.sh` one-liner cuando sea posible
   - `README` del agente
4. **Documentar** en `docs/<agente>.md` + fila en el README raíz.
5. **Verificar**
   - Lista de proveedores muestra LatinRouter
   - Key sola basta para listar modelos y chatear
   - `GET /v1/models` y un `chat/completions` de humo

## Plantilla de carpetas

```
latinrouter_agentes/
├── README.md
├── docs/
│   ├── install.md
│   ├── strategy.md
│   ├── hermes.md
│   ├── opencode.md
│   ├── openclaw.md
│   ├── opencodex.md     # futuro
│   └── claudecode.md    # futuro
├── hermes/
│   ├── install.sh
│   ├── install.ps1
│   └── plugin/latinrouter/
├── opencode/
│   ├── install.sh
│   ├── install.ps1
│   └── plugin/latinrouter.js
├── openclaw/
│   ├── install.sh
│   ├── install.ps1
│   └── plugin/
├── opencodex/           # futuro
└── claudecode/          # futuro
```

## Notas por producto (borrador)

### OpenCode

Hecho: plugin en `~/.config/opencode/plugins/` con hooks `auth` y `config` (seed modelos). Config merge en `opencode.json`. Primero en Providers vía nombre; Popular requiere upstream.

### OpenClaw

Hecho: provider plugin en `~/.openclaw/extensions/latinrouter` con `providerAuthChoices` (wizard **More… → LatinRouter**) y catálogo live `/v1/models`. Featured/Popular del onboard es hardcodeado en OpenClaw (openai/openrouter/xai/google/anthropic).

### OpenCodex

Buscar: registro de providers, `baseURL` / `apiKey`, listado de modelos. Preferir un provider id `latinrouter` en config generada por script, no solo instructions manuales.

### Claude Code

Evaluar settings / env para base URL alternativa y si hay extensión o provider plug-in. Si solo hay Anthropic Messages, documentar límites y alternativas (proxy o modo OpenAI si existe).

## Qué no hacer

- No hardcodear secretos en el repo
- No depender de forks permanentes si el producto tiene extensión oficial
- No asumir paths de modelos fijos: siempre preferir `/v1/models`
- No usar `hermes plugins install` genérico para model-providers de Hermes (debe ir a `plugins/model-providers/`)
