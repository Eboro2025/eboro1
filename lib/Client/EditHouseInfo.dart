import 'package:flutter/material.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/main.dart';

/// صفحة لتحديث بيانات التوصيل
class EditHouseInfo extends StatefulWidget {
  const EditHouseInfo({Key? key}) : super(key: key);

  @override
  _EditHouseInfoState createState() => _EditHouseInfoState();
}

class _EditHouseInfoState extends State<EditHouseInfo> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _houseController;
  late TextEditingController _intercomController;
  late TextEditingController _whatsappController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _houseController = TextEditingController(text: Auth2.user?.house ?? "");
    _intercomController =
        TextEditingController(text: Auth2.user?.intercom ?? "");
    final wp = Auth2.user?.whatsapp ?? "";
    _whatsappController = TextEditingController(
      text: (wp.isNotEmpty && wp != "0") ? wp : "",
    );
  }

  @override
  void dispose() {
    _houseController.dispose();
    _intercomController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final house = _houseController.text.trim();
      final intercom = _intercomController.text.trim();
      final whatsapp = _whatsappController.text.trim();
      final mobile = Auth2.user?.mobile ?? "";

      if (Auth2.user == null) {
        Auth2.show("Unexpected error");
        return;
      }

      await Auth2.editUserlocationsHints(
        mobile,
        house,
        intercom,
        context,
        whatsapp: whatsapp,
        navigate: false,
      );
    } catch (e) {
      Auth2.show("Unexpected error");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Conferma indirizzo",
          style: TextStyle(
            fontSize: MyApp2.fontSize16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address header
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: myColor.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: myColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Auth2.user?.address ?? "",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // House / Address
                      _buildField(
                        controller: _houseController,
                        label: "N° civico",
                        hint: "Es. 22",
                        icon: Icons.home_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Obbligatorio";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Interfono
                      _buildField(
                        controller: _intercomController,
                        label: "Citofono",
                        hint: "Nome sul citofono",
                        icon: Icons.doorbell_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Obbligatorio";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // WhatsApp (optional)
                      _buildField(
                        controller: _whatsappController,
                        label: "WhatsApp",
                        hint: "Numero WhatsApp (opzionale)",
                        icon: Icons.chat_outlined,
                        keyboardType: TextInputType.phone,
                        isOptional: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              "Salva",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: myColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Opzionale',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: myColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
