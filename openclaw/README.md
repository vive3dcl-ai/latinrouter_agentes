# LatinRouter — OpenClaw

Instaladores y plugin de proveedor para [OpenClaw](https://openclaw.ai) ([openclaw/openclaw](https://github.com/openclaw/openclaw)).

## One-liners

```bash
# Linux / macOS / WSL2
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.sh | bash
```

```powershell
# Windows nativo
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/openclaw/install.ps1)
```

## Qué hace

1. Instala OpenClaw si falta (`openclaw.ai/install` / `install.ps1`, `--no-onboard`)
2. Pregunta update si `openclaw update` existe (Enter = Sí)
3. Instala el plugin en `~/.openclaw/extensions/latinrouter`
4. Prompt API key (opcional) → `.env` + auth non-interactive si aplica

## Después

```bash
openclaw onboard
# More… → LatinRouter → API key
openclaw models list
```

Featured/Popular del wizard es hardcodeado en OpenClaw (OpenAI, OpenRouter, xAI, Google, Anthropic). LatinRouter sale nombrado bajo **More…**.

Docs: [docs/openclaw.md](../docs/openclaw.md)
