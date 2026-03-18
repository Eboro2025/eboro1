import 'dart:convert';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Auth/signin.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (code.isEmpty) {
      Auth2.show('Inserisci il codice di verifica');
      return;
    }
    if (password.isEmpty) {
      Auth2.show('Inserisci la nuova password');
      return;
    }
    if (password.length < 6) {
      Auth2.show('La password deve essere di almeno 6 caratteri');
      return;
    }
    if (password != confirmPassword) {
      Auth2.show('Le password non corrispondono');
      return;
    }

    setState(() => _isLoading = true);
    final String myUrl = '$globalUrl/api/resetPassword';

    try {
      final response = await http.post(
        Uri.parse(myUrl),
        headers: {
          'apiLang': MyApp2.apiLang.toString(),
          'Accept': 'application/json',
        },
        body: {
          'email': widget.email,
          'verify_code': code,
          'password': password,
          'password_confirmation': confirmPassword,
        },
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = json.decode(response.body);
        if (result['status'] == 'success') {
          _showSuccessSheet();
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
      Auth2.show('Connessione al server fallita. Controlla la connessione internet.');
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fatto!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1D35),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Password modificata con successo',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Accedi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggle,
    bool showToggle = false,
  }) {
    return Container(
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
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
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
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                    onPressed: onToggle,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
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
                        SizedBox(height: h * 0.02),

                        // Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: myColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.vpn_key_rounded,
                            size: 44,
                            color: myColor,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate('resetPassword') ??
                              'Reimposta password',
                          style: TextStyle(
                            fontSize: (MyApp2.fontSize20 ?? 20) + 4,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D1D35),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Email chip
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
                              Icon(Icons.email_outlined,
                                  size: 16, color: myColor),
                              const SizedBox(width: 6),
                              Text(
                                widget.email,
                                style: TextStyle(
                                  color: myColor,
                                  fontSize: MyApp2.fontSize14 ?? 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: h * 0.035),

                        // Fields
                        _buildField(
                          controller: _codeController,
                          hint: 'Codice di verifica',
                          icon: Icons.pin_rounded,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 14),

                        _buildField(
                          controller: _passwordController,
                          hint: 'Nuova password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          showToggle: true,
                          onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),

                        const SizedBox(height: 14),

                        _buildField(
                          controller: _confirmPasswordController,
                          hint: 'Conferma password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureConfirmPassword,
                          showToggle: true,
                          onToggle: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),

                        const SizedBox(height: 28),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : resetPassword,
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
                                        'Conferma modifica',
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
