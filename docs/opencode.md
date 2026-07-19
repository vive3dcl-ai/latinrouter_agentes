# LatinRouter + OpenCode

Guía para usar LatinRouter como proveedor en [OpenCode](https://opencode.ai) ([anomalyco/opencode](https://github.com/anomalyco/opencode)).

Compatible con **Linux, macOS y Windows** (nativo y WSL2).

## Listado automático de modelos

Sí: el plugin llama a:

```text
GET https://llm.latinrouter.ai/v1/models
Authorization: Bearer <LATINROUTER_API_KEY>
```

vía el hook `provider.models`. El catálogo viene del gateway; no hay lista estática en el plugin.

## Por qué un plugin (y no solo config)

OpenCode lista proveedores nativos desde [models.dev](https://models.dev) o desde un **plugin con hook `auth`**. Un endpoint OpenAI-compatible no aparece solo en `/connect` ni lista modelos sin:

1. Plugin local en `~/.config/opencode/plugins/` con `auth` + `provider.models`
2. Entrada en `opencode.json` con `@ai-sdk/openai-compatible` y `baseURL`

Así LatinRouter aparece **nombrado** en `/connect` (hint `plugin`), no como “Other”.

## Requisitos

- Cuenta y API key en [latinrouter.ai](https://latinrouter.ai)
- OpenCode **no** es requisito previo: el instalador lo gestiona solo

## Comportamiento del instalador

| Situación | Qué hace |
|-----------|----------|
| OpenCode no instalado | Instala desde el oficial (`opencode.ai/install` en Unix; scoop/npm/choco en Windows) |
| OpenCode desactualizado | Pregunta: *¿Actualizar ahora? [S/n]* — Enter = **Sí**. Sin TTY, omite la actualización |
| OpenCode al día | Solo instala el proveedor LatinRouter |
| API key | Pregunta interactiva; Enter vacío = configurar después con `/connect` |
| Idioma | Automático (es / en) según locale / UI culture |

Para no actualizar OpenCode aunque haya versión nueva: `LATINROUTER_SKIP_OPENCODE_UPDATE=1`.

## ¿Se pierde LatinRouter al actualizar OpenCode?

**No.** `opencode upgrade` (o el prompt de actualización del instalador) solo cambia el binario. El proveedor vive fuera:

- Plugin: `~/.config/opencode/plugins/latinrouter.js`
- Config: `~/.config/opencode/opencode.json`
- API key: `~/.local/share/opencode/auth.json`

Sí se pierde (salvo flags) con `opencode uninstall`, que borra config/datos relacionados. Usa `--keep-config` / `--keep-data` si quieres conservarlas.

## Paths

| Qué | Unix / WSL | Windows |
|-----|------------|---------|
| Config | `~/.config/opencode/opencode.json` | `%USERPROFILE%\.config\opencode\opencode.json` |
| Plugin | `~/.config/opencode/plugins/latinrouter.js` | `%USERPROFILE%\.config\opencode\plugins\latinrouter.js` |
| Auth | `~/.local/share/opencode/auth.json` | `%USERPROFILE%\.local\share\opencode\auth.json` |
| Model state | `~/.local/state/opencode/model.json` | `%USERPROFILE%\.local\state\opencode\model.json` |

Respeta `XDG_CONFIG_HOME` / `XDG_DATA_HOME` / `XDG_STATE_HOME` si están definidos.

## Instalación

### Linux / macOS / WSL2

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
```

### Windows nativo (PowerShell)

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.ps1)
```

### Desde un clone local

```bash
bash opencode/install.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File opencode\install.ps1
```

**Importante:** en **WSL2** corre `install.sh` dentro de WSL. En Windows nativo usa `install.ps1`.

## Uso

```bash
opencode
```

1. Si no pegaste la key en el instalador: `/connect` → **LatinRouter** → pega la API key
2. `/models` → elige un modelo del gateway
3. Si el instalador recibió la key, el chat ya puede arrancar con `latinrouter/<modelo>` por defecto

También puedes exportar `LATINROUTER_API_KEY` (el provider declara esa env var).

## Qué hace el merge de config

El instalador escribe (merge no destructivo) algo equivalente a:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "latinrouter/<primer-modelo>",
  "provider": {
    "latinrouter": {
      "npm": "@ai-sdk/openai-compatible",
      "name": " LatinRouter (Gateway IA Centralizado para Latinoamérica)",
      "env": ["LATINROUTER_API_KEY"],
      "options": {
        "baseURL": "https://llm.latinrouter.ai/v1"
      },
      "models": {
        "latinrouter": { "name": "LatinRouter (pega API key en /connect)" }
      }
    }
  }
}
```

Otras keys y providers del usuario se conservan.

## Limitaciones conocidas

| Objetivo | Estado |
|----------|--------|
| Nombrado en `/connect` | Sí — requiere ≥1 modelo en config (el plugin/instalador lo siembra) |
| Primero en sección **Providers** | Sí — el `name` lleva un espacio inicial para ganar el sort alfabético de OpenCode |
| Modelos live del gateway | Sí — hook `config` + `/v1/models` cuando hay key |
| Modelo por defecto LatinRouter | Sí (`model` + state si hay key) |
| Primero en sección **Popular** de `/connect` | **No** sin PR a OpenCode (`PROVIDER_PRIORITY` está hardcodeado: opencode, openai, anthropic, …) |

Tras reinstalar/actualizar el plugin, reinicia OpenCode. LatinRouter aparece **primero** en **Providers** (no en Popular). Para conectar la key: `/connect` → LatinRouter.

### Workaround inmediato (si aún no lo ves)

```bash
# Reinstala plugin + config con modelo seed
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
# reinicia opencode → /connect → busca LatinRouter en Providers
```

O vía CLI: `opencode providers login --provider latinrouter`

## Troubleshooting

| Problema | Qué revisar |
|----------|-------------|
| LatinRouter no sale en `/connect` | Reinstalar (necesita `models` en config), reiniciar OpenCode; debe estar en **Providers**, no en Popular |
| Sin modelos en `/models` | API key en auth o `LATINROUTER_API_KEY`; probar `curl -H "Authorization: Bearer $KEY" https://llm.latinrouter.ai/v1/models` |
| `opencode` no encontrado tras instalar | Abrir terminal nueva (PATH); en Windows: scoop/npm/choco |
| Config sobrescrita | El merge solo toca `provider.latinrouter` y opcionalmente `model`; reportar si se pierde otra key |

## Archivos en este repo

```text
opencode/
├── install.sh
├── install.ps1
├── plugin/
│   └── latinrouter.js
└── README.md
```
