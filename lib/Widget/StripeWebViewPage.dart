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

      // GPay flow returns ?pi=xxx, Checkout flow returns ?session_id=xxx
      final pi = uri.queryParameters['pi'];
      if (pi != null && pi.isNotEmpty) {
        // GPay: fetch from gpay success endpoint
        final fetchUrl = '$globalUrl/stripe/mobile-payment-success-gpay?pi=$pi';
        final response = await http.get(Uri.parse(fetchUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final paymentIntent = data['payment_intent'];
          if (mounted) Navigator.pop(context, paymentIntent);
        } else {
          if (mounted) Navigator.pop(context, null);
        }
        return;
      }

      // Checkout flow
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
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 18, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text(
              'Pagamento Sicuro',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.pop(context, null),
        ),
        bottom: _isLoading && !_hasError
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500),
                ),
              )
            : null,
      ),
      body: _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Errore di connessione',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Controlla la tua connessione e riprova',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() { _isLoading = true; _hasError = false; });
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Riprova'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
