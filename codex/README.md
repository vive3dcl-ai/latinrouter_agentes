# LatinRouter — OpenAI Codex (oficial)

Instalador que registra **LatinRouter** como `model_providers.latinrouter` en `~/.codex/config.toml`.

Repo oficial: [openai/codex](https://github.com/openai/codex)

## One-liners

```bash
curl -fsSL https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/codex/install.sh | bash
```

```powershell
iex (irm https://raw.githubusercontent.com/vive3dcl-ai/latinrouter_agentes/main/codex/install.ps1)
```

## Uso

```bash
codex --profile latinrouter
```

## Requisito del gateway

Codex actual solo habla `wire_api = "responses"` (`POST /v1/responses`).  
Si LatinRouter aún no lo expone, el instalador deja la config lista y muestra un aviso.

Docs: [docs/codex.md](../docs/codex.md)
