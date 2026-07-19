# LatinRouter — OpenCode provider

Plugin + instalador para [OpenCode](https://github.com/anomalyco/opencode).

| Campo | Valor |
|-------|--------|
| Provider id | `latinrouter` |
| Nombre | ` LatinRouter (Gateway…)` (espacio inicial → primero en Providers) |
| Base URL | `https://llm.latinrouter.ai/v1` |
| Modelos | `GET /v1/models` (vía plugin) |
| Auth | `/connect` → LatinRouter, o `LATINROUTER_API_KEY` |

## Instalación

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
```

```powershell
# Windows
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.ps1)
```

```bash
# Desde este repo
bash opencode/install.sh
```

## Uso

```bash
opencode
# /connect  → LatinRouter → pegar key (si no la diste en el instalador)
# /models   → modelos del gateway
```

Key: https://latinrouter.ai
