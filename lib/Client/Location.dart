import 'dart:convert';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/Helper/UserData.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/Client/Addresses.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:eboro/package/lib/google_map_location_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as prov;
import 'package:eboro/RealTime/Provider/CartTextProvider.dart';

import 'package:permission_handler/permission_handler.dart';
import '../Widget/Progress.dart';

class SetLocation extends StatefulWidget {
  final String? rout;
  SetLocation({Key? key, this.rout}) : super(key: key);
  @override
  SetLocation2 createState() => SetLocation2(0);
}

class SetLocation2 extends State<SetLocation> {
  final int index;
  SetLocation2(this.index);
  late AddressResult selectedPlace;
  static String? ship, tax, address, duration;
  static LatLng userPosition = LatLng(
      double.tryParse(Auth2.user?.activeLat ?? Auth2.user?.lat ?? '') ?? 45.4642,
      double.tryParse(Auth2.user?.activeLong ?? Auth2.user?.long ?? '') ?? 9.1900);

  @override
  void initState() {
    super.initState();
    if (widget.rout == null) {
      authenticate();
    }
  }

  static authenticate() async {

    String myUrl = "$globalUrl/api/distance2/"
        "${userPosition.latitude}/${userPosition.longitude}";
    http.get(Uri.parse(myUrl), headers: {
      'apiLang': MyApp2.apiLang.toString(),
      'Accept': 'application/json',
      'Authorization': "${MyApp2.token}",
    }).then((response) async {
      Map A = json.decode(response.body);
      ship = A['shipping'].toString();
      if (!ship!.contains('NaN')) {
        tax = A['Tax'].toString();
        duration = A['Duration'].toString();
      } else {
        duration = "0.0";
        ship = "0.0";
        tax = "0.0";
        //Auth2.show("Your order may not be accepted , add at last one item");
      }
    });
  }

  Future<LatLng> _getCurrentLocation() async {
    // Try cached position first (instant)
    Position? position = await Geolocator.getLastKnownPosition();
    if (position != null && position.latitude != 0.0 && position.longitude != 0.0) {
      return LatLng(position.latitude, position.longitude);
    }
    // Fallback to fresh GPS with timeout
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 8),
    );
    return LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            var status = await Permission.location.request();
            if (status.isGranted) {
              Progress.progressDialogue(context);
              LatLng myPosition = await _getCurrentLocation();
              Progress.dimesDialog(context);
              AddressResult? result = await showGoogleMapLocationPicker(
                pinWidget:
                    Icon(Icons.location_pin, color: Colors.red, size: 35),
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
                searchHint:
                    "${AppLocalizations.of(context)!.translate("search")}",
                initialLocation:
                    userPosition.longitude == 0 ? myPosition : userPosition,
                myLocation: myPosition,
              );
              if (result == null) return;
              setState(() {
                selectedPlace = result;
              });
              // Add your logic for handling the picked location here
              String lat = selectedPlace.latlng.latitude.toString();
              String lng = selectedPlace.latlng.longitude.toString();
              String address = selectedPlace.address;
              // Your existing logic for handling the picked location
              if (Auth2.user?.email != "info@eboro.com") {
                if (widget.rout != null) {
                  if (Provider2.provider != null) {
                    Provider2.provider!.clear();
                  }
                  // Update delivery address locally (don't overwrite profile address)
                  setState(() {
                    userPosition = selectedPlace.latlng;
                    UserData.deliveryAddress = address;
                    UserData.deliveryLat = lat;
                    UserData.deliveryLong = lng;
                  });
                  UserData.saveDeliveryAddress();
                  // Update only coordinates on server for distance/shipping calculation
                  Auth2.updateDeliveryCoordinates(lat, lng, context);

                  // Clear house and intercom locally
                  Auth2.user?.house = "";
                  Auth2.user?.intercom = "";

                  // Clear house and intercom on server (fire and forget)
                  final mobile = Auth2.user?.mobile ?? "";
                  Auth2.editUserlocationsHints(mobile, "", "", context,
                      whatsapp: Auth2.user?.whatsapp ?? "", navigate: false,
                      showProgress: false, popOnDone: false);

                  // Clear cart
                  final cart = prov.Provider.of<CartTextProvider>(context, listen: false);
                  await cart.clearCartSilent();

                  // Clear cache and reload providers with new coordinates
                  Provider2.clearProvidersCache();
                  final providerController = prov.Provider.of<ProviderController>(context, listen: false);
                  providerController.updateProvider(null, force: true);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AddAddress()),
                  );
                } else {
                  authenticate();
                }
              } else {
                setState(() {
                  userPosition = selectedPlace.latlng;
                  Auth2.user!.address = address;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AddAddress()),
                );
              }
            } else if (status.isDenied ||
                status.isPermanentlyDenied ||
                status.isLimited) {
              Fluttertoast.showToast(
                msg: 'Location access is denied',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                backgroundColor: Colors.grey,
              );
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize
                .min, // Ensures the row takes only the required space
            children: [
              Icon(Icons.location_on,
                  color: Colors.white,
                  size: MyApp2.fontSize16), // Location pin icon
              SizedBox(width: 4), // Space between the icon and text
              Text(
                (Auth2.user?.activeAddress == null || Auth2.user!.activeAddress!.isEmpty)
                    ? "Seleziona la posizione"
                    : Auth2.user!.activeAddress!,
                style:
                    TextStyle(color: Colors.white, fontSize: MyApp2.fontSize16),
              ),
            ],
          ),
        )
      ],
    );
  }
}
