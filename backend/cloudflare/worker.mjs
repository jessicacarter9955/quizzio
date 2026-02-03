import { handleChat } from '../core/chatCore.js';

const BRIDGE_HTML = `<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Puter Bridge</title>
    <script src="https://js.puter.com/v2/"></script>
  </head>
  <body>
    <script>
      function withTimeout(promise, ms) {
        return new Promise((resolve, reject) => {
          const t = setTimeout(() => reject(new Error('Request timed out')), ms);
          Promise.resolve(promise).then(
            (v) => { clearTimeout(t); resolve(v); },
            (e) => { clearTimeout(t); reject(e); }
          );
        });
      }

      function flutterPuterPing() {
        try {
          if (window.FlutterPuterBridge && window.FlutterPuterBridge.postMessage) {
            window.FlutterPuterBridge.postMessage(
              JSON.stringify({ id: 'ping', content: 'ping from JS' })
            );
          }
        } catch (e) {}
      }
      setTimeout(flutterPuterPing, 1500);

      function puterBootstrapReport() {
        try {
          if (!window.FlutterPuterBridge || !window.FlutterPuterBridge.postMessage) {
            return;
          }
          const hasPuter = typeof puter !== 'undefined';
          window.FlutterPuterBridge.postMessage(
            JSON.stringify({
              id: 'bootstrap',
              content: hasPuter ? 'Puter JS loaded in WebView' : 'Puter JS NOT available in WebView (network / CSP?)',
            })
          );
        } catch (e) {
          try {
            window.FlutterPuterBridge.postMessage(
              JSON.stringify({ id: 'bootstrap', error: String(e) })
            );
          } catch (_) {}
        }
      }
      setTimeout(puterBootstrapReport, 2500);

      window.PuterFlutterBridge = {
        send: async function(requestJson) {
          try {
            const req = typeof requestJson === 'string' ? JSON.parse(requestJson) : requestJson;
            const id = req.id;
            const kind = req.kind || 'chat';

            let content = '';
            let audioDataUrl = '';

            if (kind === 'speech2txt') {
              const source = req.source || req.audio || req.file;
              const options = {};
              if (req.model) options.model = req.model;
              if (req.language) options.language = req.language;
              if (typeof req.translate === 'boolean') options.translate = !!req.translate;

              let result;
              if (Object.keys(options).length === 0) {
                result = await withTimeout(puter.ai.speech2txt(source), 25000);
              } else {
                result = await withTimeout(puter.ai.speech2txt(source, options), 25000);
              }
              content = result && result.text ? result.text : ('' + result);
            } else if (kind === 'speech2speech') {
              const source = req.source || req.audio || req.file;
              const options = {};
              if (req.voice || req.voiceId || req.voice_id) {
                options.voice = req.voice || req.voiceId || req.voice_id;
              }
              if (req.model || req.modelId || req.model_id) {
                options.model = req.model || req.modelId || req.model_id;
              }

              const audioEl = Object.keys(options).length === 0
                ? await withTimeout(puter.ai.speech2speech(source), 25000)
                : await withTimeout(puter.ai.speech2speech(source, options), 25000);

              let src = audioEl && audioEl.src ? audioEl.src : '';
              if (src.startsWith('blob:')) {
                try {
                  const resp = await fetch(src);
                  const blob = await resp.blob();
                  src = await new Promise((resolve) => {
                    const reader = new FileReader();
                    reader.onloadend = () => resolve(reader.result);
                    reader.readAsDataURL(blob);
                  });
                } catch (e) {
                  src = '';
                }
              }

              audioDataUrl = src || '';
            } else {
              const model = req.model || 'gpt-5-nano';
              const messages = req.messages || [];

              const resp = await withTimeout(puter.ai.chat(messages, { model }), 25000);

              try {
                if (typeof resp === 'string') {
                  content = resp;
                } else if (resp && resp.message && resp.message.content) {
                  const mc = resp.message.content;
                  if (Array.isArray(mc)) {
                    content = mc.map(p => p.text || '').join('\n');
                  } else {
                    content = String(mc);
                  }
                } else {
                  content = JSON.stringify(resp);
                }
              } catch (e) {
                content = String(resp);
              }
            }

            if (window.FlutterPuterBridge && window.FlutterPuterBridge.postMessage) {
              window.FlutterPuterBridge.postMessage(
                JSON.stringify({ id, content, audioDataUrl })
              );
            }
          } catch (e) {
            let parsedId = null;
            try {
              const parsed = JSON.parse(requestJson);
              parsedId = parsed.id;
            } catch (_) {}

            if (window.FlutterPuterBridge && window.FlutterPuterBridge.postMessage) {
              window.FlutterPuterBridge.postMessage(
                JSON.stringify({ id: parsedId, error: String(e) })
              );
            }
          }
        }
      };
    </script>
  </body>
</html>`;

export default {
  /**
   * Cloudflare Worker entry point.
   * Exposes POST /chat which forwards to handleChat and returns JSON.
   */
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (request.method === 'GET') {
      if (url.pathname === '/' || url.pathname === '/index.html') {
        return new Response(BRIDGE_HTML, {
          status: 200,
          headers: { 'Content-Type': 'text/html; charset=utf-8' },
        });
      }
      if (url.pathname === '/health') {
        return new Response('ok', {
          status: 200,
          headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        });
      }
    }

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
