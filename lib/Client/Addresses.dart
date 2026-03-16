import 'package:flutter/material.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/UserData.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:eboro/Widget/Progress.dart';
import 'package:eboro/package/lib/google_map_location_picker_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart' as prov;

class AddAddress extends StatefulWidget {
  final bool goToHomeAfterSave;
  final bool returnToAllProviders;
  final bool popAfterSave;

  const AddAddress({
    Key? key,
    this.goToHomeAfterSave = false,
    this.returnToAllProviders = false,
    this.popAfterSave = false,
  }) : super(key: key);

  @override
  _AddAddressState createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _houseController;
  late TextEditingController _intercomController;
  late TextEditingController _whatsappController;
  late TextEditingController _whatsapp2Controller;
  late TextEditingController _noteController;
  late TextEditingController _emailController;
  bool _isSaving = false;
  bool _showSecondWhatsApp = false;

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

  bool get _isEmailRequired =>
      Auth2.user?.email == null || Auth2.user!.email!.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _houseController = TextEditingController(text: Auth2.user?.house ?? "");
    _intercomController =
        TextEditingController(text: Auth2.user?.intercom ?? "");
    final wp = Auth2.user?.whatsapp ?? "";
    final phone = Auth2.user?.mobile ?? "";
    String number = (wp.isNotEmpty && wp != "0") ? wp : phone;
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
    _whatsapp2Controller = TextEditingController();
    _noteController = TextEditingController();
    _emailController = TextEditingController(text: Auth2.user?.email ?? "");
  }

  @override
  void dispose() {
    _houseController.dispose();
    _intercomController.dispose();
    _whatsappController.dispose();
    _whatsapp2Controller.dispose();
    _noteController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _changeAddress() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position == null ||
          (position.latitude == 0.0 && position.longitude == 0.0)) {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8));
      }
      LatLng myPosition = LatLng(position.latitude, position.longitude);
      LatLng userPosition = LatLng(
        double.tryParse(Auth2.user?.activeLat ?? '') ?? position.latitude,
        double.tryParse(Auth2.user?.activeLong ?? '') ?? position.longitude,
      );

      AddressResult? result = await showGoogleMapLocationPicker(
        pinWidget: Icon(Icons.location_pin, color: Colors.red, size: 35),
        pinColor: Colors.red,
        context: context,
        addressPlaceHolder:
            "${AppLocalizations.of(context)!.translate("selecthere")}",
        addressTitle:
            "${AppLocalizations.of(context)!.translate("address")} : ",
        apiKey: "AIzaSyAB9JpHw1iVlBH3izJJfsuPGKOqxLsXSpk",
        appBarTitle:
            "${AppLocalizations.of(context)!.translate("shippingaddress")}",
        confirmButtonColor: Colors.red,
        confirmButtonText:
            "${AppLocalizations.of(context)!.translate("save")}",
        confirmButtonTextColor: Colors.white,
        country: "it",
        language: "${MyApp2.apiLang.toString()}",
        searchHint: "${AppLocalizations.of(context)!.translate("search")}",
        initialLocation: userPosition,
        myLocation: myPosition,
      );

      if (result == null) return;

      String lat = result.latlng.latitude.toString();
      String lng = result.latlng.longitude.toString();
      String address = result.address;

      Progress.progressDialogue(context);

      await Auth2.editUserlocations(address, lat, lng, context,
          navigate: false, showProgress: false);

      final mobile = Auth2.user?.mobile ?? "";
      await Auth2.editUserlocationsHints(mobile, "", "", context,
          whatsapp: Auth2.user?.whatsapp ?? "", navigate: false,
          showProgress: false, popOnDone: false);

      _houseController.clear();
      _intercomController.clear();

      Progress.dimesDialog(context);

      Auth2.user?.house = "";
      Auth2.user?.intercom = "";

      if (mounted) {
        final cart = prov.Provider.of<CartTextProvider>(context, listen: false);
        await cart.clearCartSilent();
      }

      Provider2.clearProvidersCache();
      if (mounted) {
        final newAddress = address;
        final newLat = lat;
        final newLng = lng;

        await Auth2.getUserDetails(context);

        Auth2.user?.address = newAddress;
        Auth2.user?.lat = newLat;
        Auth2.user?.long = newLng;
        UserData.deliveryAddress = newAddress;
        UserData.deliveryLat = newLat;
        UserData.deliveryLong = newLng;
        UserData.saveDeliveryAddress();
        Auth2.user?.house = "";
        Auth2.user?.intercom = "";
        final providerController =
            prov.Provider.of<ProviderController>(context, listen: false);
        providerController.updateProvider(null, force: true);
        setState(() {});
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Location access is denied',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.grey,
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final mobile = Auth2.user?.mobile ?? "";
      final house = _houseController.text.trim();
      final intercom = _intercomController.text.trim();
      final wpNumber = _whatsappController.text.trim();
      final whatsapp =
          wpNumber.isNotEmpty ? '$_selectedCountryCode$wpNumber' : '';

      if (Auth2.user == null) {
        Auth2.show("Errore imprevisto");
        return;
      }

      final whatsapp2 = _whatsapp2Controller.text.trim();
      final email = _emailController.text.trim();
      final note = _noteController.text.trim();

      await Auth2.editUserlocationsHints(
        mobile,
        house,
        intercom,
        context,
        whatsapp: whatsapp,
        whatsapp2: whatsapp2,
        email: email,
        note: note,
        navigate: !widget.popAfterSave,
      );
    } catch (e) {
      Auth2.show("Errore imprevisto");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _extractStreet(String fullAddress) {
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()} ${parts[1].trim()}'.trim();
    }
    return fullAddress;
  }

  String _extractCity(String fullAddress) {
    final parts = fullAddress.split(',');
    if (parts.length >= 3) {
      return parts.sublist(2).map((e) => e.trim()).join(', ');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final houseOk = _houseController.text.trim().isNotEmpty;
    final intercomOk = _intercomController.text.trim().isNotEmpty;
    final emailOk =
        !_isEmailRequired || _emailController.text.trim().isNotEmpty;
    final canGoBack = houseOk && intercomOk && emailOk;

    final fullAddress = Auth2.user?.activeAddress ?? '';
    final street = _extractStreet(fullAddress);
    final city = _extractCity(fullAddress);

    return PopScope(
      canPop: canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("Compila tutti i campi obbligatori per continuare"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    if (canGoBack)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 22),
                        onPressed: () => Navigator.pop(context),
                      )
                    else
                      const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        'Dettagli indirizzo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E3333),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address header
                        GestureDetector(
                          onTap: _changeAddress,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    color: myColor, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        street.isNotEmpty
                                            ? street
                                            : 'Seleziona indirizzo',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2E3333),
                                        ),
                                      ),
                                      if (city.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            city,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey.shade400, size: 22),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Form fields
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // N° Civico + Citofono in a row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _label('N\u00B0 Civico'),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _houseController,
                                          style: const TextStyle(fontSize: 15),
                                          decoration: _fieldDecor(
                                              'Es. 7, Scala A'),
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Obbligatorio'
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _label('Citofono'),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _intercomController,
                                          style: const TextStyle(fontSize: 15),
                                          decoration:
                                              _fieldDecor('Nome citofono'),
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Obbligatorio'
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Note
                              _label('Informazioni aggiuntive'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _noteController,
                                style: const TextStyle(fontSize: 15),
                                maxLines: 2,
                                decoration: _fieldDecor(
                                    'Es. Piano 3, porta a sinistra...'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // WhatsApp + Email
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('WhatsApp'),
                              const SizedBox(height: 6),
                              _buildWhatsAppField(),

                              // Add another WhatsApp number
                              if (!_showSecondWhatsApp)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _showSecondWhatsApp = true),
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_circle_outline, size: 18, color: myColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Aggiungi un altro numero',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: myColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (_showSecondWhatsApp) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _label('Secondo numero WhatsApp')),
                                    GestureDetector(
                                      onTap: () {
                                        _whatsapp2Controller.clear();
                                        setState(() => _showSecondWhatsApp = false);
                                      },
                                      child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _whatsapp2Controller,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: _fieldDecor('+39 3XX XXX XXXX'),
                                ),
                              ],

                              const SizedBox(height: 16),

                              _label(_isEmailRequired
                                  ? 'Email *'
                                  : 'Email'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(fontSize: 15),
                                decoration:
                                    _fieldDecor('Es. nome@email.com'),
                                validator: (value) {
                                  if (_isEmailRequired) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return "L'email \u00E8 obbligatoria";
                                    }
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return "Inserisci un'email valida";
                                    }
                                  } else if (value != null &&
                                      value.trim().isNotEmpty) {
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return "Inserisci un'email valida";
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Save button - fixed at bottom
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        : const Text(
                            "Salva l'indirizzo",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
  }

  InputDecoration _fieldDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: myColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selected['flag']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  selected['code']!,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.arrow_drop_down,
                    size: 18, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: _fieldDecor('3XX XXX XXXX'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Cerca paese...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
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
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final country = filtered[i];
                          final isSelected =
                              country['code'] == _selectedCountryCode;
                          return ListTile(
                            leading: Text(country['flag']!,
                                style: const TextStyle(fontSize: 22)),
                            title: Text(country['name']!),
                            trailing: Text(
                              country['code']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected ? myColor : Colors.grey.shade600,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: myColor.withValues(alpha: 0.05),
                            onTap: () {
                              setState(() {
                                _selectedCountryCode = country['code']!;
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
}
