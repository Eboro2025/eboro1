import 'package:flutter/foundation.dart';

/// Web-safe replacements for `dart:io`'s `Platform` checks.
///
/// `Platform.isIOS` / `Platform.isAndroid` throw
/// "Unsupported operation: Platform._operatingSystem" when the app runs on the
/// web, so every check has to go through `kIsWeb` first.
bool get isIOSPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get isAndroidPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
