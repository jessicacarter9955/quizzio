import { handleChat } from '../../core/chatCore.js';

/**
 * Netlify Function wrapper around the shared chat core.
 *
 * Expects POST /chat with JSON body { provider, model, temperature, messages }.
 */
export async function handler(event, context) {
  if (event.httpMethod && event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: { message: 'Method not allowed' } }),
    };
  }

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch (_) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: { message: 'Invalid JSON body' } }),
    };
  }

  try {
    const result = await handleChat({
      messages: body.messages,
      model: body.model,
      provider: body.provider,
      temperature: body.temperature,
      env: process.env,
    });

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(result),
    };
  } catch (err) {
    const message = err && err.message ? err.message : String(err);
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: { message } }),
    };
  }
}
