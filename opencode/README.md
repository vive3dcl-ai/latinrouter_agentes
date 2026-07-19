# LatinRouter — OpenCode

Instaladores y plugin para usar LatinRouter en [OpenCode](https://github.com/anomalyco/opencode).

Docs completos: [docs/opencode.md](../docs/opencode.md) · Cheatsheet: [docs/install.md](../docs/install.md#opencode)

## One-liners

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
```

```powershell
# Windows nativo
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.ps1)
```

## Clone local

```bash
bash opencode/install.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File opencode\install.ps1
```

## Qué hace el instalador

| Paso | Acción |
|------|--------|
| 1 | Si no hay `opencode` → instalador oficial (`opencode.ai/install` / scoop·npm·choco) |
| 2 | Si hay update → pregunta *¿Actualizar ahora? [S/n]* (Enter = Sí) → `opencode upgrade` |
| 3 | Copia `plugin/latinrouter.js` → `~/.config/opencode/plugins/` |
| 4 | Merge no destructivo de `opencode.json` (provider + **models** seed) |
| 5 | Prompt API key (opcional) → `auth.json` + fetch `/v1/models` + default `model` |

Actualizar OpenCode **no** borra LatinRouter (plugin/config/key viven fuera del binario).

## Después

```bash
opencode
# /connect → LatinRouter (primero en Providers) → API key
# /models  → catálogo del gateway
```

## Opciones

```bash
LATINROUTER_SKIP_OPENCODE_UPDATE=1 bash opencode/install.sh
```

## Archivos

```text
opencode/
├── install.sh          # Linux / macOS / WSL2
├── install.ps1         # Windows nativo
├── plugin/
│   └── latinrouter.js  # auth + config (seed modelos)
└── README.md
```
