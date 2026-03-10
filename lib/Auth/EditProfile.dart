import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Client/Home.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:eboro/package/intl_phone_field/intl_phone_field.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  TextEditingController _oldPasswordController = new TextEditingController();
  TextEditingController _newPasswordController = new TextEditingController();
  TextEditingController _confirmNewPasswordController =
      new TextEditingController();
  TextEditingController _addressController = new TextEditingController();

  bool _obscureText = false;
  bool _obscureText2 = false;

  Future<File?>? fileT;
  String? base64Image;
  String? fileNames;
  File? tmpFile;

  @override
  void initState() {
    // TODO: implement initState
    _nameController.text = Auth2.user!.name!;
    _emailController.text = Auth2.user!.email!;
    _phoneController.text = Auth2.user!.mobile!;
    _addressController.text = Auth2.user!.address!;
    _toggle();
    _toggle2();
    super.initState();
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _toggle2() {
    setState(() {
      _obscureText2 = !_obscureText2;
    });
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
                backgroundImage: (Auth2.user!.image != null &&
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        title: Text(
            AppLocalizations.of(context)!.translate("editmyprofile") + "s",
            style: TextStyle(color: Colors.white, fontSize: MyApp2.H! * .03)),
        iconTheme: new IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.only(left: 30, right: 30, top: 0, bottom: 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(height: MyApp2.W! * .045),
                  Container(
                    child: CircleAvatar(
                      child: CircleAvatar(
                        radius: MyApp2.W! * 0.145,
                        child: Container(
                          child: showImage(),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      radius: MyApp2.W! * .15,
                      backgroundColor: myColor,
                    ),
                  ),
                  SizedBox(
                    height: MyApp2.W! * .05,
                  ),
                  Container(
                    child: TextField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      style: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Colors.grey,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.translate("name"),
                        hintStyle: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: Colors.grey,
                        ),
                        contentPadding: new EdgeInsets.symmetric(
                            vertical: MyApp2.W! * .025,
                            horizontal: MyApp2.W! * .025),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MyApp2.W! * .025,
                  ),
                  Container(
                    child: TextFormField(
                      controller: _emailController,
                      style: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Colors.grey,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.translate("email"),
                        hintStyle: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: Colors.grey,
                        ),
                        contentPadding: new EdgeInsets.symmetric(
                            vertical: MyApp2.W! * .025,
                            horizontal: MyApp2.W! * .025),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MyApp2.W! * .025,
                  ),
                  IntlPhoneField(
                    disableLengthCheck: true,
                    decoration: InputDecoration(
                      // counterText: '',
                      labelText: AppLocalizations.of(context)!
                          .translate("mobilenumber"),
                      labelStyle: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Color(0xFFCBCBCB),
                      ),
                      contentPadding:
                          new EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    initialCountryCode: 'IT',
                    languageCode: "it",
                    initialValue: _phoneController.text,
                    onChanged: (phone) {
                      _phoneController.text = phone.completeNumber;
                    },
                  ),
                  /* Container(
                    child: TextField(
                      controller: _phoneController,
                      style: TextStyle(fontSize: MyApp2.fontSize16, color: Colors.grey, ),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).translate("mobilenumber"),
                        hintStyle:TextStyle(fontSize: MyApp2.fontSize16, color: Colors.grey, ),
                        contentPadding: new EdgeInsets.symmetric(vertical: MyApp2.W *.025, horizontal: MyApp2.W *.025),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),*/

                  SizedBox(
                    height: MyApp2.W! * .025,
                  ),
                  Container(
                    child: TextField(
                      controller: _addressController,
                      style: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Colors.grey,
                      ),
                      keyboardType: TextInputType.streetAddress,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.translate("address"),
                        hintStyle: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: Colors.grey,
                        ),
                        contentPadding: new EdgeInsets.symmetric(
                            vertical: MyApp2.W! * .025,
                            horizontal: MyApp2.W! * .025),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MyApp2.W! * .025,
                  ),
                  Container(
                      child: TextField(
                    controller: _oldPasswordController,
                    style: TextStyle(
                      fontSize: MyApp2.fontSize16,
                      color: Colors.grey,
                    ),
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!
                          .translate("oldpassword"),
                      suffixIcon: Padding(
                        padding: EdgeInsetsDirectional.only(end: 12.0),
                        child: GestureDetector(
                          child: _obscureText2
                              ? Icon(
                                  FontAwesomeIcons.eye,
                                  color: Colors.grey,
                                  size: MyApp2.fontSize16,
                                )
                              : Icon(
                                  FontAwesomeIcons.eyeSlash,
                                  color: myColor,
                                  size: MyApp2.fontSize16,
                                ),
                          onTap: () {
                            _toggle();
                          },
                        ),
                      ),
                      hintStyle: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Colors.grey,
                      ),
                      contentPadding: new EdgeInsets.symmetric(
                          vertical: MyApp2.W! * .025,
                          horizontal: MyApp2.W! * .025),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  )),
                  SizedBox(
                    height: MyApp2.W! * .025,
                  ),
                  Container(
                    child: TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureText2,
                      style: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Colors.grey,
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!
                            .translate("newpassword"),
                        suffixIcon: Padding(
                          padding: EdgeInsetsDirectional.only(end: 12.0),
                          child: GestureDetector(
                            child: _obscureText2
                                ? Icon(
                                    FontAwesomeIcons.eye,
                                    color: Colors.grey,
                                    size: MyApp2.fontSize16,
                                  )
                                : Icon(
                                    FontAwesomeIcons.eyeSlash,
                                    color: myColor,
                                    size: MyApp2.fontSize16,
                                  ),
                            onTap: () {
                              _toggle2();
                            },
                          ),
                        ),
                        hintStyle: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: Colors.grey,
                        ),
                        contentPadding: new EdgeInsets.symmetric(
                            vertical: MyApp2.W! * .025,
                            horizontal: MyApp2.W! * .025),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MyApp2.W! * .025,
                  ),
                  Container(
                    child: TextField(
                      controller: _confirmNewPasswordController,
                      obscureText: _obscureText2,
                      style: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Colors.grey,
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!
                            .translate("confirmpassword"),
                        suffixIcon: Padding(
                          padding: EdgeInsetsDirectional.only(end: 12.0),
                          child: GestureDetector(
                            child: _obscureText2
                                ? Icon(
                                    FontAwesomeIcons.eye,
                                    color: Colors.grey,
                                    size: MyApp2.fontSize16,
                                  )
                                : Icon(
                                    FontAwesomeIcons.eyeSlash,
                                    color: myColor,
                                    size: MyApp2.fontSize16,
                                  ),
                            onTap: () {
                              _toggle2();
                            },
                          ),
                        ),
                        hintStyle: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: Colors.grey,
                        ),
                        contentPadding: new EdgeInsets.symmetric(
                            vertical: MyApp2.W! * .025,
                            horizontal: MyApp2.W! * .025),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MyApp2.W! * .045),
                  Container(
                      width: MyApp2.W! * .5,
                      child: MaterialButton(
                        padding: const EdgeInsets.only(top: 12.5, bottom: 12.5),
                        child: Text(
                          AppLocalizations.of(context)!.translate("save"),
                          style: TextStyle(
                            fontSize: MyApp2.W! * .05,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        color: myColor,
                        textColor: Colors.white,
                        onPressed: () async {
                          if (_oldPasswordController.text.isNotEmpty) {
                            await Auth2.changePassword(
                                _oldPasswordController.text,
                                _newPasswordController.text,
                                _confirmNewPasswordController.text,
                                context);
                          }

                          // Geocode address if it changed
                          String? lat;
                          String? lng;
                          if (_addressController.text != Auth2.user!.address) {
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
                              context);
                          // Update lat/long locally after save
                          if (lat != null && lng != null) {
                            Auth2.user?.lat = lat;
                            Auth2.user?.long = lng;
                          }
                          if (!mounted) return;
                          Navigator.of(context).pop();
                        },
                      )),
                  SizedBox(height: MyApp2.W! * .045),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
