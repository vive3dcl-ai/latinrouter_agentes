# LatinRouter — OpenCode

Instalador y plugin para usar LatinRouter en [OpenCode](https://github.com/anomalyco/opencode).

## Quick install

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
```

```powershell
# Windows
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.ps1)
```

## Qué hace

1. Instala OpenCode si falta (oficial)
2. Si hay update disponible, pregunta (Enter = Sí) y corre `opencode upgrade`
3. Copia el plugin a `~/.config/opencode/plugins/latinrouter.js`
4. Merge de `opencode.json` con el proveedor LatinRouter
5. Pregunta API key (opcional) → auth + modelos + default

Actualizar OpenCode **no** borra LatinRouter (plugin/config/key viven en `~/.config` y `~/.local`).

## Uso

```bash
opencode
# /connect → LatinRouter
# /models  → catálogo del gateway
```

Docs: [docs/opencode.md](../docs/opencode.md)
