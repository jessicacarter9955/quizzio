import { handleChat } from '../core/chatCore.js';

export default {
  /**
   * Cloudflare Worker entry point.
   * Exposes POST /chat which forwards to handleChat and returns JSON.
   */
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (url.pathname !== '/chat') {
      return new Response('Not found', { status: 404 });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    let body;
    try {
      body = await request.json();
    } catch (_) {
      return new Response(
        JSON.stringify({ error: { message: 'Invalid JSON body' } }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        },
      );
    }

    try {
      const result = await handleChat({
        messages: body.messages,
        model: body.model,
        provider: body.provider,
        temperature: body.temperature,
        env,
      });

      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    } catch (err) {
      const message = err && err.message ? err.message : String(err);
      return new Response(
        JSON.stringify({ error: { message } }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        },
      );
    }
  },
};
