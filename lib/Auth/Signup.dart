import 'dart:convert';
import 'dart:io';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:eboro/package/intl_phone_field/intl_phone_field.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:uuid/uuid.dart';

class SignupScreen extends StatefulWidget {
  @override
  SignupScreen2 createState() => SignupScreen2();
}

class SignupScreen2 extends State<SignupScreen> {
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _addressController = new TextEditingController();
  TextEditingController _emailController = new TextEditingController();
  TextEditingController _passwordController = new TextEditingController();
  TextEditingController _phoneController = new TextEditingController();
  TextEditingController _confirmPasswordController =
      new TextEditingController();

  bool _obscureText = false;

  File? file;
  String? base64Image;
  String? fileNames;
  String? lat;
  String? long;
  File? tmpFile;
  final String apiKey = 'AIzaSyAB9JpHw1iVlBH3izJJfsuPGKOqxLsXSpk';
  var _sessionToken;
  var uuid = new Uuid();
  List<dynamic> _placeList = [];

  @override
  void initState() {
    super.initState();
    _toggle();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSuggestionSelected(suggestion) async {
    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/details/json')
            .replace(queryParameters: {
      'place_id': (suggestion as Map<String, dynamic>)['place_id'],
      'key': 'AIzaSyAB9JpHw1iVlBH3izJJfsuPGKOqxLsXSpk',
    });
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    final location = data['result']['geometry']['location'];
    lat = location['lat'].toString();
    long = location['lng'].toString();
    String address = (suggestion)['description'] ?? '';
    if (address.isNotEmpty) {
      setState(() {
        _addressController.text = address;
      });
    }

    // Use the lat and lng to get the location
    //Auth2.editUserlocations(address, lat, lng, context);
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  chooseImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        file = File(pickedFile.path);
      });
    }
  }

  Future<List> getSuggestion(String input) async {
    if (input.isNotEmpty) {
      if (_sessionToken == null) {
        _sessionToken = uuid.v4();
      }
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=$input&key=${apiKey}&sessiontoken=$_sessionToken&language=it';
      var response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        _placeList = json.decode(response.body)['predictions'];
        return _placeList;
      } else {
        throw Exception('Failed to load predictions');
      }
    }
    return _placeList;
  }

  Future<void> _getCurrentLocation() async {
    try {
      await _requestLocationPermission();
      Position? lastPos = await Geolocator.getLastKnownPosition();
      final position = (lastPos != null && lastPos.latitude != 0.0 && lastPos.longitude != 0.0)
          ? lastPos
          : await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 8));
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      final address =
          '${placemarks[0].street}, ${placemarks[0].postalCode}, ${placemarks[0].locality}, ${placemarks[0].country}';
      if (mounted) {
        setState(() {
          _addressController.text = address;
          lat = position.latitude.toString();
          long = position.longitude.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        Auth2.show("Impossibile ottenere la posizione. Inserisci l'indirizzo manualmente.");
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  Widget showImage() {
    ImageProvider imageProvider;
    if (file != null) {
      tmpFile = file;
      base64Image = base64Encode(file!.readAsBytesSync());
      fileNames = file!.path.split("/").last;
      imageProvider = FileImage(file!);
    } else {
      imageProvider = const AssetImage('images/icons/profile.png');
    }

    return CircleAvatar(
      radius: MyApp2.W! * .15,
      backgroundColor: file != null ? Colors.black12 : myColor,
      child: CircleAvatar(
        radius: MyApp2.W! * .145,
        backgroundColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            image: DecorationImage(
              fit: BoxFit.fill,
              image: imageProvider,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(200.0)),
          ),
          alignment: Alignment.bottomRight,
          child: Container(
            height: MyApp2.W! * .075,
            width: MyApp2.W! * .075,
            decoration: BoxDecoration(
              color: myColor,
              borderRadius: const BorderRadius.all(Radius.circular(200.0)),
            ),
            child: GestureDetector(
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: MyApp2.W! * .05,
              ),
              onTap: () {
                chooseImage();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding:
              const EdgeInsets.only(left: 30, right: 30, top: 0, bottom: 0),
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: MyApp2.W! * .05,
                ),
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
                        fontSize: MyApp2.fontSize16, color: Colors.grey),
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.translate("name"),
                      labelStyle: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Color(0xFFCBCBCB),
                      ),
                      contentPadding:
                          new EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFCBCBCB), width: 0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 0.5),
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
                      labelStyle: TextStyle(
                        fontSize: MyApp2.fontSize16,
                        color: Color(0xFFCBCBCB),
                      ),
                      contentPadding:
                          new EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFCBCBCB), width: 0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MyApp2.W! * .025,
                ),
                Container(
                    child: IntlPhoneField(
                  disableLengthCheck: true,
                  decoration: InputDecoration(
                    // counterText: '',
                    labelText:
                        AppLocalizations.of(context)!.translate("mobilenumber"),
                    labelStyle: TextStyle(
                      fontSize: MyApp2.fontSize16,
                      color: Color(0xFFCBCBCB),
                    ),
                    contentPadding:
                        new EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFCBCBCB), width: 0.5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 0.5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  initialCountryCode: 'IT',
                  languageCode: "it",
                  onChanged: (phone) {
                    // Ensure space between country code and mobile number
                    String formattedNumber =
                        "${phone.countryCode} ${phone.number}";
                    _phoneController.text = formattedNumber;
                    // _phoneController.text = phone.completeNumber;
                  },
                )),
                SizedBox(
                  height: MyApp2.W! * .025,
                ),
                Container(
                  child: TypeAheadField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: "Address",
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        prefixIcon: Icon(Icons.home),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.location_pin),
                          onPressed: _getCurrentLocation,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blue, width: 0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        hintText: "Enter your address",
                        hintStyle: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: Color(0xFFCBCBCB),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      final suggestions = await getSuggestion(pattern);
                      return suggestions;
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text((suggestion
                                as Map<String, dynamic>)['description'] ??
                            ''),
                      );
                    },
                    transitionBuilder: (context, suggestionsBox, controller) {
                      return suggestionsBox;
                    },
                    onSuggestionSelected: (suggestion) {
                      _handleSuggestionSelected(suggestion);
                    },
                  ),
                ),
                SizedBox(
                  height: MyApp2.W! * .025,
                ),
                Container(
                    child: TextField(
                  controller: _passwordController,
                  style: TextStyle(
                    fontSize: MyApp2.fontSize16,
                    color: Colors.grey,
                  ),
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.translate("password"),
                    suffixIcon: Padding(
                      padding: EdgeInsetsDirectional.only(end: 12.0),
                      child: GestureDetector(
                        child: _obscureText
                            ? Icon(
                                FontAwesomeIcons.eyeSlash,
                                color: Color(0xFFCBCBCB),
                                size: MyApp2.fontSize16,
                              )
                            : Icon(
                                FontAwesomeIcons.eye,
                                color: Color(0xFFCBCBCB),
                                size: MyApp2.fontSize16,
                              ),
                        onTap: () {
                          _toggle();
                        },
                      ),
                    ),
                    labelStyle: TextStyle(
                      fontSize: MyApp2.fontSize16,
                      color: Color(0xFFCBCBCB),
                    ),
                    contentPadding:
                        new EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFCBCBCB), width: 0.5),
                      borderRadius: BorderRadius.circular(50),
                    ),
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
                    controller: _confirmPasswordController,
                    obscureText: _obscureText,
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
                          child: _obscureText
                              ? Icon(
                                  FontAwesomeIcons.eyeSlash,
                                  color: Color(0xFFCBCBCB),
                                  size: MyApp2.fontSize16,
                                )
                              : Icon(
                                  FontAwesomeIcons.eye,
                                  color: Color(0xFFCBCBCB),
                                  size: MyApp2.fontSize16,
                                ),
                          onTap: () {
                            _toggle();
                          },
                        ),
                      ),
                      labelStyle: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: Color(0xFFCBCBCB)),
                      contentPadding:
                          new EdgeInsets.symmetric(horizontal: MyApp2.W! * .06),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFCBCBCB), width: 0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MyApp2.W! * .025,
                ),
                Container(
                  child: Text(
                      AppLocalizations.of(context)!
                          .translate("TermsandConditions"),
                      style: TextStyle(
                        fontSize: MyApp2.fontSize14,
                        color: Colors.black54,
                      )),
                ),
                SizedBox(
                  height: MyApp2.W! * .025,
                ),
                Container(
                  width: MyApp2.W,
                  child: MaterialButton(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      AppLocalizations.of(context)!.translate("signup"),
                      style: TextStyle(
                        fontSize: MyApp2.fontSize20,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    color: myColor,
                    textColor: Colors.white,
                    onPressed: () {
                      if (_emailController.text.isNotEmpty &&
                          _phoneController.text.isNotEmpty &&
                          _addressController.text.isNotEmpty &&
                          _nameController.text.isNotEmpty &&
                          _confirmPasswordController.text.isNotEmpty) {
                        Auth2.signUp(
                            _nameController.text,
                            _emailController.text,
                            _phoneController.text,
                            _passwordController.text,
                            _confirmPasswordController.text,
                            _addressController.text,
                            base64Image,
                            fileNames,
                            lat,
                            long,
                            context);
                      } else {
                        Auth2.show(AppLocalizations.of(context)!
                            .translate("enterInfo"));
                      }
                    },
                  ),
                ),
                SizedBox(
                  height: MyApp2.W! * .025,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                        child: Divider(
                      thickness: 0.5,
                      color: Color(0xff818181),
                    )),
                    SizedBox(width: MyApp2.W! * .03),
                    Text(AppLocalizations.of(context)!.translate("or"),
                        style: TextStyle(
                          fontSize: MyApp2.fontSize16,
                          color: Colors.black54,
                        )),
                    SizedBox(width: MyApp2.W! * .03),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Color(0xff818181),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      child: Text(
                          AppLocalizations.of(context)!
                                  .translate("donothaveanaccount") +
                              '  ',
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          )),
                    ),
                    GestureDetector(
                      child: Text(
                          AppLocalizations.of(context)!.translate("signin"),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor,
                            fontWeight: FontWeight.w900,
                          )),
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
