import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  bool _currentNumberIsWhatsApp = true;

  static const _black = Color(0xFF000000);
  static const _darkGrey = Color(0xFF2C2C2E);
  static const _midGrey = Color(0xFF636366);
  static const _lightGrey = Color(0xFFF2F2F7);
  static const _cardColor = Colors.white;
  static const _bg = Color(0xFFF2F2F7);
  static const _accent = Color(0xFFB71C1C);

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
    _currentNumberIsWhatsApp = wp.isNotEmpty && wp != "0";
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
          whatsapp: Auth2.user?.whatsapp ?? "",
          navigate: false,
          showProgress: false,
          popOnDone: false);

      _houseController.clear();
      _intercomController.clear();

      Progress.dimesDialog(context);

      Auth2.user?.house = "";
      Auth2.user?.intercom = "";

      if (mounted) {
        final cart =
            prov.Provider.of<CartTextProvider>(context, listen: false);
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
      final whatsapp = _currentNumberIsWhatsApp && wpNumber.isNotEmpty
          ? '$_selectedCountryCode$wpNumber'
          : '';

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
            SnackBar(
              content: const Text(
                "Compila tutti i campi obbligatori",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
              backgroundColor: _black,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(20),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Container(
                color: _cardColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    if (canGoBack)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: _black),
                        onPressed: () => Navigator.pop(context),
                      )
                    else
                      const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        'Indirizzo di consegna',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _black,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Content ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // ── Location Card ──
                        _buildCard(
                          child: GestureDetector(
                            onTap: _changeAddress,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _accent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.location_on_rounded,
                                      color: _accent, size: 20),
                                ),
                                const SizedBox(width: 14),
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
                                          color: _black,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      if (city.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3),
                                          child: Text(
                                            city,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: _midGrey),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _lightGrey,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: _midGrey,
                                      size: 13),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Building Details Card ──
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                  Icons.apartment_rounded, 'Edificio'),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildField(
                                      controller: _houseController,
                                      label: 'N\u00B0 Civico',
                                      icon: Icons.tag_rounded,
                                      required: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildField(
                                      controller: _intercomController,
                                      label: 'Citofono',
                                      icon: Icons.doorbell_outlined,
                                      required: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                controller: _noteController,
                                label: 'Note per il rider',
                                icon: Icons.edit_note_rounded,
                                hint: 'Es. Piano 3, porta a sinistra...',
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Contact Card ──
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                  Icons.phone_rounded, 'Contatti'),
                              const SizedBox(height: 16),

                              // Phone number with WhatsApp toggle
                              _buildPhoneField(),

                              const SizedBox(height: 12),

                              // WhatsApp toggle
                              GestureDetector(
                                onTap: () => setState(() =>
                                    _currentNumberIsWhatsApp =
                                        !_currentNumberIsWhatsApp),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _currentNumberIsWhatsApp
                                        ? const Color(0xFF25D366)
                                            .withOpacity(0.08)
                                        : _lightGrey,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _currentNumberIsWhatsApp
                                          ? const Color(0xFF25D366)
                                              .withOpacity(0.3)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _currentNumberIsWhatsApp
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        size: 20,
                                        color: _currentNumberIsWhatsApp
                                            ? const Color(0xFF25D366)
                                            : _midGrey,
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Questo numero ha WhatsApp',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _darkGrey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Second WhatsApp
                              if (!_showSecondWhatsApp) ...[
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _showSecondWhatsApp = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _lightGrey,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: _accent.withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.add_rounded,
                                              size: 18, color: _accent),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Aggiungi numero alternativo',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: _black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Per privacy, usa un numero diverso per la consegna',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _midGrey,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded,
                                            size: 14, color: _midGrey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              if (_showSecondWhatsApp) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Numero alternativo',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: _midGrey,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _whatsapp2Controller.clear();
                                        setState(() =>
                                            _showSecondWhatsApp = false);
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: _lightGrey,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.close_rounded,
                                            size: 14, color: _midGrey),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _whatsapp2Controller,
                                  label: '+39 3XX XXX XXXX',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Divider
                              Container(height: 0.5, color: _lightGrey),

                              const SizedBox(height: 16),

                              // Email
                              _buildField(
                                controller: _emailController,
                                label:
                                    _isEmailRequired ? 'Email *' : 'Email',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
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

                        // ── Tip Card ──
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFE082),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.lightbulb_rounded,
                                    size: 20,
                                    color: Color(0xFFF9A825)),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Suggerimento',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5D4037),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Aggiungi dettagli precisi come piano, scala e nome sul citofono per una consegna pi\u00F9 veloce.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF795548),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
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

              // ── Save Button ──
              Container(
                decoration: BoxDecoration(
                  color: _cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
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
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text(
                              "Salva indirizzo",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
      ),
    );
  }

  // ── Card wrapper ──
  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Section header ──
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _black,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── Text field ──
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
          fontSize: 15, color: _black, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 14, color: _midGrey),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: _darkGrey,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 13,
          color: _accent,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: _darkGrey)
            : null,
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
          borderSide:
              const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator ??
          (required
              ? (v) =>
                  v == null || v.trim().isEmpty ? 'Obbligatorio' : null
              : null),
    );
  }

  // ── Phone field with country picker ──
  Widget _buildPhoneField() {
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
              color: _lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selected['flag']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  selected['code']!,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _black),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: _midGrey),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildField(
            controller: _whatsappController,
            label: 'Numero di telefono',
            keyboardType: TextInputType.phone,
            required: true,
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
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
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
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Seleziona paese',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: searchController,
                          style: const TextStyle(
                              fontSize: 15, color: _black),
                          decoration: InputDecoration(
                            hintText: "Cerca paese...",
                            hintStyle:
                                const TextStyle(color: _midGrey),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: _midGrey, size: 20),
                            filled: true,
                            fillColor: _lightGrey,
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
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            child: Container(
                                height: 0.5, color: _lightGrey),
                          ),
                          itemBuilder: (ctx, i) {
                            final country = filtered[i];
                            final isSelected = country['code'] ==
                                _selectedCountryCode;
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 2),
                              leading: Text(country['flag']!,
                                  style: const TextStyle(fontSize: 22)),
                              title: Text(
                                country['name']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: _black,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    country['code']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? _accent
                                          : _midGrey,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: _accent),
                                  ],
                                ],
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
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
              ),
            );
          },
        );
      },
    );
  }
}
