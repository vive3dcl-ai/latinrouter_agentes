# LatinRouter + Hermes Agent

Guía para usar LatinRouter como proveedor nativo en [Hermes Agent](https://github.com/NousResearch/hermes-agent).

Compatible con **Linux, macOS y Windows** (nativo y WSL2).

## Listado automático de modelos

Sí: al elegir LatinRouter e ingresar la API key, Hermes llama a:

```text
GET https://llm.latinrouter.ai/v1/models
Authorization: Bearer <LATINROUTER_API_KEY>
```

Eso lo hace el `ProviderProfile.fetch_models` de Hermes (mismo flujo que NVIDIA, DeepSeek, etc.). El plugin declara:

- `base_url`: `https://llm.latinrouter.ai/v1`
- `models_url`: `https://llm.latinrouter.ai/v1/models`

No hace falta mantener a mano una lista de modelos en el plugin; el catálogo viene del gateway. Si `/models` falla, el picker no tiene fallback estático (`fallback_models` vacío).

## Por qué un plugin (y no solo “custom endpoint”)

Hermes ya habla con cualquier endpoint OpenAI-compatible vía “Custom endpoint”. Un **model-provider plugin** da UX de primera clase:

- Aparece como **LatinRouter** en `hermes model`
- Variable dedicada `LATINROUTER_API_KEY`
- Catálogo live desde `/v1/models`
- Sin editar el código de Hermes ni esperar un PR upstream

Discovery oficial: `$HERMES_HOME/plugins/model-providers/<name>/` (ver [Model Provider Plugins](https://hermes-agent.nousresearch.com/docs/developer-guide/model-provider-plugin)).

## Requisitos

- Hermes instalado (`hermes` en PATH)
- Cuenta y API key en [latinrouter.ai](https://latinrouter.ai)

### Instalar Hermes

| Plataforma | Comando |
|------------|---------|
| Linux / macOS / WSL2 | `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash` |
| Windows nativo | `iex (irm https://hermes-agent.nousresearch.com/install.ps1)` |

Luego recarga el shell (`source ~/.bashrc` / nueva ventana de PowerShell).

## Instalación del proveedor LatinRouter

| Plataforma | `HERMES_HOME` por defecto | Instalador |
|------------|---------------------------|------------|
| Linux / macOS | `~/.hermes` | `bash hermes/install.sh` |
| WSL2 | `~/.hermes` (dentro de WSL) | `bash hermes/install.sh` |
| Windows nativo | `%LOCALAPPDATA%\hermes` | `hermes\install.ps1` |
| Git Bash (Windows nativo) | `%LOCALAPPDATA%\hermes` (auto) | `bash hermes/install.sh` o `.ps1` |

### Linux / macOS / WSL2

```bash
bash hermes/install.sh
```

One-liner (repo publicado):

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh | bash
```

### Windows nativo (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File hermes\install.ps1
```

One-liner (repo publicado):

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.ps1)
```

**Importante:** si usas Hermes en **WSL2**, instala el plugin **dentro de WSL** con `install.sh`. Si usas Hermes **nativo en Windows**, usa `install.ps1`. Son homes distintos (`~/.hermes` vs `%LOCALAPPDATA%\hermes`).

El script:

1. Resuelve `HERMES_HOME` según la plataforma
2. Copia el plugin a `$HERMES_HOME/plugins/model-providers/latinrouter/`
3. Imprime los siguientes pasos

## Uso

```bash
hermes model
```

1. Selecciona **LatinRouter**
2. Pega tu API key (se guarda en `$HERMES_HOME/.env` como `LATINROUTER_API_KEY`)
3. Hermes lista los modelos del gateway automáticamente
4. Elige un modelo y chatea:

```bash
hermes
```

Flags útiles:

```bash
hermes -z "hola" --provider latinrouter -m <nombre-modelo>
```

Aliases del proveedor: `latinrouter`, `latin-router`, `lr`.

### Key manual

En `$HERMES_HOME/.env` (Linux/macOS/WSL: `~/.hermes/.env`; Windows: `%LOCALAPPDATA%\hermes\.env`):

```bash
LATINROUTER_API_KEY=sk-...
# opcional:
# LATINROUTER_BASE_URL=https://llm.latinrouter.ai/v1
```

## Qué instala el plugin

```
$HERMES_HOME/plugins/model-providers/latinrouter/
├── __init__.py      # register_provider(ProviderProfile(...))
├── plugin.yaml      # kind: model-provider
└── README.md
```

Perfil:

| Campo | Valor |
|-------|--------|
| `name` | `latinrouter` |
| `base_url` | `https://llm.latinrouter.ai/v1` |
| `models_url` | `https://llm.latinrouter.ai/v1/models` |
| `env_vars` | `LATINROUTER_API_KEY`, `LATINROUTER_BASE_URL` |
| `auth_type` | `api_key` |
| `signup_url` | `https://latinrouter.ai` |

Hermes auto-inyecta el perfil en: picker de modelos, auth, doctor, setup y runtime.

## Desinstalación

Linux / macOS / WSL2:

```bash
rm -rf "${HERMES_HOME:-$HOME/.hermes}/plugins/model-providers/latinrouter"
```

Windows (PowerShell):

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\hermes\plugins\model-providers\latinrouter"
```

Opcional: quitar `LATINROUTER_API_KEY` del `.env` correspondiente.

## Troubleshooting

| Problema | Qué revisar |
|----------|-------------|
| LatinRouter no aparece en `hermes model` | Que exista `$HERMES_HOME/plugins/model-providers/latinrouter/__init__.py`; reinicia la terminal |
| Plugin instalado pero Hermes no lo ve (Windows) | ¿Instalaste en WSL y corres Hermes nativo (o al revés)? Usa el home correcto |
| 401 / Missing API key | Key válida en `.env` o reconfigura con `hermes model` |
| Lista de modelos vacía | `curl -H "Authorization: Bearer $LATINROUTER_API_KEY" https://llm.latinrouter.ai/v1/models` |
| `hermes` no encontrado | Reinstalar Hermes y abrir un shell nuevo |

## Desarrollo / actualizar el plugin

1. Edita `hermes/plugin/latinrouter/`
2. Re-ejecuta `install.sh` o `install.ps1`
3. Verifica con `hermes model`

No hace falta reiniciar un daemon: Hermes descubre plugins al arrancar cada sesión CLI.

## Relación con upstream

Esta integración es **terceros** (drop-in en `$HERMES_HOME`). Un PR a `NousResearch/hermes-agent` bajo `plugins/model-providers/latinrouter/` haría que llegue a todos los usuarios sin instalador; es opcional y no requerido para el flujo documentado aquí.
