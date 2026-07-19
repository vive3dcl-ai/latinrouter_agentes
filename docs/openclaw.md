# LatinRouter + OpenClaw

Guía para usar LatinRouter como proveedor nombrado en [OpenClaw](https://openclaw.ai) ([openclaw/openclaw](https://github.com/openclaw/openclaw)).

Compatible con **Linux, macOS y Windows** (nativo y WSL2).

## Listado automático de modelos

Sí: con API key, el plugin llama a:

```text
GET https://llm.latinrouter.ai/v1/models
Authorization: Bearer <LATINROUTER_API_KEY>
```

vía `getCachedLiveProviderModelRows` (SDK OpenClaw). El catálogo viene del gateway.

## Por qué un plugin

OpenClaw registra proveedores con **provider plugins** (`registerProvider` / `defineSingleProviderPluginEntry` + `openclaw.plugin.json`), no con models.dev.

Eso hace que LatinRouter aparezca como grupo nombrado en el wizard (`openclaw onboard`), no como “Custom Provider”.

## Requisitos

- Cuenta y API key en [latinrouter.ai](https://latinrouter.ai)
- OpenClaw **no** es requisito previo: el instalador lo gestiona solo

## Comportamiento del instalador

| Situación | Qué hace |
|-----------|----------|
| OpenClaw no instalado | Instala desde el oficial (`openclaw.ai/install.sh` / `.ps1`) con `--no-onboard` cuando aplica |
| OpenClaw presente | Pregunta update si existe `openclaw update` (Enter = Sí) |
| Plugin | Copia/link a `~/.openclaw/extensions/latinrouter` + `plugins install --link` / `enable` |
| API key | Pregunta interactiva; Enter vacío = `openclaw onboard` → More… → LatinRouter |
| Idioma | Automático (es / en) |

Para no actualizar: `LATINROUTER_SKIP_OPENCLAW_UPDATE=1`.

## Paths

| Qué | Default |
|-----|---------|
| State / home | `~/.openclaw/` (`OPENCLAW_STATE_DIR` / `OPENCLAW_HOME`) |
| Plugin | `~/.openclaw/extensions/latinrouter/` |
| Env keys | `~/.openclaw/.env` |
| Config | `~/.openclaw/openclaw.json` |
| Auth profiles | `~/.openclaw/agents/<id>/agent/auth-profiles.json` |

## Instalación

### Linux / macOS / WSL2

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.sh | bash
```

### Windows nativo (PowerShell)

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.ps1)
```

### Desde un clone local

```bash
bash openclaw/install.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File openclaw\install.ps1
```

## Uso (wizard)

```bash
openclaw onboard
```

1. Si te pide proveedor: **More…** → **LatinRouter**
2. Pega la API key
3. Los modelos se listan desde el gateway
4. Verifica: `openclaw models list`

Si el instalador ya recibió la key, puede aplicar auth non-interactive (`--auth-choice latinrouter-api-key`).

## Limitaciones conocidas

| Objetivo | Estado |
|----------|--------|
| Nombrado en el wizard (no Custom) | Sí — plugin + `providerAuthChoices` |
| Solo pegar API key | Sí |
| Modelos live `/v1/models` | Sí |
| Primero / Featured (Popular) | **No** sin PR a OpenClaw — `FEATURED_PROVIDER_AUTH_GROUP_ORDER` es fijo (openai, openrouter, xai, google, anthropic) |

Workaround “primero”: el instalador puede configurar auth non-interactive para no pasar por el picker.

## Troubleshooting

| Problema | Qué revisar |
|----------|-------------|
| LatinRouter no sale en onboard | Plugin en `extensions/latinrouter`, `openclaw plugins list`, reiniciar gateway |
| Sin modelos | Key en `.env` / auth profiles; `curl -H "Authorization: Bearer $KEY" https://llm.latinrouter.ai/v1/models` |
| `openclaw` no encontrado | Terminal nueva (PATH); reinstalar desde [openclaw.ai](https://openclaw.ai) |

## Archivos en este repo

```text
openclaw/
├── install.sh
├── install.ps1
├── plugin/
│   ├── index.ts
│   ├── openclaw.plugin.json
│   ├── package.json
│   └── README.md
└── README.md
```
