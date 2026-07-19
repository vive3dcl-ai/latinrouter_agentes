/**
 * LatinRouter provider plugin for OpenCode.
 *
 * /connect lists models.dev ∪ providers that have ≥1 model in the runtime catalog.
 * Auth-only plugins do NOT appear. We seed models via the `config` hook so
 * LatinRouter shows under "Providers" (not Popular — that needs upstream
 * PROVIDER_PRIORITY in OpenCode).
 *
 * Drop into: ~/.config/opencode/plugins/latinrouter.js
 */

const BASE_URL = "https://llm.latinrouter.ai/v1"
const PROVIDER_ID = "latinrouter"
// Leading space pins LatinRouter first in the /connect "Providers" section
// (OpenCode sorts that section alphabetically by name; Popular requires upstream).
const DISPLAY_NAME = " LatinRouter (Gateway IA Centralizado para Latinoamérica)"
const SEED_MODEL_ID = "latinrouter"

function homeDir() {
  return process.env.HOME || process.env.USERPROFILE || ""
}

function authPaths() {
  const home = homeDir()
  const xdg = process.env.XDG_DATA_HOME
  const paths = []
  if (xdg) paths.push(`${xdg}/opencode/auth.json`)
  if (home) {
    paths.push(`${home}/.local/share/opencode/auth.json`)
    // Windows-style fallback used by some installs
    paths.push(`${home}/.config/opencode/auth.json`)
  }
  return paths
}

async function readApiKey() {
  const envKey = process.env.LATINROUTER_API_KEY
  if (envKey && String(envKey).trim()) return String(envKey).trim()

  for (const path of authPaths()) {
    try {
      const file = Bun.file(path)
      if (!(await file.exists())) continue
      const data = await file.json()
      const entry = data?.[PROVIDER_ID]
      if (entry?.type === "api" && entry.key) return String(entry.key).trim()
    } catch {
      // try next path
    }
  }
  return ""
}

function configModelsFromIds(ids) {
  const out = {}
  for (const id of ids) {
    if (!id) continue
    out[id] = { name: id }
  }
  return out
}

async function fetchModelIds(apiKey) {
  if (!apiKey) return []
  const res = await fetch(`${BASE_URL}/models`, {
    headers: {
      Authorization: `Bearer ${apiKey}`,
      Accept: "application/json",
    },
    signal: AbortSignal.timeout(12000),
  }).catch(() => undefined)
  if (!res || !res.ok) return []
  const body = await res.json().catch(() => undefined)
  const items = Array.isArray(body) ? body : body?.data
  if (!Array.isArray(items)) return []
  const ids = []
  for (const item of items) {
    const id = item && typeof item === "object" ? item.id : undefined
    if (typeof id === "string" && id) ids.push(id)
  }
  return ids
}

function makeRuntimeModel(id) {
  const name = String(id)
  return {
    id: name,
    providerID: PROVIDER_ID,
    name,
    family: "latinrouter",
    api: {
      id: name,
      url: BASE_URL,
      npm: "@ai-sdk/openai-compatible",
    },
    status: "active",
    headers: {},
    options: {},
    cost: { input: 0, output: 0, cache: { read: 0, write: 0 } },
    limit: { context: 128000, output: 8192 },
    capabilities: {
      temperature: true,
      reasoning: false,
      attachment: false,
      toolcall: true,
      input: { text: true, audio: false, image: false, video: false, pdf: false },
      output: { text: true, audio: false, image: false, video: false, pdf: false },
      interleaved: false,
    },
    release_date: "",
    variants: {},
  }
}

export async function LatinRouterPlugin() {
  return {
    auth: {
      provider: PROVIDER_ID,
      methods: [
        {
          type: "api",
          label: "LatinRouter API key",
        },
      ],
    },

    /**
     * Inject provider + models into config so /connect and Provider.list include us.
     * (plugin `provider.models` only runs for providers already in models.dev.)
     */
    async config(cfg) {
      cfg.provider = cfg.provider ?? {}
      const prev = cfg.provider[PROVIDER_ID]
      const entry = prev && typeof prev === "object" ? { ...prev } : {}
      const prevModels =
        entry.models && typeof entry.models === "object" ? entry.models : {}

      const key = await readApiKey()
      const liveIds = await fetchModelIds(key)
      let models = prevModels
      if (liveIds.length > 0) {
        models = { ...configModelsFromIds(liveIds), ...prevModels }
      } else if (!models || Object.keys(models).length === 0) {
        // Seed so OpenCode keeps the provider (empty models ⇒ deleted from catalog)
        models = {
          [SEED_MODEL_ID]: {
            name: "LatinRouter (pega API key en /connect)",
          },
        }
      }

      cfg.provider[PROVIDER_ID] = {
        ...entry,
        npm: entry.npm || "@ai-sdk/openai-compatible",
        name: DISPLAY_NAME,
        env: entry.env || ["LATINROUTER_API_KEY"],
        options: {
          ...(entry.options && typeof entry.options === "object" ? entry.options : {}),
          baseURL:
            (entry.options && entry.options.baseURL) || BASE_URL,
        },
        models,
      }

      // Prefer LatinRouter as default model when none set and we have a real id
      if (!cfg.model && liveIds.length > 0) {
        cfg.model = `${PROVIDER_ID}/${liveIds[0]}`
      }
    },

    provider: {
      id: PROVIDER_ID,
      async models(provider, ctx) {
        // Only used if latinrouter is ever in models.dev; keep for forward-compat.
        const base = provider?.models ?? {}
        const key =
          (ctx?.auth?.type === "api" && ctx.auth.key) ||
          process.env.LATINROUTER_API_KEY ||
          (await readApiKey()) ||
          ""
        const liveIds = await fetchModelIds(key)
        const live = Object.fromEntries(liveIds.map((id) => [id, makeRuntimeModel(id)]))
        return { ...base, ...live }
      },
    },
  }
}

export default LatinRouterPlugin
