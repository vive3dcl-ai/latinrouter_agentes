# Comandos de instalación — LatinRouter Agentes

Referencia rápida de instaladores por agente y plataforma.

Repo: https://github.com/vive3dcl-ai/latinrouter_agentes  
Gateway: `https://llm.latinrouter.ai/v1`  
API key: https://latinrouter.ai

---

## Hermes Agent

Instala (o actualiza si hace falta) Hermes desde el oficial de NousResearch y registra **LatinRouter** como proveedor nativo.

| Situación | Comportamiento |
|-----------|----------------|
| Sin Hermes | Instala Hermes oficial automáticamente |
| Hermes desactualizado | Pregunta si actualizar (Enter = Sí) |
| Hermes al día | Solo instala el proveedor LatinRouter |
| Idioma | Automático según la consola (es / en) |

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh | bash
```

Funciona en distros comunes (Ubuntu, Debian, Fedora, Arch, etc.) con `bash` y `curl`.

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh | bash
```

### WSL2 (Windows Subsystem for Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh | bash
```

Usa el home de Linux (`~/.hermes`), no el de Windows nativo.

### Windows nativo (PowerShell)

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.ps1)
```

Home: `%LOCALAPPDATA%\hermes`

### Desde un clone local

```bash
# Linux / macOS / WSL2
bash hermes/install.sh
```

```powershell
# Windows nativo
powershell -ExecutionPolicy Bypass -File hermes\install.ps1
```

### Después de instalar (Hermes)

```bash
hermes model    # LatinRouter preseleccionado → pegar API key → elegir modelo
hermes          # chatear
```

### Opciones útiles (Hermes)

```bash
# No preguntar por actualizar Hermes
LATINROUTER_SKIP_HERMES_UPDATE=1 bash hermes/install.sh
```

Docs: [hermes.md](hermes.md)

---

## OpenCode

Instala (o actualiza si hace falta) [OpenCode](https://opencode.ai) desde el oficial y registra **LatinRouter** como proveedor (plugin + `opencode.json`).

| Situación | Comportamiento |
|-----------|----------------|
| Sin OpenCode | Instala OpenCode oficial automáticamente |
| OpenCode desactualizado | Pregunta si actualizar (Enter = Sí) |
| OpenCode al día | Solo instala/actualiza el proveedor LatinRouter |
| API key | Pregunta interactiva (Enter = omitir → `/connect` después) |
| Idioma | Automático según la consola (es / en) |
| Lista `/connect` | LatinRouter **primero** en **Providers** (Popular requiere PR upstream) |

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
```

Funciona en distros comunes (Ubuntu, Debian, Fedora, Arch, etc.) con `bash` y `curl`.

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
```

### WSL2 (Windows Subsystem for Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
```

Usa el home de Linux (`~/.config/opencode`), no el de Windows nativo.

### Windows nativo (PowerShell)

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.ps1)
```

Config: `%USERPROFILE%\.config\opencode\`  
Si no hay OpenCode: intenta scoop → npm → choco.

### Desde un clone local

```bash
# Linux / macOS / WSL2
bash opencode/install.sh
```

```powershell
# Windows nativo
powershell -ExecutionPolicy Bypass -File opencode\install.ps1
```

### Qué escribe el instalador

| Archivo | Contenido |
|---------|-----------|
| `plugins/latinrouter.js` | Plugin (`auth` + seed de modelos) |
| `opencode.json` | Provider `latinrouter` + `models` (obligatorio para salir en `/connect`) |
| `auth.json` | API key si la pegaste en el prompt |
| `model.json` | Modelo reciente/default si hubo key y `/v1/models` OK |

### Después de instalar (OpenCode)

```bash
opencode
# /connect → LatinRouter (arriba en Providers) → API key   (si no la diste en el instalador)
# /models  → elegir modelo del gateway
```

Reinicia OpenCode si ya estaba abierto para que cargue el plugin nuevo.

### Opciones útiles (OpenCode)

```bash
# No preguntar por actualizar OpenCode
LATINROUTER_SKIP_OPENCODE_UPDATE=1 bash opencode/install.sh
```

Docs: [opencode.md](opencode.md)

---

## OpenClaw

Instala (si hace falta) [OpenClaw](https://openclaw.ai) y registra **LatinRouter** como proveedor nombrado del wizard (`openclaw onboard`).

| Situación | Comportamiento |
|-----------|----------------|
| Sin OpenClaw | Instala OpenClaw oficial (`--no-onboard` cuando aplica) |
| OpenClaw presente | Pregunta update si existe `openclaw update` (Enter = Sí) |
| API key | Pregunta interactiva (Enter = omitir → wizard) |
| Wizard | **More… → LatinRouter** (Featured es hardcodeado upstream) |
| Idioma | Automático según la consola (es / en) |

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.sh | bash
```

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.sh | bash
```

### WSL2

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.sh | bash
```

Usa `~/.openclaw` de Linux, no el de Windows nativo.

### Windows nativo (PowerShell)

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.ps1)
```

Home: `%USERPROFILE%\.openclaw`

### Desde un clone local

```bash
bash openclaw/install.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File openclaw\install.ps1
```

### Después de instalar (OpenClaw)

```bash
openclaw onboard
# More… → LatinRouter → API key
openclaw models list
```

### Opciones útiles (OpenClaw)

```bash
LATINROUTER_SKIP_OPENCLAW_UPDATE=1 bash openclaw/install.sh
```

Docs: [openclaw.md](openclaw.md)

---

## OpenCodex

Pendiente.

```bash
# (próximamente)
```

---

## Claude Code

Pendiente.

```bash
# (próximamente)
```

---

## Resumen rápido

| Agente | Linux / macOS / WSL2 | Windows nativo |
|--------|----------------------|----------------|
| **Hermes** | `curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.sh \| bash` | `iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/hermes/install.ps1)` |
| **OpenCode** | `curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh \| bash` | `iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.ps1)` |
| **OpenClaw** | `curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.sh \| bash` | `iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.ps1)` |
| OpenCodex | — | — |
| Claude Code | — | — |
