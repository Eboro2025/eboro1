import 'package:eboro/All/NotificationService.dart';

class SendNotification {
  static String? selectedNotificationPayload;

  static PushNotification(msg, body) async {
    await NotificationService.showLocalNotification(
      title: msg.toString(),
      body: body.toString(),
    );
  }
}
