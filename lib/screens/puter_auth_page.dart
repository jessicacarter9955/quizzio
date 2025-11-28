import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PuterAuthPage extends StatefulWidget {
  const PuterAuthPage({super.key});

  @override
  State<PuterAuthPage> createState() => _PuterAuthPageState();
}

class _PuterAuthPageState extends State<PuterAuthPage> {
  late final WebViewController _controller;
  final ValueNotifier<String> _status = ValueNotifier<String>(
    'Loading Puter login page...',
  );

  static final Uri _authUri = Uri.parse('https://puter.com/apps/auth/login');

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _status.value = 'Opening Puter sign-in...';
          },
          onPageFinished: (url) {
            _status.value =
                'If you have a Puter.com account, sign in above then tap back to return.';
          },
          onWebResourceError: (error) {
            _status.value =
                'Failed to load Puter login (${error.errorCode}): ${error.description}';
          },
        ),
      )
      ..loadRequest(_authUri);
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in with your Puter.com account so WordWeaver can use free AI via Puter on this device.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String>(
                    valueListenable: _status,
                    builder: (context, value, _) {
                      return Text(
                        value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
