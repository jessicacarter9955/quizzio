import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PuterAuthPage extends StatefulWidget {
  const PuterAuthPage({super.key});

  @override
  State<PuterAuthPage> createState() => _PuterAuthPageState();
}

class _PuterAuthPageState extends State<PuterAuthPage> {
  late final WebViewController _controller;

  static const String _authHtml = '''<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Puter Login</title>
    <style>
      body {
        margin: 0;
        font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        background-color: #0b141a;
        color: #e9edef;
        display: flex;
        flex-direction: column;
        height: 100vh;
      }
      #content {
        padding: 16px;
        box-sizing: border-box;
        flex: 1;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: stretch;
        max-width: 480px;
        margin: 0 auto;
      }
      h1 {
        font-size: 20px;
        margin: 0 0 8px 0;
      }
      p {
        font-size: 14px;
        margin: 0 0 12px 0;
        color: rgba(233, 237, 239, 0.8);
      }
      #status {
        font-size: 13px;
        margin-bottom: 12px;
        min-height: 18px;
      }
      button {
        padding: 10px 16px;
        border-radius: 999px;
        border: none;
        background-color: #00a884;
        color: #fff;
        font-size: 14px;
      }
    </style>
  </head>
  <body>
    <div id="content">
      <h1>Puter login</h1>
      <p>Sign in with your Puter.com account so WordWeaver can use free AI via Puter on this device.</p>
      <div id="status">Checking sign-in status...</div>
      <button id="loginBtn">Sign in with Puter</button>
    </div>

    <script src="https://js.puter.com/v2/"></script>
    <script>
      const statusEl = document.getElementById('status');
      const btn = document.getElementById('loginBtn');

      async function refreshStatus() {
        try {
          const signedIn = puter.auth.isSignedIn();
          if (!signedIn) {
            statusEl.textContent = 'Not signed in.';
            return;
          }
          const user = await puter.auth.getUser();
          const label = user && (user.email || user.username || user.name)
            ? (user.email || user.username || user.name)
            : 'Puter user';
          statusEl.textContent = 'Signed in as ' + label + '.';
        } catch (e) {
          statusEl.textContent = 'Error: ' + e;
        }
      }

      btn.addEventListener('click', async () => {
        try {
          statusEl.textContent = 'Opening Puter sign-in...';
          await puter.auth.signIn();
          await refreshStatus();
        } catch (e) {
          statusEl.textContent = 'Error: ' + e;
        }
      });

      refreshStatus();
    </script>
  </body>
</html>''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_authHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Puter login',
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
