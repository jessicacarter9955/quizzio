const OPENAI_URL = 'https://api.openai.com/v1/chat/completions';

/**
 * Shared chat core used by both Cloudflare Workers and Netlify Functions.
 *
 * @param {Object} params
 * @param {Array} params.messages   OpenAI-style messages [{ role, content }, ...]
 * @param {string} [params.model]   Model name, defaults to gpt-4o-mini
 * @param {string} [params.provider] Provider id, currently only 'openai' supported
 * @param {number} [params.temperature] Sampling temperature
 * @param {Object} params.env       Environment-like object containing secrets
 * @returns {Promise<{ provider: string, model: string, reply: string }>} Result
 */
export async function handleChat({
  messages,
  model,
  provider = 'openai',
  temperature = 0.7,
  env,
}) {
  if (!Array.isArray(messages) || messages.length === 0) {
    throw new Error('messages must be a non-empty array');
  }

  if (provider !== 'openai') {
    throw new Error(`Unsupported provider: ${provider}`);
  }

  if (!env) {
    throw new Error('env object is required');
  }

  const apiKey =
    env.OPENAI_API_KEY || env.OPENAI_APIKEY || env.OPENAI_KEY || env.openaiApiKey;
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is not set in environment.');
  }

  const usedModel = model || 'gpt-4o-mini';
  const usedTemperature =
    typeof temperature === 'number' && !Number.isNaN(temperature)
      ? temperature
      : 0.7;

  const body = {
    model: usedModel,
    messages,
    temperature: usedTemperature,
  };

  const response = await fetch(OPENAI_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  const text = await response.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch (_) {
    data = null;
  }

  if (response.status !== 200 || !data) {
    let reason = '';
    if (data && data.error && typeof data.error === 'object') {
      reason = data.error.message || JSON.stringify(data.error);
    } else if (text && !data) {
      reason = text.slice(0, 400);
    }
    if (!reason) {
      reason = `Upstream error with status ${response.status}`;
    }
    throw new Error(reason);
  }

  const choices = data.choices;
  if (!Array.isArray(choices) || choices.length === 0) {
    throw new Error('AI returned an empty response.');
  }

  const first = choices[0];
  const message = first && first.message;
  const content = message && message.content;
  const replyText = typeof content === 'string' ? content : String(content || '').trim();

  if (!replyText) {
    throw new Error('AI returned an empty response.');
  }

  return {
    provider: 'openai',
    model: usedModel,
    reply: replyText,
  };
}
