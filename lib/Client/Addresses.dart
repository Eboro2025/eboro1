import 'package:flutter/material.dart';
import 'package:eboro/API/Auth.dart';
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
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _houseController = TextEditingController(text: Auth2.user?.house ?? "");
    _intercomController =
        TextEditingController(text: Auth2.user?.intercom ?? "");
    // WhatsApp: show existing whatsapp number, or phone number as default
    final wp = Auth2.user?.whatsapp ?? "";
    final phone = Auth2.user?.mobile ?? "";
    _whatsappController = TextEditingController(
        text: (wp.isNotEmpty && wp != "0") ? wp : phone);
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _houseController.dispose();
    _intercomController.dispose();
    _whatsappController.dispose();
    _noteController.dispose();
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

      print('DEBUG _changeAddress: START');

      Progress.progressDialogue(context);

      print('DEBUG _changeAddress: calling editUserlocations');
      await Auth2.editUserlocations(address, lat, lng, context,
          navigate: false, showProgress: false);
      print('DEBUG _changeAddress: editUserlocations DONE');

      // Clear house and intercom on server when address changes
      final mobile = Auth2.user?.mobile ?? "";
      print('DEBUG _changeAddress: calling editUserlocationsHints with mobile=$mobile');
      await Auth2.editUserlocationsHints(mobile, "", "", context,
          whatsapp: Auth2.user?.whatsapp ?? "", navigate: false,
          showProgress: false, popOnDone: false);
      print('DEBUG _changeAddress: editUserlocationsHints DONE');

      // Clear local fields
      _houseController.clear();
      _intercomController.clear();

      Progress.dimesDialog(context);

      // Force clear local user data
      Auth2.user?.house = "";
      Auth2.user?.intercom = "";
      print('DEBUG _changeAddress: cleared house and intercom locally');

      // Clear cart when address changes
      if (mounted) {
        final cart = prov.Provider.of<CartTextProvider>(context, listen: false);
        print('DEBUG _changeAddress: cart items=${cart.cart?.cart_items?.length ?? 0}');
        try {
          await cart.clearCart(context);
          print('DEBUG _changeAddress: clearCart DONE');
        } catch (e) {
          print('DEBUG _changeAddress: clearCart ERROR: $e');
        }
      } else {
        print('DEBUG _changeAddress: NOT mounted, skipping cart clear');
      }

      Provider2.clearProvidersCache();
      if (mounted) {
        await Auth2.getUserDetails(context);
        print('DEBUG _changeAddress: after getUserDetails, re-clearing');
        // Re-clear after getUserDetails in case server still has old values
        Auth2.user?.house = "";
        Auth2.user?.intercom = "";
        final providerController =
            prov.Provider.of<ProviderController>(context, listen: false);
        providerController.updateProvider(null, force: true);
        setState(() {});
        print('DEBUG _changeAddress: COMPLETE');
      } else {
        print('DEBUG _changeAddress: NOT mounted after getUserDetails');
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
      final whatsapp = _whatsappController.text.trim();

      if (Auth2.user == null) {
        Auth2.show("Errore imprevisto");
        return;
      }

      await Auth2.editUserlocationsHints(
        mobile,
        house,
        intercom,
        context,
        whatsapp: whatsapp,
        navigate: !widget.popAfterSave,
      );
    } catch (e) {
      Auth2.show("Errore imprevisto");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(icon, color: myColor, size: 20),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: myColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final houseOk = _houseController.text.trim().isNotEmpty;
    final intercomOk = _intercomController.text.trim().isNotEmpty;
    final canGoBack = houseOk && intercomOk;

    final hasAddress = Auth2.user?.activeAddress != null &&
        Auth2.user!.activeAddress!.isNotEmpty;

    return PopScope(
      canPop: canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Compila N° civico e citofono per continuare"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: myColor,
          centerTitle: true,
          elevation: 0,
          title: const Text(
            'Conferma indirizzo',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          automaticallyImplyLeading: canGoBack,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address card
                  GestureDetector(
                    onTap: _changeAddress,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: myColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.location_on, color: myColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Indirizzo di consegna',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasAddress
                                      ? Auth2.user!.activeAddress!
                                      : 'Seleziona indirizzo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: hasAddress ? Colors.black87 : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // N° Civico
                  _buildLabel('N° Civico', required: true),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _houseController,
                    keyboardType: TextInputType.text,
                    decoration: _inputDecoration(
                      hint: 'Es. 7, Scala A, Piano 3',
                      icon: Icons.home_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Il numero civico è obbligatorio';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Citofono
                  _buildLabel('Citofono', required: true),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _intercomController,
                    keyboardType: TextInputType.text,
                    decoration: _inputDecoration(
                      hint: 'Nome sul citofono',
                      icon: Icons.doorbell_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Il citofono è obbligatorio';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // WhatsApp (opzionale)
                  _buildLabel('WhatsApp', required: false),
                  const SizedBox(height: 4),
                  Text(
                    'Il tuo numero registrato. Cambia se vuoi usare un altro numero.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      hint: '+39 3XX XXX XXXX',
                      icon: Icons.chat_outlined,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nota
                  _buildLabel('Nota', required: false),
                  const SizedBox(height: 4),
                  Text(
                    'Aggiungi dettagli per aiutare il rider a trovarti',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      hint: 'Es. Scala B, piano 3, porta a sinistra...',
                      icon: Icons.note_outlined,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Save button
                  SizedBox(
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
                          : const Text(
                              'Salva',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {required bool required}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ],
    );
  }
}
