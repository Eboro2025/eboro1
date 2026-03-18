import 'dart:async';
import 'dart:convert';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final int? resendToken;

  const OTPVerificationScreen({
    super.key,
    required this.phone,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone,
      forceResendingToken: widget.resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Auth2.show(e.message ?? 'Errore');
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _verificationId = verificationId;
        });
        Auth2.show('OTP reinviato');
        _startCountdown();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOTP() async {
    FocusScope.of(context).unfocus();
    final code = _otpController.text.trim();

    if (code.isEmpty) {
      Auth2.show(AppLocalizations.of(context)?.translate('enterOTP') ??
          'Inserisci il codice OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Verify with Firebase
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Auth2.show('Verifica fallita');
        return;
      }

      // 2. Get Firebase ID token
      String? firebaseToken = await userCredential.user!.getIdToken();

      // 3. Send to your Laravel backend to get app token
      final String myUrl = '$globalUrl/api/firebase-phone-login';
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {
          'firebase_token': firebaseToken ?? '',
          'mobile': widget.phone,
          'name': widget.phone,
        },
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = json.decode(response.body);
        if (result['status'] == 'success' && result['data'] != null) {
          MyApp2.prefs.setString('firstTime', 'firstTime');
          MyApp2.token = "Bearer ${result['data']['token']}";

          if (result['data']['refresh_token'] != null) {
            MyApp2.prefs.setString(
                'refresh_token', result['data']['refresh_token']);
          }

          await Auth2.getUserDetails(context);
          await Auth2.checkType(MyApp2.token!, context);
        } else {
          final msg = result['message'] ??
              result['errors']?.toString() ??
              response.body;
          Auth2.show(msg.toString());
        }
      } else {
        Auth2.show('Errore dal server: ${response.statusCode}');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.code == 'invalid-verification-code') {
        Auth2.show('Codice OTP non valido');
      } else {
        Auth2.show(e.message ?? 'Errore di verifica');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Auth2.show('Connessione fallita. Controlla la connessione internet.');
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
            right: -w * 0.12,
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
            top: h * 0.18,
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
                              color: myColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 24,
                            height: 4,
                            decoration: BoxDecoration(
                              color: myColor,
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
                            Icons.sms_rounded,
                            size: 44,
                            color: myColor,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate('verifyOTP') ??
                              'Verifica OTP',
                          style: TextStyle(
                            fontSize: (MyApp2.fontSize20 ?? 20) + 4,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D1D35),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Phone chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: myColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_rounded,
                                  size: 16, color: myColor),
                              const SizedBox(width: 6),
                              Text(
                                widget.phone,
                                style: TextStyle(
                                  color: myColor,
                                  fontSize: MyApp2.fontSize14 ?? 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppLocalizations.of(context)
                                    ?.translate('otpSentDesc') ??
                                'Inserisci il codice a 6 cifre inviato al tuo numero.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: MyApp2.fontSize14 ?? 14,
                              color: Colors.grey[500],
                              height: 1.5,
                            ),
                          ),
                        ),

                        SizedBox(height: h * 0.04),

                        // OTP input
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
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: TextStyle(
                              fontSize: (MyApp2.fontSize20 ?? 20) + 4,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1D35),
                              letterSpacing: 12,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '------',
                              hintStyle: TextStyle(
                                color: Colors.grey[300],
                                fontWeight: FontWeight.w400,
                                letterSpacing: 12,
                              ),
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, right: 12),
                                child: Icon(Icons.pin_rounded,
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

                        const SizedBox(height: 16),

                        // Resend timer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_resendCountdown > 0) ...[
                              Icon(Icons.timer_outlined,
                                  size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                '${AppLocalizations.of(context)?.translate('resendIn') ?? 'Reinvia tra'} ${_resendCountdown}s',
                                style: TextStyle(
                                  fontSize: MyApp2.fontSize14 ?? 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ] else
                              GestureDetector(
                                onTap: _resendOTP,
                                child: Text(
                                  AppLocalizations.of(context)
                                          ?.translate('resendOTP') ??
                                      'Reinvia codice OTP',
                                  style: TextStyle(
                                    fontSize: MyApp2.fontSize14 ?? 14,
                                    color: myColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Verify button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOTP,
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
                                                ?.translate('verify') ??
                                            'Verifica',
                                        style: TextStyle(
                                          fontSize: MyApp2.fontSize16 ?? 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_rounded,
                                          size: 20),
                                    ],
                                  ),
                          ),
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
