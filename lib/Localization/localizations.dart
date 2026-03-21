import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:eboro/Localization/l10n/messages_all.dart';

class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Future<AppLocalizations> load(Locale locale) {
    final String name =
        locale.countryCode == null ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((bool _) {
      Intl.defaultLocale = localeName;
      return new AppLocalizations();
    });
  }

  String get Getstarted {
    return Intl.message('Get started', name: 'Getstarted');
  }
  String get restaurant {
    return Intl.message('Restaurant', name: 'restaurant');
  }
  String get signin {
    return Intl.message('Sign In', name: 'signin');
  }
  String get signup {
    return Intl.message('Sign Up', name: 'signup');
  }
  String get language {
    return Intl.message('Language', name: 'language');
  }
  String get terms {
    return Intl.message('Terms & Conditions', name: 'terms');
  }
  String get email {
    return Intl.message('Email', name: 'email');
  }
  String get password {
    return Intl.message('Password', name: 'password');
  }
  String get forgetpassword {
    return Intl.message('Forget Password?', name: 'forgetpassword');
  }
  String get donothaveanaccount {
    return Intl.message("Don't have an account?", name: 'donothaveanaccount');
  }
  String get name {
    return Intl.message("Name", name: 'name');
  }
  String get address {
  return Intl.message("Address", name: 'address');
  }
  String get mobilenumber {
    return Intl.message("Mobile number", name: 'mobilenumber');
  }
  String get TermsandConditions {
    return Intl.message("By clicking on sign up you agree to the following Terms and Conditions", name: 'TermsandConditions');
  }
  String get alreadyhaveanaccount {
  return Intl.message("Already have an account?", name: 'alreadyhaveanaccount');
  }
  String get changeyourpassword {
  return Intl.message("Please enter your email to be able to change your password", name: 'changeyourpassword');
  }
  String get send {
  return Intl.message("Send", name: 'send');
  }
  String get mostsell {
  return Intl.message("Most sell", name: 'mostsell');
  }
  String get news {
  return Intl.message("New", name: 'news');
  }
  String get categories {
  return Intl.message("Categories", name: 'categories');
  }
  String get home {
  return Intl.message("Home", name: 'home');
  }
  String get mycontacts {
  return Intl.message("My contacts", name: 'mycontacts');
  }
  String get pharmacy {
  return Intl.message("Pharmacy", name: 'pharmacy');
  }
  String get store {
  return Intl.message("Store", name: 'store');
  }
  String get supermarket {
  return Intl.message("Supermarket", name: 'supermarket');
  }
  String get party {
  return Intl.message("Party", name: 'party');
  }
  String get confirmpassword {
  return Intl.message("Confirm Password", name: 'confirmpassword');
  }
  String get myfavorite {
  return Intl.message("My Favorite", name: 'myfavorite');
  }
  String get mycart {
  return Intl.message("My Cart", name: 'mycart');
  }
  String get myprofile {
  return Intl.message("My Profile", name: 'myprofile');
  }
  String get myorders {
  return Intl.message("My Orders", name: 'myorders');
  }
  String get contactus {
  return Intl.message("Contact Us", name: 'contactus');
  }
  String get logout {
  return Intl.message("Sign Out", name: 'logout');
  }
  String get newpassword {
  return Intl.message("New Password", name: 'newpassword');
  }

  String get oldpassword {
  return Intl.message("Old Password", name: 'oldpassword');
  }
  String get confirmnewpassword {
  return Intl.message("Confirm New Password", name: 'confirmnewpassword');
  }
  String get editmyprofile {
  return Intl.message("Edit My Profile", name: 'editmyprofile');
  }
  String get total {
  return Intl.message("Total", name: 'total');
  }
  String get subject {
  return Intl.message("Subject", name: 'subject');
  }
  String get typeyourmessage {
  return Intl.message("Type your message...", name: 'typeyourmessage');
  }
  String get contactinformation {
  return Intl.message("Contact Information", name: 'contactinformation');
  }
  String get message {
  return Intl.message("Message", name: 'message');
  }
  String get date {
  return Intl.message("Date", name: 'date');
  }
  String get state {
  return Intl.message("State", name: 'state');
  }
  String get description {
  return Intl.message("Description", name: 'description');
  }
  String get details {
  return Intl.message("Details", name: 'details');
  }
  String get addtocart {
  return Intl.message("Add to Cart", name: 'addtocart');
  }
  String get price {
  return Intl.message("Price", name: 'price');
  }
  String get category {
  return Intl.message("Category", name: 'category');
  }
  String get brand {
  return Intl.message("Brand", name: 'brand');
  }
  String get type {
  return Intl.message("Type", name: 'type');
  }
  String get size {
  return Intl.message("Size", name: 'size');
  }
  String get additions {
  return Intl.message("Additions", name: 'additions');
  }
  String get calories {
  return Intl.message("Calories", name: 'calories');
  }
  String get alcohol {
  return Intl.message("Alcohol", name: 'alcohol');
  }
  String get lard {
  return Intl.message("Lard", name: 'lard');
  }
  String get shippingaddress {
  return Intl.message("Shipping Address", name: 'shippingaddress');
  }
  String get subtotal {
  return Intl.message("Subtotal", name: 'subtotal');
  }
  String get tax {
  return Intl.message("Tax", name: 'tax');
  }
  String get shipping {
  return Intl.message("Shipping", name: 'shipping');
  }
  String get paymentmethod {
  return Intl.message("Payment Method", name: 'paymentmethod');
  }
  String get cash {
  return Intl.message("Cash", name: 'cash');
  }
  String get online {
  return Intl.message("Online", name: 'online');
  }
  String get cardnumber {
  return Intl.message("Card Number", name: 'cardnumber');
  }
  String get expirationdate {
  return Intl.message("Expiration Date", name: 'expirationdate');
  }
  String get placeorder {
  return Intl.message("Place Order", name: 'placeorder');
  }

  String get yourorder {
  return Intl.message("Your Order", name: 'yourorder');
  }

  String get locale {
    return Intl.message('en', name: 'locale');
  }
}

class SpecificLocalizationDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  final Locale overriddenLocale;

  SpecificLocalizationDelegate(this.overriddenLocale);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.load(overriddenLocale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => true;
}

class FallbackCupertinoLocalisationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'it'].contains(locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) => SynchronousFuture<_DefaultCupertinoLocalizations>(_DefaultCupertinoLocalizations(locale));

  @override
  bool shouldReload(FallbackCupertinoLocalisationsDelegate old) => false;
}

class _DefaultCupertinoLocalizations extends DefaultCupertinoLocalizations {
  final Locale locale;
  
  _DefaultCupertinoLocalizations(this.locale);

 
}
