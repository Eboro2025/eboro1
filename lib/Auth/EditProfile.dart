import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:eboro/package/intl_phone_field/intl_phone_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditProfile extends StatefulWidget {
  @override
  Edit createState() => Edit();
}

class Edit extends State<EditProfile> {
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _emailController = new TextEditingController();
  TextEditingController _phoneController = new TextEditingController();
  TextEditingController _addressController = new TextEditingController();
  TextEditingController _codiceFiscaleController = new TextEditingController();

  Future<File?>? fileT;
  String? base64Image;
  String? fileNames;
  File? tmpFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await Auth2.getUserDetails(context);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _nameController.text = Auth2.user?.name ?? '';
        _emailController.text = Auth2.user?.email ?? '';
        _phoneController.text = Auth2.user?.mobile ?? '';
        _addressController.text = Auth2.user?.address ?? '';
        _codiceFiscaleController.text = Auth2.user?.codice_fiscale ?? '';
        _isLoading = false;
      });
    }
  }

  Future<File?> chooseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxHeight: 250,
        maxWidth: 250);
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  Widget showImage() {
    return FutureBuilder<File?>(
      future: fileT,
      builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          tmpFile = snapshot.data;
          base64Image =
              base64Encode(snapshot.data!.readAsBytesSync());
          fileNames = snapshot.data!.path.split("/").last;
          return CircleAvatar(
            child: CircleAvatar(
                radius: MyApp2.W! * .145,
                backgroundImage: FileImage(File(snapshot.data!.path)),
                child: Container(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    height: MyApp2.W! * .08,
                    width: MyApp2.W! * .08,
                    decoration: BoxDecoration(
                      color: myColor,
                      borderRadius: BorderRadius.all(Radius.circular(200.0)),
                    ),
                    child: GestureDetector(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: MyApp2.W! * .05,
                      ),
                      onTap: () {
                        setState(() {
                          fileT = chooseImage();
                        });
                      },
                    ),
                  ),
                )),
            radius: MyApp2.W! * .145,
            backgroundColor: myColor,
          );
        } else if (null != snapshot.error) {
          return const Text(
            'Error Picking Image',
            textAlign: TextAlign.center,
          );
        } else {
          return CircleAvatar(
            child: CircleAvatar(
                radius: MyApp2.W! * .145,
                backgroundImage: (Auth2.user?.image != null &&
                        Auth2.user!.image!.isNotEmpty &&
                        Auth2.user!.image!.trim().isNotEmpty)
                    ? CachedNetworkImageProvider(Auth2.user!.image!)
                    : null,
                child: Container(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    height: MyApp2.W! * .08,
                    width: MyApp2.W! * .08,
                    decoration: BoxDecoration(
                      color: myColor,
                      borderRadius: BorderRadius.all(Radius.circular(200.0)),
                    ),
                    child: GestureDetector(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: MyApp2.W! * .05,
                      ),
                      onTap: () {
                        setState(() {
                          fileT = chooseImage();
                        });
                      },
                    ),
                  ),
                )),
            radius: MyApp2.W! * .145,
            backgroundColor: myColor,
          );
        }
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: myColor, size: 20),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        filled: true,
        fillColor: Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: myColor, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cambia Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: myColor)),
            SizedBox(height: 20),
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate("oldpassword"),
                prefixIcon: Icon(Icons.lock_outline, color: myColor, size: 20),
                filled: true, fillColor: Color(0xFFF9F9F9),
                border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(14)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate("newpassword"),
                prefixIcon: Icon(Icons.lock_reset, color: myColor, size: 20),
                filled: true, fillColor: Color(0xFFF9F9F9),
                border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(14)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate("confirmpassword"),
                prefixIcon: Icon(Icons.lock_reset, color: myColor, size: 20),
                filled: true, fillColor: Color(0xFFF9F9F9),
                border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(14)),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () async {
                  if (oldPass.text.isEmpty || newPass.text.isEmpty) {
                    Auth2.show('Compila tutti i campi');
                    return;
                  }
                  Navigator.pop(ctx);
                  await Auth2.changePassword(
                    oldPass.text, newPass.text, confirmPass.text, context);
                },
                child: Text('Salva', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        title: Text(
            AppLocalizations.of(context)!.translate("editmyprofile"),
            style: TextStyle(color: Colors.white, fontSize: MyApp2.H! * .025)),
        iconTheme: new IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: 20),
              // Profile Image
              CircleAvatar(
                child: CircleAvatar(
                  radius: MyApp2.W! * 0.145,
                  child: showImage(),
                  backgroundColor: Colors.white,
                ),
                radius: MyApp2.W! * .15,
                backgroundColor: myColor,
              ),
              SizedBox(height: 24),

              // Name
              _buildField(
                controller: _nameController,
                label: AppLocalizations.of(context)!.translate("name"),
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),
              SizedBox(height: 12),

              // Email
              _buildField(
                controller: _emailController,
                label: AppLocalizations.of(context)!.translate("email"),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12),

              // Phone
              IntlPhoneField(
                disableLengthCheck: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate("mobilenumber"),
                  labelStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: myColor, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                initialCountryCode: 'IT',
                languageCode: "it",
                initialValue: _phoneController.text,
                onChanged: (phone) {
                  _phoneController.text = phone.completeNumber;
                },
              ),
              SizedBox(height: 2),

              // Address
              _buildField(
                controller: _addressController,
                label: AppLocalizations.of(context)!.translate("address"),
                icon: Icons.location_on_outlined,
                keyboardType: TextInputType.streetAddress,
              ),
              SizedBox(height: 12),

              // Codice Fiscale
              TextField(
                controller: _codiceFiscaleController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 16,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  labelText: 'Codice Fiscale',
                  labelStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  hintText: 'RSSMRA85M01H501Z',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFFCCCCCC), letterSpacing: 1.2),
                  counterText: '',
                  prefixIcon: Icon(Icons.badge_outlined, color: myColor, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  filled: true,
                  fillColor: Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: myColor, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Change Password Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.lock_outline, size: 20, color: myColor),
                  label: Text(
                    'Cambia Password',
                    style: TextStyle(fontSize: 15, color: myColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                    backgroundColor: Color(0xFFF9F9F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _showChangePasswordSheet(context),
                ),
              ),

              SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: myColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // Geocode address if it changed
                    String? lat;
                    String? lng;
                    if (_addressController.text != (Auth2.user?.address ?? '')) {
                      try {
                        final query = Uri.encodeComponent(_addressController.text);
                        final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';
                        final response = await http.get(
                          Uri.parse(url),
                          headers: {'User-Agent': 'Eboro/1.0'},
                        ).timeout(const Duration(seconds: 5));
                        if (response.statusCode == 200) {
                          final results = json.decode(response.body);
                          if (results.isNotEmpty) {
                            lat = results[0]['lat'];
                            lng = results[0]['lon'];
                          }
                        }
                      } catch (_) {}
                    }

                    await Auth2.editUserDetails(
                        _nameController.text,
                        _emailController.text,
                        _phoneController.text,
                        _addressController.text,
                        base64Image,
                        fileNames,
                        null,
                        null,
                        null,
                        context,
                        codiceFiscale: _codiceFiscaleController.text.trim().isNotEmpty
                            ? _codiceFiscaleController.text.trim().toUpperCase()
                            : null);
                    // Update lat/long locally after save
                    if (lat != null && lng != null) {
                      Auth2.user?.lat = lat;
                      Auth2.user?.long = lng;
                    }
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.translate("save"),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
