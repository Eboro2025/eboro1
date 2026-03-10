import 'dart:convert';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Auth/OTPVerification.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:eboro/package/intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  String _fullPhone = '';
  bool _isLoading = false;
  bool _callbackReceived = false;

  Future<void> _sendOTP() async {
    FocusScope.of(context).unfocus();

    if (_fullPhone.isEmpty) {
      Auth2.show(AppLocalizations.of(context)?.translate('enterPhone') ??
          'Inserisci il numero di telefono');
      return;
    }

    setState(() => _isLoading = true);
    _callbackReceived = false;
    print('Sending OTP to: $_fullPhone');

    // Safety timeout - stop loading after 30 seconds if no callback received
    Future.delayed(const Duration(seconds: 30), () {
      if (!_callbackReceived && mounted) {
        setState(() => _isLoading = false);
        Auth2.show(
            'Timeout: controlla che Phone Authentication sia abilitato in Firebase Console e che SHA-1 sia configurato.');
      }
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android) - sign in directly
          _callbackReceived = true;
          print('Auto verification completed');
          try {
            UserCredential userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
            if (userCredential.user != null) {
              _loginToBackend(userCredential);
            }
          } catch (e) {
            print('Auto sign-in error: $e');
            if (mounted) setState(() => _isLoading = false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _callbackReceived = true;
          print('verificationFailed code: ${e.code}');
          print('verificationFailed message: ${e.message}');
          if (!mounted) return;
          setState(() => _isLoading = false);

          String errorMsg;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMsg = 'Numero di telefono non valido';
              break;
            case 'too-many-requests':
              errorMsg = 'Troppe richieste. Riprova più tardi';
              break;
            case 'app-not-authorized':
              errorMsg =
                  'App non autorizzata. Abilita Phone Authentication in Firebase Console e aggiungi SHA-1';
              break;
            case 'missing-client-identifier':
              errorMsg =
                  'Configurazione mancante. Aggiungi SHA-1 e SHA-256 in Firebase Console e ricarica google-services.json';
              break;
            default:
              errorMsg = '${e.message ?? "Errore"} (${e.code})';
          }
          Auth2.show(errorMsg);
        },
        codeSent: (String verificationId, int? resendToken) {
          _callbackReceived = true;
          print('Code sent! verificationId: $verificationId');
          if (!mounted) return;
          setState(() => _isLoading = false);
          Auth2.show('Codice OTP inviato');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(
                phone: _fullPhone,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _callbackReceived = true;
          print('Auto retrieval timeout');
          if (!mounted) return;
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      _callbackReceived = true;
      print('verifyPhoneNumber exception: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      Auth2.show('Errore: $e');
    }
  }

  Future<void> _loginToBackend(UserCredential userCredential) async {
    try {
      String? firebaseToken = await userCredential.user!.getIdToken();
      final String myUrl = '$globalUrl/api/firebase-phone-login';
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {
          'firebase_token': firebaseToken ?? '',
          'mobile': _fullPhone,
          'name': _fullPhone,
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        if (result['status'] == 'success' && result['data'] != null) {
          MyApp2.prefs.setString('firstTime', 'firstTime');
          MyApp2.token = "Bearer ${result['data']['token']}";
          await Auth2.getUserDetails(context);
          await Auth2.checkType(MyApp2.token!, context);
        }
      }
    } catch (e) {
      print('loginToBackend error: $e');
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
            top: -h * 0.06,
            left: -w * 0.12,
            child: Container(
              width: w * 0.5,
              height: w * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: myColor.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: h * 0.15,
            right: -w * 0.15,
            child: Container(
              width: w * 0.35,
              height: w * 0.35,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      const SizedBox(width: 16),
                      // Step indicator
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 4,
                            decoration: BoxDecoration(
                              color: myColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 24,
                            height: 4,
                            decoration: BoxDecoration(
                              color: myColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
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
                        SizedBox(height: h * 0.03),

                        // Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: myColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.phone_android_rounded,
                            size: 48,
                            color: myColor,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Title
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate('loginWithPhone') ??
                              'Accedi con Telefono',
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
                                    ?.translate('phoneLoginDesc') ??
                                'Inserisci il tuo numero di telefono e ti invieremo un codice di verifica.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: MyApp2.fontSize14 ?? 14,
                              color: Colors.grey[500],
                              height: 1.6,
                            ),
                          ),
                        ),

                        SizedBox(height: h * 0.05),

                        // Phone field
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: IntlPhoneField(
                              disableLengthCheck: true,
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: AppLocalizations.of(context)
                                        ?.translate('mobilenumber') ??
                                    'Numero di telefono',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 16),
                              ),
                              initialCountryCode: 'IT',
                              style: TextStyle(
                                fontSize: MyApp2.fontSize16 ?? 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1D1D35),
                              ),
                              onChanged: (phone) {
                                _fullPhone = phone.completeNumber;
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Send OTP button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOTP,
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
                                                ?.translate('sendOTP') ??
                                            'Invia codice OTP',
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
                                        ?.translate('backToLogin') ??
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
