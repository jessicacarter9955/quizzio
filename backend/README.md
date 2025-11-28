# Wordweaver Backend (Node + Express)

Simple AI proxy service for the Wordweaver app.

- Exposes a single `POST /chat` endpoint.
- Proxies to different AI vendors (currently OpenAI and Gemini).
- Keeps API keys **on the server**, never in the mobile app.

## Setup

```bash
cd backend
npm install
cp .env.example .env
# edit .env and set OPENAI_API_KEY / GEMINI_API_KEY
```

## Running locally

```bash
cd backend
npm run dev
# Server will start on http://localhost:3000 by default
```

## API

### `POST /chat`

**Request body (JSON):**

```json
{
  "provider": "openai",   // or "gemini"
  "model": "gpt-4o-mini", // or any OpenAI/Gemini model you configured
  "messages": [
    { "role": "system", "content": "You are a helpful tutor." },
    { "role": "user", "content": "Hello!" }
  ],
  "temperature": 0.4
}
```

- `provider` (string, optional): `"openai"` (default) or `"gemini"`.
- `model` (string, optional): model name, e.g. `"gpt-4o-mini"`, `"gpt-5-nano"`, `"gemini-1.5-flash"`.
- `messages` (array, **required**): OpenAI-style chat messages.
- `temperature` (number, optional): defaults to `0.4`.

**Success response:**

```json
{
  "provider": "openai",
  "model": "gpt-4o-mini",
  "reply": "...model text here..."
}
```

**Error response:**

```json
{
  "error": {
    "message": "...",
    "name": "Error",
    "context": { "provider": "openai", "model": "gpt-4o-mini" }
  }
}
```

In development (`NODE_ENV` not `production`), a simplified `stack` field may be included in the error for debugging.

## Notes

- This backend is intentionally small and focused.
- You can later update the Flutter app to call this `/chat` endpoint instead of going directly to the AI vendors.
- Make sure to **never commit `.env`** or real API keys.
