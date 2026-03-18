import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/main.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:http/http.dart' as http;

/// Quick registration page for guest users.
/// Collects name + phone, creates account, logs in, then pops back.
class QuickRegister extends StatefulWidget {
  const QuickRegister({Key? key}) : super(key: key);

  @override
  State<QuickRegister> createState() => _QuickRegisterState();
}

class _QuickRegisterState extends State<QuickRegister> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;
  bool _obscurePassword = true;

  static const _black = Color(0xFF000000);
  static const _darkGrey = Color(0xFF2C2C2E);
  static const _midGrey = Color(0xFF636366);
  static const _lightGrey = Color(0xFFF2F2F7);
  static const _bg = Color(0xFFF2F2F7);
  static const _accent = Color(0xFFB71C1C);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final address = Auth2.user?.activeAddress ?? Auth2.user?.address ?? "Posizione corrente";
      final lat = Auth2.user?.activeLat ?? Auth2.user?.lat ?? "";
      final lng = Auth2.user?.activeLong ?? Auth2.user?.long ?? "";

      // 1. Register
      final regUrl = '$globalUrl/api/register';
      final regResponse = await http.post(
        Uri.parse(regUrl),
        headers: {'apiLang': MyApp2.apiLang ?? 'it'},
        body: {
          'name': name,
          'email': email,
          'mobile': phone,
          'password': password,
          'password_confirmation': password,
          'address': address,
          'base64Image': '',
          'fileNames': '',
          'type': '0',
          'flag': 'json',
          'lat': lat,
          'long': lng,
        },
      );

      if (regResponse.statusCode != 200 && regResponse.statusCode != 201) {
        final body = json.decode(regResponse.body);
        final errors = body['errors'];
        if (errors is Map) {
          final msgs = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              for (final msg in value) {
                String clean = msg.toString();
                if (clean.contains('già stato preso') || clean.contains('already been taken')) {
                  if (key == 'email') clean = 'Questa email è già registrata.';
                  if (key == 'mobile') clean = 'Questo numero è già registrato.';
                }
                msgs.add(clean);
              }
            }
          });
          Auth2.show(msgs.join('\n'));
        } else {
          Auth2.show(body['message'] ?? 'Errore nella registrazione');
        }
        return;
      }

      // 2. Login automatically
      if (!mounted) return;
      Progress.progressDialogue(context);

      final loginUrl = '$globalUrl/api/login';
      final loginResponse = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'apiLang': MyApp2.apiLang ?? 'it',
          'Accept': 'application/json',
        },
        body: {
          'email': email,
          'password': password,
        },
      );

      if (!mounted) return;
      Progress.dimesDialog(context);

      if (loginResponse.statusCode == 200 || loginResponse.statusCode == 201) {
        final data = json.decode(loginResponse.body);
        if (data['data'] != null && data['data']['token'] != null) {
          MyApp2.token = "Bearer ${data['data']['token']}";
          MyApp2.prefs.setString('token', MyApp2.token!);
          MyApp2.prefs.setString('firstTime', 'firstTime');

          await Auth2.getUserDetails(context);

          if (mounted) {
            Navigator.pop(context, true); // Return true = registered successfully
          }
          return;
        }
      }

      // Fallback: registration ok but login failed
      Auth2.show('Account creato! Accedi con email e password.');
      if (mounted) Navigator.pop(context, false);
    } catch (e) {
      Auth2.show('Errore di connessione. Riprova.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _black),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  const Expanded(
                    child: Text(
                      'Registrazione rapida',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.person_add_rounded, size: 36, color: _accent),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Crea il tuo account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Per completare l\'ordine, registrati con i tuoi dati',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _midGrey,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Form card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildField(
                              controller: _nameController,
                              label: 'Nome completo',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Inserisci il tuo nome'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _phoneController,
                              label: 'Numero di telefono',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Inserisci il numero';
                                if (v.trim().length < 6) return 'Numero non valido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Inserisci la tua email';
                                if (!v.contains('@') || !v.contains('.')) return 'Email non valida';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 15, color: _black, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(fontSize: 14, color: _darkGrey, fontWeight: FontWeight.w500),
                                floatingLabelStyle: const TextStyle(fontSize: 13, color: _accent, fontWeight: FontWeight.w600),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: _darkGrey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: _midGrey,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: _lightGrey,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _accent, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFDC2626)),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Inserisci una password';
                                if (v.length < 6) return 'Minimo 6 caratteri';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info text
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF2E7D32)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'La registrazione è veloce e ti permette di tracciare i tuoi ordini.',
                                style: TextStyle(fontSize: 13, color: Color(0xFF1B5E20), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),

            // Register button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSaving ? null : _register,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Registrati e ordina',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: _black, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: _darkGrey, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(fontSize: 13, color: _accent, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, size: 18, color: _darkGrey),
        filled: true,
        fillColor: _lightGrey,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}
