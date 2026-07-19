# LatinRouter — Hermes model provider

Plugin de proveedor para [Hermes Agent](https://github.com/NousResearch/hermes-agent).

| Campo | Valor |
|-------|--------|
| Provider id | `latinrouter` |
| Descripción | Gateway IA Centralizado para Latinoamérica |
| Base URL | `https://llm.latinrouter.ai/v1` |
| Modelos | `GET /v1/models` (automático tras ingresar la key) |
| API key env | `LATINROUTER_API_KEY` |

## Instalación

| Plataforma | Comando |
|------------|---------|
| Linux / macOS / WSL2 | `bash hermes/install.sh` |
| Windows nativo | `powershell -ExecutionPolicy Bypass -File hermes\install.ps1` |

One-liners (cuando el repo esté publicado):

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh | bash
```

```powershell
# Windows nativo
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.ps1)
```

## Uso

```bash
hermes model          # LatinRouter → API key → modelos del gateway
hermes
```

Obtén tu key en [latinrouter.ai](https://latinrouter.ai).
