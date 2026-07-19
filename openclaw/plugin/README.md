# LatinRouter — OpenClaw provider plugin

Plugin de proveedor para [OpenClaw](https://openclaw.ai) (`openclaw onboard` wizard).

| Campo | Valor |
|-------|--------|
| Provider id | `latinrouter` |
| Base URL | `https://llm.latinrouter.ai/v1` |
| Auth | API key (`LATINROUTER_API_KEY`) |
| Modelos | Live `GET /v1/models` |
| Wizard | **More… → LatinRouter** (featured/Popular es hardcodeado en OpenClaw) |

## Install

Prefer the repo one-liners in [../README.md](../README.md). Manual:

```bash
openclaw plugins install --link ./openclaw/plugin
openclaw plugins enable latinrouter
openclaw onboard
# More… → LatinRouter → paste API key
```
