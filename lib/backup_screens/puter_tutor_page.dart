import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PuterTutorPage extends StatefulWidget {
  const PuterTutorPage({super.key});

  @override
  State<PuterTutorPage> createState() => _PuterTutorPageState();
}

class _PuterTutorPageState extends State<PuterTutorPage> {
  late final WebViewController _controller;

  static const String _initialHtml = '''<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Puter Tutor</title>
    <style>
      body {
        margin: 0;
        font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        background-color: #0b141a;
        color: #e9edef;
      }
      #container {
        display: flex;
        flex-direction: column;
        height: 100vh;
      }
      #messages {
        flex: 1;
        overflow-y: auto;
        padding: 12px;
        box-sizing: border-box;
      }
      .msg {
        margin-bottom: 8px;
        max-width: 90%;
      }
      .user {
        text-align: right;
      }
      .user span {
        display: inline-block;
        background: #005c4b;
        padding: 8px 12px;
        border-radius: 16px 4px 16px 16px;
      }
      .bot span {
        display: inline-block;
        background: #202c33;
        padding: 8px 12px;
        border-radius: 4px 16px 16px 16px;
      }
      #inputRow {
        display: flex;
        padding: 8px;
        border-top: 1px solid rgba(255, 255, 255, 0.06);
        box-sizing: border-box;
        background: #202c33;
      }
      #input {
        flex: 1;
        padding: 8px 12px;
        border-radius: 20px;
        border: none;
        outline: none;
        background: #111b21;
        color: #e9edef;
        font-size: 14px;
      }
      #sendBtn {
        margin-left: 8px;
        padding: 0 16px;
        border-radius: 20px;
        border: none;
        background: #00a884;
        color: #fff;
        font-size: 14px;
      }
      #hint {
        padding: 4px 12px 0;
        font-size: 11px;
        color: rgba(233, 237, 239, 0.6);
      }
    </style>
  </head>
  <body>
    <div id="container">
      <div id="messages"></div>
      <div id="hint">Powered by Puter.ai – no API key needed. Try asking in your target language.</div>
      <div id="inputRow">
        <input id="input" type="text" placeholder="Type a message" autocomplete="off" />
        <button id="sendBtn">Send</button>
      </div>
    </div>

    <script src="https://js.puter.com/v2/"></script>
    <script>
      const messagesEl = document.getElementById('messages');
      const inputEl = document.getElementById('input');
      const sendBtn = document.getElementById('sendBtn');

      function appendMessage(text, isUser) {
        const wrapper = document.createElement('div');
        wrapper.className = 'msg ' + (isUser ? 'user' : 'bot');
        const bubble = document.createElement('span');
        bubble.textContent = text;
        wrapper.appendChild(bubble);
        messagesEl.appendChild(wrapper);
        messagesEl.scrollTop = messagesEl.scrollHeight;
      }

      async function sendMessage() {
        const text = inputEl.value.trim();
        if (!text) return;
        inputEl.value = '';
        appendMessage(text, true);
        try {
          const resp = await puter.ai.chat(text, { model: 'gpt-5-nano' });
          let content = resp;
          try {
            if (resp && resp.message && resp.message.content) {
              content = Array.isArray(resp.message.content)
                ? resp.message.content.map(p => (p.text || '')).join('\n')
                : resp.message.content;
            }
          } catch (e) {}
          appendMessage(String(content), false);
        } catch (e) {
          appendMessage('Error: ' + e, false);
        }
      }

      sendBtn.addEventListener('click', sendMessage);
      inputEl.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          sendMessage();
        }
      });

      appendMessage('Hola, soy tu tutor de idiomas impulsado por IA. \'Frag mich auf Deutsch, pregúntame en español, chiedimi in italiano...\'', false);
    </script>
  </body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_initialHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Tutor (Puter)',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
