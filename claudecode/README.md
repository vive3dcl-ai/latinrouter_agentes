# LatinRouter — Claude Code (oficial)

Instalador que apunta Claude Code a LatinRouter vía `~/.claude/settings.json` (`ANTHROPIC_BASE_URL` + key).

Docs oficiales: [code.claude.com](https://code.claude.com/docs/en/setup)

## One-liners

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/claudecode/install.sh | bash
```

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/claudecode/install.ps1)
```

## Uso

```bash
claude
# /status
```

## Requisito del gateway

Claude Code habla **Anthropic Messages** (`POST /v1/messages`), no OpenAI Chat Completions.  
Si LatinRouter aún no lo expone, el instalador deja la config lista y muestra un aviso.

Docs: [docs/claudecode.md](../docs/claudecode.md)
