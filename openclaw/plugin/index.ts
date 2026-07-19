/**
 * LatinRouter provider plugin for OpenClaw.
 *
 * - Named wizard entry: More… → LatinRouter (not "Custom Provider")
 * - API key only (LATINROUTER_API_KEY)
 * - Live models from GET https://llm.latinrouter.ai/v1/models
 *
 * Install: openclaw plugins install --link ./openclaw/plugin
 * Docs: https://docs.openclaw.ai/plugins/sdk-provider-plugins
 */

import { defineSingleProviderPluginEntry } from "openclaw/plugin-sdk/provider-entry";
import {
  getCachedLiveProviderModelRows,
  LiveModelCatalogHttpError,
} from "openclaw/plugin-sdk/provider-catalog-live-runtime";
import type { ModelDefinitionConfig } from "openclaw/plugin-sdk/provider-model-shared";

const PROVIDER_ID = "latinrouter";
const BASE_URL = "https://llm.latinrouter.ai/v1";
const ENV_VAR = "LATINROUTER_API_KEY";
const GROUP_HINT = "Gateway IA Centralizado para Latinoamérica";

const DEFAULT_COST = {
  input: 0,
  output: 0,
  cacheRead: 0,
  cacheWrite: 0,
} as const;

const FALLBACK_MODELS: ModelDefinitionConfig[] = [
  {
    id: "latinrouter",
    name: "LatinRouter (set API key)",
    reasoning: false,
    input: ["text"],
    cost: { ...DEFAULT_COST },
    contextWindow: 128_000,
    maxTokens: 8192,
  },
];

function modelFromId(id: string): ModelDefinitionConfig {
  return {
    id,
    name: id,
    reasoning: false,
    input: ["text"],
    cost: { ...DEFAULT_COST },
    contextWindow: 128_000,
    maxTokens: 8192,
  };
}

async function discoverModels(apiKey: string): Promise<ModelDefinitionConfig[]> {
  try {
    const rows = await getCachedLiveProviderModelRows({
      providerId: PROVIDER_ID,
      endpoint: `${BASE_URL}/models`,
      apiKey,
      ttlMs: 60_000,
      auditContext: "latinrouter-model-discovery",
    });
    const models = rows
      .map((row) => {
        const id = typeof row?.id === "string" ? row.id.trim() : "";
        return id ? modelFromId(id) : null;
      })
      .filter((m): m is ModelDefinitionConfig => m !== null);
    return models.length > 0 ? models : FALLBACK_MODELS;
  } catch (error) {
    if (error instanceof LiveModelCatalogHttpError) {
      return FALLBACK_MODELS;
    }
    throw error;
  }
}

function staticProviderConfig() {
  return {
    baseUrl: BASE_URL,
    api: "openai-completions" as const,
    models: FALLBACK_MODELS,
  };
}

async function liveProviderConfig(apiKey: string) {
  return {
    baseUrl: BASE_URL,
    api: "openai-completions" as const,
    apiKey,
    models: await discoverModels(apiKey),
  };
}

export default defineSingleProviderPluginEntry({
  id: PROVIDER_ID,
  name: "LatinRouter",
  description: `LatinRouter (${GROUP_HINT})`,
  provider: {
    label: "LatinRouter",
    docsPath: "https://latinrouter.ai",
    envVars: [ENV_VAR],
    auth: [
      {
        methodId: "api-key",
        label: "LatinRouter API key",
        hint: GROUP_HINT,
        optionKey: "latinrouterApiKey",
        flagName: "--latinrouter-api-key",
        envVar: ENV_VAR,
        promptMessage: "Enter your LatinRouter API key",
        defaultModel: `${PROVIDER_ID}/latinrouter`,
        wizard: {
          choiceId: "latinrouter-api-key",
          choiceLabel: "LatinRouter API key",
          choiceHint: GROUP_HINT,
          groupId: PROVIDER_ID,
          groupLabel: "LatinRouter",
          groupHint: GROUP_HINT,
        },
      },
    ],
    // Custom run so we can resolve the API key from OpenClaw auth and fetch /v1/models.
    catalog: {
      order: "simple",
      run: async (ctx) => {
        const apiKey = ctx.resolveProviderApiKey(PROVIDER_ID).apiKey;
        if (!apiKey) return null;
        return { provider: await liveProviderConfig(apiKey) };
      },
      staticRun: async () => ({ provider: staticProviderConfig() }),
    },
    resolveDynamicModel: (ctx) => ({
      id: ctx.modelId,
      name: ctx.modelId,
      provider: PROVIDER_ID,
      api: "openai-completions",
      baseUrl: BASE_URL,
      reasoning: false,
      input: ["text"],
      cost: { ...DEFAULT_COST },
      contextWindow: 128_000,
      maxTokens: 8192,
    }),
  },
});
