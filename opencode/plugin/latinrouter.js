/**
 * LatinRouter provider plugin for OpenCode.
 *
 * - Appears in /connect as "LatinRouter" (auth hook)
 * - Lists models live from GET https://llm.latinrouter.ai/v1/models
 *
 * Drop into: ~/.config/opencode/plugins/latinrouter.js
 */

const BASE_URL = "https://llm.latinrouter.ai/v1"
const PROVIDER_ID = "latinrouter"
const DISPLAY_NAME = "LatinRouter (Gateway IA Centralizado para Latinoamérica)"

function makeModel(id, providerID) {
  const name = String(id)
  return {
    id: name,
    providerID,
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

async function fetchModels(apiKey) {
  if (!apiKey) return {}
  const res = await fetch(`${BASE_URL}/models`, {
    headers: {
      Authorization: `Bearer ${apiKey}`,
      Accept: "application/json",
    },
    signal: AbortSignal.timeout(12000),
  }).catch(() => undefined)
  if (!res || !res.ok) return {}
  const body = await res.json().catch(() => undefined)
  const items = Array.isArray(body) ? body : body?.data
  if (!Array.isArray(items)) return {}
  const out = {}
  for (const item of items) {
    const id = item && typeof item === "object" ? item.id : undefined
    if (typeof id !== "string" || !id) continue
    out[id] = makeModel(id, PROVIDER_ID)
  }
  return out
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
    provider: {
      id: PROVIDER_ID,
      async models(provider, ctx) {
        const base = provider?.models ?? {}
        const key =
          (ctx?.auth?.type === "api" && ctx.auth.key) ||
          process.env.LATINROUTER_API_KEY ||
          ""
        const live = await fetchModels(key)
        return { ...base, ...live }
      },
    },
  }
}

// OpenCode loads any exported plugin function(s) from the module.
export default LatinRouterPlugin
