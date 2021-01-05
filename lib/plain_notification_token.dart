import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class to get token to send push notification for Flutter.
///
/// This plugin is aiming to compatible with [firebase_messaging](https://pub.dev/packages/firebase_messaging) API.
class PlainNotificationToken {
  static PlainNotificationToken _instance;
  final MethodChannel _channel;

  PlainNotificationToken._(MethodChannel channel)
      : _channel = channel {
    _channel.setMethodCallHandler(_handleMethod);
  }

  factory PlainNotificationToken() =>
      _instance ??
      (_instance = PlainNotificationToken._(
          const MethodChannel('plain_notification_token')));

  final StreamController<String> _tokenStreamController =
      StreamController<String>.broadcast();

  /// Fires when a new token is generated.
  Stream<String> get onTokenRefresh => _tokenStreamController.stream;

  /// Returns the APNs (in iOS)/FCM (in Android) token.
  Future<String> getToken() => _channel.invokeMethod<String>('getToken');

  final StreamController<IosNotificationSettings> _iosSettingsStreamController =
      StreamController<IosNotificationSettings>.broadcast();

  /// Stream that fires when the user changes their notification settings.
  ///
  /// Only fires on iOS.
  Stream<IosNotificationSettings> get onIosSettingsRegistered =>
      _iosSettingsStreamController.stream;

  /// On iOS, prompts the user for notification permissions the first time it is called.
  ///
  /// Does nothing on Android.
  void requestPermission(
      [IosNotificationSettings settings = const IosNotificationSettings()]) {
    if (Platform.isAndroid) return;

    _channel.invokeMethod("requestPermission", settings.toMap());
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "onToken":
        final String token = call.arguments;
        _tokenStreamController.add(token);
        return null;
      case "onIosSettingsRegistered":
        _iosSettingsStreamController.add(IosNotificationSettings._fromMap(
            call.arguments.cast<String, bool>()));
        return null;
    }
  }
}

/// Representing settings of notify way in iOS.
class IosNotificationSettings {
  final bool alert;
  final bool badge;
  final bool sound;

  const IosNotificationSettings(
      {this.alert = true, this.badge = true, this.sound = true});

  IosNotificationSettings._fromMap(Map<String, bool> settings)
      : sound = settings['sound'],
        alert = settings['alert'],
        badge = settings['badge'];

  @visibleForTesting
  Map<String, dynamic> toMap() {
    return <String, bool>{'sound': sound, 'alert': alert, 'badge': badge};
  }

  @override
  String toString() => 'PushNotificationSettings ${toMap()}';
}
