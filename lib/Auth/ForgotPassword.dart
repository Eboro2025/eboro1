import 'dart:convert';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Auth/ResetPassword.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => ForgotPasswordState();
}

class ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> sendResetCode() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      Auth2.show('Inserisci l\'email');
      return;
    }
    if (!_isValidEmail(email)) {
      Auth2.show('Inserisci un\'email valida');
      return;
    }

    setState(() => _isLoading = true);

    final String myUrl = '$globalUrl/api/sendResetCode';

    try {
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {'email': email},
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      print('sendResetCode status: ${response.statusCode}');
      print('sendResetCode body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = json.decode(response.body);
        if (result['status'] == 'success') {
          Auth2.show(result['message'] ?? 'Codice inviato');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: email),
            ),
          );
        } else {
          final msg = result['message'] ??
              result['errors']?.toString() ??
              response.body;
          Auth2.show(msg.toString());
        }
      } else {
        Auth2.show('Errore dal server: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('sendResetCode error: $e');
      Auth2.show('Connessione al server fallita. Controlla la connessione internet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Stack(
        children: [
          // Decorative shapes
          Positioned(
            top: -h * 0.08,
            right: -w * 0.15,
            child: Container(
              width: w * 0.55,
              height: w * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: myColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: h * 0.12,
            left: -w * 0.1,
            child: Container(
              width: w * 0.3,
              height: w * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: myColor.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(Icons.arrow_back_ios_new,
                              size: 18, color: myColor2),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: h * 0.04),

                        // Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: myColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.lock_open_rounded,
                            size: 48,
                            color: myColor,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Title
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate('forgotPassword') ??
                              'Password dimenticata?',
                          style: TextStyle(
                            fontSize: (MyApp2.fontSize20 ?? 20) + 6,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D1D35),
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppLocalizations.of(context)
                                    ?.translate('changeyourpassword') ??
                                'Non preoccuparti! Inserisci la tua email e ti invieremo un codice di verifica per reimpostare la password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: MyApp2.fontSize14 ?? 14,
                              color: Colors.grey[500],
                              height: 1.6,
                            ),
                          ),
                        ),

                        SizedBox(height: h * 0.06),

                        // Email field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: MyApp2.fontSize16 ?? 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1D1D35),
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)
                                      ?.translate('email') ??
                                  'Email',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 16, right: 12),
                                child: Icon(Icons.email_outlined,
                                    color: myColor, size: 22),
                              ),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 48),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 20),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Send button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : sendResetCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  myColor.withValues(alpha: 0.7),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)
                                                ?.translate('send') ??
                                            'Invia codice di verifica',
                                        style: TextStyle(
                                          fontSize: MyApp2.fontSize16 ?? 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 20),
                                    ],
                                  ),
                          ),
                        ),

                        SizedBox(height: h * 0.04),

                        // Back to login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back_rounded,
                                size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                AppLocalizations.of(context)
                                        ?.translate('signin') ??
                                    'Torna al login',
                                style: TextStyle(
                                  color: myColor,
                                  fontSize: MyApp2.fontSize14 ?? 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: h * 0.04),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
