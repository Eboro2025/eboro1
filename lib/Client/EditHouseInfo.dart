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

  static const List<Map<String, String>> _countryCodes = [
    {'code': '+39', 'flag': '🇮🇹', 'name': 'Italia'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'Francia'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Germania'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'Spagna'},
    {'code': '+351', 'flag': '🇵🇹', 'name': 'Portogallo'},
    {'code': '+41', 'flag': '🇨🇭', 'name': 'Svizzera'},
    {'code': '+43', 'flag': '🇦🇹', 'name': 'Austria'},
    {'code': '+32', 'flag': '🇧🇪', 'name': 'Belgio'},
    {'code': '+31', 'flag': '🇳🇱', 'name': 'Paesi Bassi'},
    {'code': '+46', 'flag': '🇸🇪', 'name': 'Svezia'},
    {'code': '+47', 'flag': '🇳🇴', 'name': 'Norvegia'},
    {'code': '+45', 'flag': '🇩🇰', 'name': 'Danimarca'},
    {'code': '+48', 'flag': '🇵🇱', 'name': 'Polonia'},
    {'code': '+40', 'flag': '🇷🇴', 'name': 'Romania'},
    {'code': '+30', 'flag': '🇬🇷', 'name': 'Grecia'},
    {'code': '+90', 'flag': '🇹🇷', 'name': 'Turchia'},
    {'code': '+7', 'flag': '🇷🇺', 'name': 'Russia'},
    {'code': '+380', 'flag': '🇺🇦', 'name': 'Ucraina'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'Cina'},
    {'code': '+81', 'flag': '🇯🇵', 'name': 'Giappone'},
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brasile'},
    {'code': '+54', 'flag': '🇦🇷', 'name': 'Argentina'},
    {'code': '+52', 'flag': '🇲🇽', 'name': 'Messico'},
    {'code': '+20', 'flag': '🇪🇬', 'name': 'Egitto'},
    {'code': '+212', 'flag': '🇲🇦', 'name': 'Marocco'},
    {'code': '+216', 'flag': '🇹🇳', 'name': 'Tunisia'},
    {'code': '+213', 'flag': '🇩🇿', 'name': 'Algeria'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
    {'code': '+27', 'flag': '🇿🇦', 'name': 'Sudafrica'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Arabia Saudita'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'Emirati Arabi'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'Giordania'},
    {'code': '+961', 'flag': '🇱🇧', 'name': 'Libano'},
    {'code': '+964', 'flag': '🇮🇶', 'name': 'Iraq'},
    {'code': '+98', 'flag': '🇮🇷', 'name': 'Iran'},
    {'code': '+92', 'flag': '🇵🇰', 'name': 'Pakistan'},
    {'code': '+880', 'flag': '🇧🇩', 'name': 'Bangladesh'},
    {'code': '+94', 'flag': '🇱🇰', 'name': 'Sri Lanka'},
    {'code': '+63', 'flag': '🇵🇭', 'name': 'Filippine'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
    {'code': '+64', 'flag': '🇳🇿', 'name': 'Nuova Zelanda'},
    {'code': '+82', 'flag': '🇰🇷', 'name': 'Corea del Sud'},
    {'code': '+60', 'flag': '🇲🇾', 'name': 'Malesia'},
    {'code': '+65', 'flag': '🇸🇬', 'name': 'Singapore'},
    {'code': '+66', 'flag': '🇹🇭', 'name': 'Thailandia'},
    {'code': '+84', 'flag': '🇻🇳', 'name': 'Vietnam'},
    {'code': '+62', 'flag': '🇮🇩', 'name': 'Indonesia'},
    {'code': '+353', 'flag': '🇮🇪', 'name': 'Irlanda'},
    {'code': '+358', 'flag': '🇫🇮', 'name': 'Finlandia'},
    {'code': '+36', 'flag': '🇭🇺', 'name': 'Ungheria'},
    {'code': '+420', 'flag': '🇨🇿', 'name': 'Rep. Ceca'},
    {'code': '+421', 'flag': '🇸🇰', 'name': 'Slovacchia'},
    {'code': '+385', 'flag': '🇭🇷', 'name': 'Croazia'},
    {'code': '+386', 'flag': '🇸🇮', 'name': 'Slovenia'},
    {'code': '+381', 'flag': '🇷🇸', 'name': 'Serbia'},
    {'code': '+359', 'flag': '🇧🇬', 'name': 'Bulgaria'},
    {'code': '+370', 'flag': '🇱🇹', 'name': 'Lituania'},
    {'code': '+371', 'flag': '🇱🇻', 'name': 'Lettonia'},
    {'code': '+372', 'flag': '🇪🇪', 'name': 'Estonia'},
    {'code': '+56', 'flag': '🇨🇱', 'name': 'Cile'},
    {'code': '+57', 'flag': '🇨🇴', 'name': 'Colombia'},
    {'code': '+51', 'flag': '🇵🇪', 'name': 'Perù'},
    {'code': '+58', 'flag': '🇻🇪', 'name': 'Venezuela'},
    {'code': '+593', 'flag': '🇪🇨', 'name': 'Ecuador'},
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+255', 'flag': '🇹🇿', 'name': 'Tanzania'},
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+251', 'flag': '🇪🇹', 'name': 'Etiopia'},
    {'code': '+256', 'flag': '🇺🇬', 'name': 'Uganda'},
  ];

  String _selectedCountryCode = '+39';

  @override
  void initState() {
    super.initState();
    _houseController = TextEditingController(text: Auth2.user?.house ?? "");
    _intercomController =
        TextEditingController(text: Auth2.user?.intercom ?? "");
    final wp = Auth2.user?.whatsapp ?? "";
    // Parse existing whatsapp to extract country code and number
    String number = (wp.isNotEmpty && wp != "0") ? wp : "";
    if (number.startsWith('+')) {
      for (final country in _countryCodes) {
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
                      _buildWhatsAppField(),
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

  Widget _buildWhatsAppField() {
    final selected = _countryCodes.firstWhere(
      (c) => c['code'] == _selectedCountryCode,
      orElse: () => _countryCodes.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_outlined, size: 18, color: myColor),
            const SizedBox(width: 6),
            Text(
              "WhatsApp",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
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
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code dropdown
            GestureDetector(
              onTap: () => _showCountryCodePicker(),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selected['flag']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selected['code']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down,
                        size: 18, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Phone number field
            Expanded(
              child: TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "3XX XXX XXXX",
                  hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 14),
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),
            ),
          ],
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Cerca paese...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (query) {
                          setModalState(() {
                            filtered = _countryCodes.where((c) {
                              final q = query.toLowerCase();
                              return c['name']!
                                      .toLowerCase()
                                      .contains(q) ||
                                  c['code']!.contains(q);
                            }).toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final country = filtered[i];
                          final isSelected =
                              country['code'] == _selectedCountryCode;
                          return ListTile(
                            leading: Text(
                              country['flag']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(country['name']!),
                            trailing: Text(
                              country['code']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? myColor
                                    : Colors.grey[600],
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor:
                                myColor.withValues(alpha: 0.05),
                            onTap: () {
                              setState(() {
                                _selectedCountryCode =
                                    country['code']!;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
