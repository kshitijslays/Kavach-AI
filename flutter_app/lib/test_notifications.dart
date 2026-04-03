import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  
  await flutterLocalNotificationsPlugin.show(
    0,
    'title',
    'body',
    const NotificationDetails(),
  );
  
  await flutterLocalNotificationsPlugin.cancel(0);
}
