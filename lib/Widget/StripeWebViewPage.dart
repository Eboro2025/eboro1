import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:eboro/main.dart';

/// WebView page for Stripe card payment
class StripeWebViewPage extends StatefulWidget {
  final String url;
  final WebViewController? preloadedController;
  const StripeWebViewPage({super.key, required this.url, this.preloadedController});

  @override
  State<StripeWebViewPage> createState() => _StripeWebViewPageState();
}

class _StripeWebViewPageState extends State<StripeWebViewPage> {
  late final WebViewController _controller;
  bool _popped = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.preloadedController ?? WebViewController();
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() { _isLoading = true; _hasError = false; });
            _checkForSuccess(url);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() { _isLoading = false; });
            _checkForSuccess(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == true) {
              if (mounted) setState(() { _isLoading = false; _hasError = true; });
            }
          },
          onUrlChange: (UrlChange change) {
            _checkForSuccess(change.url ?? '');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkForSuccess(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    if (widget.preloadedController == null) {
      _controller.loadRequest(Uri.parse(widget.url));
    } else {
      _isLoading = false;
    }
  }

  bool _checkForSuccess(String url) {
    if (_popped) return true;
    if (url.contains('mobile-payment-success')) {
      _popped = true;
      _fetchPaymentIntent(url);
      return true;
    } else if (url.contains('mobile-payment-cancel')) {
      _popped = true;
      Navigator.pop(context, null);
      return true;
    }
    return false;
  }

  Future<void> _fetchPaymentIntent(String url) async {
    try {
      final uri = Uri.parse(url);
      final sessionId = uri.queryParameters['session_id'];
      final fetchUrl = '$globalUrl/stripe/mobile-payment-success?session_id=$sessionId';
      final response = await http.get(Uri.parse(fetchUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentIntent = data['payment_intent'];
        if (mounted) Navigator.pop(context, paymentIntent);
      } else {
        if (mounted) Navigator.pop(context, null);
      }
    } catch (e) {
      debugPrint('Stripe WebView fetch error: $e');
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: Stack(
        children: [
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Errore di connessione', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() { _isLoading = true; _hasError = false; });
                      _controller.reload();
                    },
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading && !_hasError)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
