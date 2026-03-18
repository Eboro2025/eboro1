import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:provider/provider.dart' as prov;
import 'package:eboro/Auth/Signup.dart';
import 'package:eboro/Auth/PhoneLogin.dart';
import 'package:eboro/Client/Addresses.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:eboro/package/lib/google_map_location_picker_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

import '../API/Categories.dart';
import '../Helper/UserData.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
  static String email = "";
  static String password = "";
  static bool autoLogin = false;
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  bool _rememberMe = false;
  bool _showEmailLogin = false;
  bool _showForgotPassword = false;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _resetEmailController = TextEditingController();
  late AddressResult selectedPlace;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    // أولوية للبيانات من التسجيل الجديد
    if (LoginScreen.email.isNotEmpty) {
      final email = LoginScreen.email;
      final password = LoginScreen.password;
      LoginScreen.email = "";
      LoginScreen.password = "";

      if (mounted) {
        setState(() {
          _emailController.text = email;
          if (password.isNotEmpty) {
            _passwordController.text = password;
          }
          _showEmailLogin = true;
        });
      }
      return;
    }

    final remember = await _storage.read(key: 'remember_me');
    if (remember == 'true') {
      final savedEmail = await _storage.read(key: 'saved_email') ?? '';
      final savedPassword = await _storage.read(key: 'saved_password') ?? '';
      if (mounted) {
        setState(() {
          _rememberMe = true;
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
        });
      }
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await _storage.write(key: 'remember_me', value: 'true');
      await _storage.write(key: 'saved_email', value: _emailController.text);
      await _storage.write(key: 'saved_password', value: _passwordController.text);
    } else {
      await _storage.delete(key: 'remember_me');
      await _storage.delete(key: 'saved_email');
      await _storage.delete(key: 'saved_password');
    }
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _showEmailLogin ? _buildEmailLoginView(h, w) : _buildMainView(h, w),
    );
  }

  // ==================== MAIN VIEW (New Design) ====================
  Widget _buildMainView(double h, double w) {
    return Column(
      children: [
        // ── Yellow Header Section ──
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFFC107),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: [
                  // Logo + Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'images/icons/logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.red[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Italia',
                              style: TextStyle(
                                fontSize: (MyApp2.fontSize14 ?? 14) - 1,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D1D35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tagline + Person Image
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You dream,\nwe deliver fast',
                                style: TextStyle(
                                  fontSize: (MyApp2.fontSize20 ?? 20) + 6,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1D1D35),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: myColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Image.asset(
                        'images/icons/delivery-man.png',
                        height: h * 0.18,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.delivery_dining,
                          size: h * 0.12,
                          color: myColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── White Bottom Section ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Apple & Google Login Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _handleAppleLogin,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Image.asset('images/icons/apple.png', height: 28, width: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: _handleGoogleLogin,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Image.asset('images/icons/gmail.png', height: 28, width: 28),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Phone Login Button (Red/filled)
                _buildSocialButton(
                  icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 22),
                  label: 'Continua con Telefono',
                  outlined: false,
                  backgroundColor: myColor,
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Divider with "or"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: MyApp2.fontSize14 ?? 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                  ],
                ),

                const SizedBox(height: 20),

                // Guest Mode
                GestureDetector(
                  onTap: _joinAsGuest,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline_rounded, color: Colors.grey[600], size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Guest Mode',
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16 ?? 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Email login link
                GestureDetector(
                  onTap: () {
                    setState(() => _showEmailLogin = true);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email_outlined, size: 18, color: myColor),
                      const SizedBox(width: 6),
                      Text(
                        'Accedi con Email',
                        style: TextStyle(
                          color: myColor,
                          fontSize: MyApp2.fontSize14 ?? 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Non hai un account? ",
                      style: TextStyle(
                        fontSize: MyApp2.fontSize14 ?? 14,
                        color: myColor2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => SignupScreen()),
                        );
                      },
                      child: Text(
                        'Registrati',
                        style: TextStyle(
                          fontSize: MyApp2.fontSize14 ?? 14,
                          color: myColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== EMAIL LOGIN VIEW ====================
  Widget _buildEmailLoginView(double h, double w) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showEmailLogin = false),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.arrow_back_ios_new, size: 18, color: myColor2),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Accedi',
                  style: TextStyle(
                    fontSize: (MyApp2.fontSize20 ?? 20),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1D35),
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
                  SizedBox(height: h * 0.03),

                  // Logo
                  Image.asset(
                    'images/icons/logo.png',
                    height: h * 0.12,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: h * 0.04),

                  // Email field
                  _buildInputField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 14),

                  // Password field
                  _buildInputField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscureText,
                    showToggle: true,
                    onToggle: _toggle,
                  ),

                  const SizedBox(height: 8),

                  // Remember me + Forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() => _rememberMe = val ?? false);
                              },
                              activeColor: myColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: Text(
                              'Ricordami',
                              style: TextStyle(
                                fontSize: MyApp2.fontSize14 ?? 14,
                                color: myColor2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showForgotPassword = true;
                            _resetEmailController.text = _emailController.text;
                          });
                        },
                        child: Text(
                          'Password dimenticata?',
                          style: TextStyle(
                            fontSize: MyApp2.fontSize14 ?? 14,
                            color: myColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Forgot password inline field
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showForgotPassword
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5FA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _resetEmailController,
                                      keyboardType: TextInputType.emailAddress,
                                      cursorColor: myColor,
                                      style: TextStyle(
                                        fontSize: MyApp2.fontSize16 ?? 16,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1D1D35),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Email per reset password',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w400,
                                          fontSize: (MyApp2.fontSize14 ?? 14),
                                        ),
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.only(left: 16, right: 12),
                                          child: Icon(Icons.email_outlined, color: myColor, size: 22),
                                        ),
                                        prefixIconConstraints: const BoxConstraints(minWidth: 48),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                      ),
                                    ),
                                  ),
                                  // Close button
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _showForgotPassword = false);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(Icons.close, color: Colors.grey[400], size: 20),
                                    ),
                                  ),
                                  // Send arrow button
                                  GestureDetector(
                                    onTap: () async {
                                      if (_resetEmailController.text.isEmpty) {
                                        Auth2.show('Inserisci la tua email');
                                        return;
                                      }
                                      await Auth2.sendResetCode(_resetEmailController.text, context);
                                      setState(() {
                                        _emailController.text = _resetEmailController.text;
                                        _showForgotPassword = false;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: myColor,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                          await _saveCredentials();
                          await Auth2.login(_emailController.text, _passwordController.text, context, onChange: () async {
                            if (Auth2.user != null && Auth2.user?.address == null) {
                              var status = await Permission.location.request();
                              if (status.isGranted) {
                                // Location flow
                              } else if (status.isDenied || status.isPermanentlyDenied || status.isLimited) {
                                Fluttertoast.showToast(
                                  msg: 'Location access is denied',
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.CENTER,
                                  backgroundColor: Colors.grey,
                                );
                              }
                            }
                          });
                        } else {
                          Auth2.show('Inserisci email e password');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Accedi',
                        style: TextStyle(
                          fontSize: MyApp2.fontSize18 ?? 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.translate('donothaveanaccount') ?? "Non hai un account? ",
                        style: TextStyle(
                          fontSize: MyApp2.fontSize16 ?? 16,
                          color: myColor2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => SignupScreen()),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)?.translate('signup') ?? 'Registrati',
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16 ?? 16,
                            color: myColor,
                            fontWeight: FontWeight.w900,
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
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildSocialButton({
    required Widget icon,
    required String label,
    required bool outlined,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : (backgroundColor ?? myColor),
          borderRadius: BorderRadius.circular(18),
          border: outlined
              ? Border.all(color: Colors.grey[300]!, width: 1.5)
              : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: (backgroundColor ?? myColor).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: MyApp2.fontSize16 ?? 16,
                fontWeight: FontWeight.w600,
                color: outlined ? const Color(0xFF1D1D35) : (textColor ?? Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    bool showToggle = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        cursorColor: myColor,
        style: TextStyle(
          fontSize: MyApp2.fontSize16 ?? 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1D1D35),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: myColor, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: showToggle
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                    onPressed: onToggle,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  // ==================== SOCIAL LOGIN HANDLERS ====================

  Future<void> _handleGoogleLogin() async {
    Progress.progressDialogue(context);
    final googleSignIn = GoogleSignIn.instance;
    try {
      if (Platform.isIOS) {
        await googleSignIn.initialize(
          clientId: "646379856639-aml1v59cmi535kga9ojqi53l84rrvldd.apps.googleusercontent.com",
        );
      } else {
        await googleSignIn.initialize(
          serverClientId: "646379856639-6cetrrap6csblfffk2v8g14p46r5sqol.apps.googleusercontent.com",
        );
      }
      final currentUser = await googleSignIn.authenticate(scopeHint: ['email']);
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress dialog
      await Auth2.googlefacebooklogin(
        currentUser.email,
        currentUser.displayName,
        currentUser.photoUrl,
        currentUser.id,
        "1",
        context,
      );
      if (Auth2.user != null && Auth2.user?.address == null) {
        try {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
            Fluttertoast.showToast(
              msg: 'Location access is denied',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.grey,
            );
            return;
          }
          if (!mounted) return;
          LatLng myPosition;
          try {
            myPosition = await _getCurrentLocation();
          } catch (_) {
            myPosition = LatLng(45.4642, 9.1900);
          }
          if (!mounted) return;
          AddressResult? result = await showGoogleMapLocationPicker(
            pinWidget: Icon(Icons.location_pin, color: Colors.red, size: 35),
            pinColor: Colors.red,
            context: context,
            addressPlaceHolder: "Seleziona qui",
            addressTitle: "Indirizzo : ",
            apiKey: "AIzaSyAB9JpHw1iVlBH3izJJfsuPGKOqxLsXSpk",
            appBarTitle: "Indirizzo di consegna",
            confirmButtonColor: Colors.red,
            confirmButtonText: "Salva",
            confirmButtonTextColor: Colors.white,
            country: "it",
            language: MyApp2.apiLang.toString(),
            searchHint: "Cerca",
            initialLocation: myPosition,
            myLocation: myPosition,
          );
          if (result == null) return;
          setState(() {
            selectedPlace = result;
          });
          String lat = selectedPlace.latlng.latitude.toString();
          String lng = selectedPlace.latlng.longitude.toString();
          String address = selectedPlace.address;
          if (Auth2.user!.email != "info@eboro.com") {
            Auth2.editUserlocations(address, lat, lng, context);
          } else {
            Auth2.user!.address = address;
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AddAddress()),
            );
          }
        } catch (_) {}
      }
    } catch (error) {
      if (mounted) {
        try { Navigator.of(context).pop(); } catch (_) {}
      }
      Fluttertoast.showToast(
        msg: 'Errore accesso Google',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _handleAppleLogin() async {
    try {
      final isAvailable = await TheAppleSignIn.isAvailable();
      if (!isAvailable) {
        Fluttertoast.showToast(
          msg: 'Accesso con Apple non disponibile su questo dispositivo',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.grey,
        );
        return;
      }
      final AuthorizationResult result = await TheAppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName]),
      ]);

      // print('DEBUG APPLE: result.status=${result.status}');
      switch (result.status) {
        case AuthorizationStatus.authorized:
          final AppleIdCredential credential = result.credential!;
          final String? email = credential.email;
          final String fullName = "${credential.fullName?.givenName ?? ''} ${credential.fullName?.familyName ?? ''}".trim();
          final String token = utf8.decode(credential.identityToken!.toList());

          final savedEmail = email != null ? email : await loadFromStorage('apple_email');
          final savedName = fullName.isNotEmpty ? fullName : await loadFromStorage('apple_fullname');

          print('DEBUG APPLE: email=$email savedEmail=$savedEmail savedName=$savedName token=${token.substring(0, 20)}...');

          if (email != null) await saveToStorage('apple_email', email);
          if (fullName.isNotEmpty) await saveToStorage('apple_fullname', fullName);

          if (savedEmail.isEmpty) {
            // Apple non ha fornito l'email - usa il token direttamente
            // Il server può estrarre l'email dal JWT token di Apple
            if (!mounted) return;
            await Auth2.googlefacebooklogin(
              'apple_$token',
              savedName.isNotEmpty ? savedName : 'Utente Apple',
              null,
              token,
              "3",
              context,
            );
            return;
          }

          if (!mounted) return;
          await Auth2.googlefacebooklogin(
            savedEmail,
            savedName,
            null,
            token,
            "3",
            context,
          );

          if (Auth2.user != null && Auth2.user?.address == null) {
            try {
              var permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }
              if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                Fluttertoast.showToast(
                  msg: 'Location access is denied',
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: Colors.grey,
                );
                return;
              }
              if (!mounted) return;
              LatLng myPosition;
              try {
                myPosition = await _getCurrentLocation();
              } catch (_) {
                myPosition = LatLng(45.4642, 9.1900);
              }
              if (!mounted) return;
              AddressResult? locResult = await showGoogleMapLocationPicker(
                pinWidget: Icon(Icons.location_pin, color: Colors.red, size: 35),
                pinColor: Colors.red,
                context: context,
                addressPlaceHolder: "Seleziona qui",
                addressTitle: "Indirizzo : ",
                apiKey: "AIzaSyAB9JpHw1iVlBH3izJJfsuPGKOqxLsXSpk",
                appBarTitle: "Indirizzo di consegna",
                confirmButtonColor: Colors.red,
                confirmButtonText: "Salva",
                confirmButtonTextColor: Colors.white,
                country: "it",
                language: MyApp2.apiLang.toString(),
                searchHint: "Cerca",
                initialLocation: myPosition,
                myLocation: myPosition,
              );
              if (locResult == null) return;
              setState(() {
                selectedPlace = locResult;
              });
              String lat = selectedPlace.latlng.latitude.toString();
              String lng = selectedPlace.latlng.longitude.toString();
              String address = selectedPlace.address;
              if (Auth2.user!.email != "info@eboro.com") {
                Auth2.editUserlocations(address, lat, lng, context);
              } else {
                Auth2.user!.address = address;
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AddAddress()),
                );
              }
            } catch (_) {}
          }
          break;
        case AuthorizationStatus.error:
          break;
        case AuthorizationStatus.cancelled:
          break;
      }
    } catch (e) {
      // print('DEBUG APPLE ERROR: $e');
      Fluttertoast.showToast(
        msg: 'Errore accesso Apple: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
      );
    }
  }

  // ==================== HELPERS ====================

  String _composeAddressFromPlacemark(Placemark p) {
    final street = (p.street ?? '').trim();
    final houseNumber = (p.subThoroughfare ?? '').trim();
    final cap = (p.postalCode ?? '').trim();
    final city = (p.locality ?? '').trim();
    final country = (p.country ?? '').trim();

    final streetWithNumber = [street, houseNumber]
        .where((value) => value.isNotEmpty)
        .join(' ');

    return [streetWithNumber, cap, city, country]
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  void _joinAsGuest() async {
    // Clear old session data for fresh guest
    MyApp2.token = null;
    MyApp2.prefs.remove('token');
    Auth2.user = null;
    UserData.clearDeliveryAddress();

    String guestAddress = "Posizione corrente";
    String guestLat = "45.49181009999999";
    String guestLong = "9.1897173";

    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        final current = await _getCurrentLocation();
        guestLat = current.latitude.toString();
        guestLong = current.longitude.toString();

        try {
          final placemarks = await placemarkFromCoordinates(
            current.latitude,
            current.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final address = _composeAddressFromPlacemark(p).trim();
            if (address.replaceAll(',', '').trim().isNotEmpty) {
              guestAddress = address;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    Auth2.user = UserData(
      address: guestAddress,
      name: "EBORO",
      email: "info@eboro.com",
      image: "eboro/fbbba9c4d7a35e141f16a6bfdd66724ed7b620ab.jpg",
      lat: guestLat,
      long: guestLong,
      type: "0",
    );

    // Clear cart for fresh guest session
    if (mounted) {
      try {
        final cart = prov.Provider.of<CartTextProvider>(context, listen: false);
        await cart.clearCartSilent();
      } catch (_) {}
    }

    await Categories2.getGuestCategories(flag: true, context: context);
  }

  Future<LatLng> _getCurrentLocation() async {
    Position? position = await Geolocator.getLastKnownPosition();
    if (position != null && position.latitude != 0.0 && position.longitude != 0.0) {
      return LatLng(position.latitude, position.longitude);
    }
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 8),
    );
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> saveToStorage(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String> loadFromStorage(String key) async {
    return await _storage.read(key: key) ?? '';
  }

  Future<void> sendAppleSignInDetailsToServer(AppleIdCredential credential) async {
    final response = await http.post(
      Uri.parse('$globalUrl/login/apple').replace(
        queryParameters: <String, String?>{
          'code': credential.identityToken.toString(),
          if (credential.email != null) "firstname": credential.email,
          if (credential.user != null) "lastname": credential.user,
          'useBundleId': 'true',
          if (credential.state != null) 'state': credential.state,
        },
      ),
    );
    if (response.statusCode == 200) {
      Map A = json.decode(response.body);
      MyApp2.prefs.setString('firstTime', credential.user!);
      MyApp2.prefs.setBool('gof', true);
      MyApp2.token = "Bearer " + A['data']["token"];
      await Auth2.getUserDetails(context);
      await Auth2.checkType("Bearer " + A["data"]["token"], context);
    }
  }

}

