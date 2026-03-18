import 'package:flutter/material.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/main.dart';

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

  static const _black = Color(0xFF0A0A0A);
  static const _midGrey = Color(0xFF8E8E93);
  static const _borderColor = Color(0xFFE5E5E5);

  static const List<Map<String, String>> _countryCodes = [
    {'code': '+39', 'flag': '\u{1F1EE}\u{1F1F9}', 'name': 'Italia'},
    {'code': '+1', 'flag': '\u{1F1FA}\u{1F1F8}', 'name': 'USA'},
    {'code': '+44', 'flag': '\u{1F1EC}\u{1F1E7}', 'name': 'UK'},
    {'code': '+33', 'flag': '\u{1F1EB}\u{1F1F7}', 'name': 'Francia'},
    {'code': '+49', 'flag': '\u{1F1E9}\u{1F1EA}', 'name': 'Germania'},
    {'code': '+34', 'flag': '\u{1F1EA}\u{1F1F8}', 'name': 'Spagna'},
    {'code': '+351', 'flag': '\u{1F1F5}\u{1F1F9}', 'name': 'Portogallo'},
    {'code': '+41', 'flag': '\u{1F1E8}\u{1F1ED}', 'name': 'Svizzera'},
    {'code': '+43', 'flag': '\u{1F1E6}\u{1F1F9}', 'name': 'Austria'},
    {'code': '+32', 'flag': '\u{1F1E7}\u{1F1EA}', 'name': 'Belgio'},
    {'code': '+31', 'flag': '\u{1F1F3}\u{1F1F1}', 'name': 'Paesi Bassi'},
    {'code': '+20', 'flag': '\u{1F1EA}\u{1F1EC}', 'name': 'Egitto'},
    {'code': '+212', 'flag': '\u{1F1F2}\u{1F1E6}', 'name': 'Marocco'},
    {'code': '+216', 'flag': '\u{1F1F9}\u{1F1F3}', 'name': 'Tunisia'},
    {'code': '+213', 'flag': '\u{1F1E9}\u{1F1FF}', 'name': 'Algeria'},
    {'code': '+966', 'flag': '\u{1F1F8}\u{1F1E6}', 'name': 'Arabia Saudita'},
    {'code': '+971', 'flag': '\u{1F1E6}\u{1F1EA}', 'name': 'Emirati Arabi'},
    {'code': '+962', 'flag': '\u{1F1EF}\u{1F1F4}', 'name': 'Giordania'},
    {'code': '+961', 'flag': '\u{1F1F1}\u{1F1E7}', 'name': 'Libano'},
    {'code': '+964', 'flag': '\u{1F1EE}\u{1F1F6}', 'name': 'Iraq'},
    {'code': '+92', 'flag': '\u{1F1F5}\u{1F1F0}', 'name': 'Pakistan'},
    {'code': '+880', 'flag': '\u{1F1E7}\u{1F1E9}', 'name': 'Bangladesh'},
    {'code': '+91', 'flag': '\u{1F1EE}\u{1F1F3}', 'name': 'India'},
    {'code': '+86', 'flag': '\u{1F1E8}\u{1F1F3}', 'name': 'Cina'},
    {'code': '+55', 'flag': '\u{1F1E7}\u{1F1F7}', 'name': 'Brasile'},
    {'code': '+90', 'flag': '\u{1F1F9}\u{1F1F7}', 'name': 'Turchia'},
    {'code': '+7', 'flag': '\u{1F1F7}\u{1F1FA}', 'name': 'Russia'},
    {'code': '+380', 'flag': '\u{1F1FA}\u{1F1E6}', 'name': 'Ucraina'},
    {'code': '+48', 'flag': '\u{1F1F5}\u{1F1F1}', 'name': 'Polonia'},
    {'code': '+40', 'flag': '\u{1F1F7}\u{1F1F4}', 'name': 'Romania'},
    {'code': '+234', 'flag': '\u{1F1F3}\u{1F1EC}', 'name': 'Nigeria'},
    {'code': '+63', 'flag': '\u{1F1F5}\u{1F1ED}', 'name': 'Filippine'},
    {'code': '+62', 'flag': '\u{1F1EE}\u{1F1E9}', 'name': 'Indonesia'},
  ];

  String _selectedCountryCode = '+39';

  @override
  void initState() {
    super.initState();
    _houseController = TextEditingController(text: Auth2.user?.house ?? "");
    _intercomController =
        TextEditingController(text: Auth2.user?.intercom ?? "");
    final wp = Auth2.user?.whatsapp ?? "";
    String number = (wp.isNotEmpty && wp != "0") ? wp : "";
    if (number.startsWith('+')) {
      final sorted = List<Map<String, String>>.from(_countryCodes)
        ..sort((a, b) => b['code']!.length.compareTo(a['code']!.length));
      for (final country in sorted) {
        if (number.startsWith(country['code']!)) {
          _selectedCountryCode = country['code']!;
          number = number.substring(country['code']!.length).trim();
          break;
        }
      }
    }
    _whatsappController = TextEditingController(text: number);
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
      final wpNumber = _whatsappController.text.trim();
      final whatsapp = wpNumber.isNotEmpty ? '$_selectedCountryCode$wpNumber' : '';
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _borderColor),
        ),
        title: const Text(
          "Conferma indirizzo",
          style: TextStyle(
            fontSize: 17,
            color: _black,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Address display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: _borderColor),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: _black, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  Auth2.user?.address ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Section
                        const Text(
                          'DETTAGLI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _midGrey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildMinimalField(
                          controller: _houseController,
                          label: 'N\u00B0 Civico',
                          required: true,
                        ),
                        const SizedBox(height: 14),

                        _buildMinimalField(
                          controller: _intercomController,
                          label: 'Citofono',
                          required: true,
                        ),

                        const SizedBox(height: 32),
                        Container(height: 0.5, color: _borderColor),
                        const SizedBox(height: 32),

                        // WhatsApp section
                        Row(
                          children: [
                            const Text(
                              'WHATSAPP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _midGrey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: _borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Opzionale',
                                style: TextStyle(fontSize: 10, color: _midGrey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildWhatsAppField(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Save button
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _borderColor, width: 0.5)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Salva",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
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

  Widget _buildMinimalField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: _black, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: _midGrey, fontWeight: FontWeight.w400),
        floatingLabelStyle: const TextStyle(fontSize: 13, color: _black, fontWeight: FontWeight.w500),
        filled: false,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _black, width: 1.5),
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
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Obbligatorio' : null
          : null,
    );
  }

  Widget _buildWhatsAppField() {
    final selected = _countryCodes.firstWhere(
      (c) => c['code'] == _selectedCountryCode,
      orElse: () => _countryCodes.first,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showCountryCodePicker,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selected['flag']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  selected['code']!,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _black),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: _midGrey),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMinimalField(
            controller: _whatsappController,
            label: '3XX XXX XXXX',
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }

  void _showCountryCodePicker() {
    final searchController = TextEditingController();
    List<Map<String, String>> filtered = List.from(_countryCodes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                maxChildSize: 0.9,
                minChildSize: 0.5,
                expand: false,
                builder: (ctx, scrollController) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Paese',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _black),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: searchController,
                          style: const TextStyle(fontSize: 15, color: _black),
                          decoration: InputDecoration(
                            hintText: "Cerca...",
                            hintStyle: const TextStyle(color: _midGrey),
                            prefixIcon: const Icon(Icons.search, color: _midGrey, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (query) {
                            setModalState(() {
                              filtered = _countryCodes.where((c) {
                                final q = query.toLowerCase();
                                return c['name']!.toLowerCase().contains(q) ||
                                    c['code']!.contains(q);
                              }).toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(height: 0.5, color: _borderColor),
                          ),
                          itemBuilder: (ctx, i) {
                            final country = filtered[i];
                            final isSelected = country['code'] == _selectedCountryCode;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              leading: Text(country['flag']!, style: const TextStyle(fontSize: 22)),
                              title: Text(
                                country['name']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: _black,
                                ),
                              ),
                              trailing: Text(
                                country['code']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? _black : _midGrey,
                                ),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onTap: () {
                                setState(() => _selectedCountryCode = country['code']!);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
