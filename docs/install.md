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

Instala (si hace falta) OpenCode desde el oficial y registra **LatinRouter** como proveedor (plugin + config).

| Situación | Comportamiento |
|-----------|----------------|
| Sin OpenCode | Instala OpenCode oficial automáticamente |
| OpenCode presente | Solo instala el proveedor LatinRouter |
| API key | Pregunta interactiva (Enter = omitir → `/connect` después) |
| Idioma | Automático según la consola (es / en) |

### Linux / macOS / WSL2

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.sh | bash
```

### Windows nativo (PowerShell)

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/opencode/install.ps1)
```

Config: `%USERPROFILE%\.config\opencode\`

### Desde un clone local

```bash
bash opencode/install.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File opencode\install.ps1
```

### Después de instalar (OpenCode)

```bash
opencode
# /connect → LatinRouter → API key   (si no la diste en el instalador)
# /models  → elegir modelo del gateway
```

Docs: [opencode.md](opencode.md)

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

## OpenClaw

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
| OpenCodex | — | — |
| Claude Code | — | — |
| OpenClaw | — | — |
