import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import OpenAI from 'openai';
import { GoogleGenerativeAI } from '@google/generative-ai';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '2mb' }));

// --- AI clients (lazily constructed) ---
let openaiClient = null;
function getOpenAI() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is not set');
  }
  if (!openaiClient) {
    openaiClient = new OpenAI({ apiKey });
  }
  return openaiClient;
}

let geminiClient = null;
function getGemini(modelName) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not set');
  }
  if (!geminiClient) {
    geminiClient = new GoogleGenerativeAI(apiKey);
  }
  return geminiClient.getGenerativeModel({ model: modelName || 'gemini-1.5-flash' });
}

// --- Helpers ---
function summarizeMessages(messages) {
  if (!Array.isArray(messages)) return '[]';
  return messages
    .map((m) => `${m.role || 'user'}: ${(m.content || '').slice(0, 40)}...`)
    .join(' | ');
}

function buildErrorPayload(err, context) {
  const isDev = process.env.NODE_ENV !== 'production';
  const base = {
    message: err?.message || String(err),
    name: err?.name || 'Error',
    context,
  };
  if (isDev && err?.stack) {
    base.stack = err.stack;
  }
  return base;
}

// --- Routes ---
app.get('/health', (req, res) => {
  res.json({ ok: true, uptime: process.uptime() });
});

app.post('/chat', async (req, res) => {
  const {
    provider = 'openai',
    model,
    messages,
    temperature = 0.4,
  } = req.body || {};

  console.log('[CHAT] Incoming request', {
    provider,
    model,
    messageCount: Array.isArray(messages) ? messages.length : 0,
  });

  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({
      error: {
        message: 'messages must be a non-empty array',
      },
    });
  }

  try {
    let replyText = '';

    if (provider === 'openai') {
      const client = getOpenAI();
      const response = await client.chat.completions.create({
        model: model || 'gpt-4o-mini',
        messages,
        temperature,
      });

      const choice = response?.choices?.[0];
      replyText = choice?.message?.content || '';
    } else if (provider === 'gemini') {
      const joined = messages
        .map((m) => `${(m.role || 'user').toUpperCase()}: ${m.content || ''}`)
        .join('\n');

      const generativeModel = getGemini(model);
      const result = await generativeModel.generateContent(joined);
      replyText = result?.response?.text?.() || '';
    } else {
      return res.status(400).json({
        error: {
          message: `Unsupported provider: ${provider}`,
        },
      });
    }

    if (!replyText) {
      console.warn('[CHAT] Empty reply from provider', { provider, model });
      return res.status(502).json({
        error: {
          message: 'AI provider returned an empty response',
        },
      });
    }

    console.log('[CHAT] Success', {
      provider,
      model,
      summary: summarizeMessages(messages),
    });

    return res.json({
      provider,
      model,
      reply: replyText,
    });
  } catch (err) {
    console.error('[CHAT] Error', err);
    const payload = buildErrorPayload(err, { provider, model });
    return res.status(500).json({ error: payload });
  }
});

// Fallback 404
app.use((req, res) => {
  res.status(404).json({ error: { message: 'Not found' } });
});

app.listen(port, () => {
  console.log(`Wordweaver backend listening on http://localhost:${port}`);
});
