import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final service = FlutterBackgroundService();
  if (notificationResponse.actionId == 'yes_safe') {
    service.invoke('cancelAlert');
  } else if (notificationResponse.actionId == 'no_help') {
    service.invoke('forceTriggerSOS');
  }
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'kavach_foreground', // id
    'Kavach Safety Service', // name
    description: 'This service keeps Kavach active in the background to detect emergency shakes.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await (flutterLocalNotificationsPlugin as dynamic).initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'kavach_foreground',
      initialNotificationTitle: 'Kavach is active',
      initialNotificationContent: 'Monitoring for safety shakes',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  
  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }
  
  // Setup notifications for background isolate
  final bgNotifications = FlutterLocalNotificationsPlugin();
  final apiService = ApiService();
  
  try {
    debugPrint('🚨 [BG] Attempting to initialize notifications...');
    
    // Ensure the channel is also created in the background isolate (redundant but safe)
    const AndroidNotificationChannel bgChannel = AndroidNotificationChannel(
      'kavach_foreground', 
      'Kavach Safety Service',
      description: 'This service keeps Kavach active in the background to detect emergency shakes.',
      importance: Importance.max, // Max for heads-up
    );
    
    await bgNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bgChannel);

    await (bgNotifications as dynamic).initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    debugPrint('🚨 [BG] Notifications initialized ✅');
  } catch (e, stack) {
    debugPrint('🚨 [BG] Notification init error: $e');
    debugPrint('🚨 [BG] Stack: $stack');
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  bool isAlerting = false;
  bool isFgHandling = false;
  DateTime lastAlert = DateTime.now().subtract(const Duration(seconds: 45));

  // Forward declaration of trigger sequence to avoid duplication
  Future<void> triggerEmergencySequence() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
         permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        debugPrint('❌ [BG] Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final storage = StorageService();
      final prefs = await SharedPreferences.getInstance();
      final String? userEmail = prefs.getString('userEmail');
      final String? contactsJson = prefs.getString('userEmergencyContacts');
      
      // FALLBACK: Use regular SharedPreferences for token because SecureStorage fails in BG isolates
      final String? token = await storage.getToken() ?? prefs.getString('userToken');
      
      List<dynamic> contacts = [];
      if (contactsJson != null) {
        contacts = jsonDecode(contactsJson);
      }

      if (token != null && contacts.isNotEmpty) {
        final apiService = ApiService();
        debugPrint('🚨 [BG] Triggering alert for ${contacts.length} contacts...');
        
        await apiService.triggerEmergencyAlert(token, {
          'userId': userEmail ?? 'unknown_user',
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'contacts': contacts,
          'message': "🚨 EMERGENCY ALERT: I may be in danger. Please check on me immediately."
        });
        debugPrint('✅ [BG] Emergency alert API call successful');
        
        (bgNotifications as dynamic).cancel(890); // Dismiss safe prompt if it's there
        
        // Show notification that it was sent
        (bgNotifications as dynamic).show(
          889,
          'SOS Sent',
          'Your emergency contacts have been alerted. Recording 30s audio...',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'kavach_foreground',
              'Kavach Safety Service',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );

        // Start audio recording in background
        final record = AudioRecorder();
        try {
          if (await record.hasPermission()) {
            final dir = await getTemporaryDirectory();
            final filePath = '${dir.path}/emergency_audio_bg_${DateTime.now().millisecondsSinceEpoch}.m4a';

            await record.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
            debugPrint('🎙️ [BG] Recording emergency audio...');

            await Future.delayed(const Duration(seconds: 30));

            final path = await record.stop();
            if (path != null) {
              debugPrint('🎙️ [BG] Recording finished, uploading...');
              await apiService.uploadEmergencyAudio(token, path, contacts);
              debugPrint('✅ [BG] Audio uploaded to Cloudinary/SMS');
              try {
                await File(path).delete();
              } catch (_) {}
            }
          }
        } catch (e) {
          debugPrint('🎙️ [BG] Recording error: $e');
        } finally {
          record.dispose();
        }

      }
    } catch (e) {
      debugPrint('SOS Background Error: $e');
    }
  }

  service.on('set_foreground').listen((event) {
    if (event != null && event['isForeground'] != null) {
      isFgHandling = event['isForeground'];
      debugPrint('🚨 [BG] Foreground State Changed: $isFgHandling');
    }
  });

  service.on('fgAlertStarted').listen((event) {
    isFgHandling = true;
    isAlerting = true; // Block bg detection while fg is handling
    debugPrint('🚨 [BG] Alert started in Foreground, suppressing Push Notification');
  });

  service.on('cancelAlert').listen((event) {
    isAlerting = false;
    isFgHandling = false;
    (bgNotifications as dynamic).cancel(890);
  });

  service.on('forceTriggerSOS').listen((event) async {
    if (isAlerting) {
      isAlerting = false;
      (bgNotifications as dynamic).cancel(890);
      await triggerEmergencySequence();
    }
  });

  debugPrint('👋 [BG] accelerometer listener starting...');
  userAccelerometerEvents.listen((UserAccelerometerEvent event) async {
    final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    if (magnitude > 28 && DateTime.now().difference(lastAlert).inSeconds > 45 && !isAlerting) {
      debugPrint('🚨 [BG] SHAKE DETECTED! Mag: $magnitude');
      isAlerting = true;
      lastAlert = DateTime.now();

      if (isFgHandling) {
        debugPrint('🚨 [BG] App is in foreground, letting UI handle the shake. Sending event...');
        service.invoke('shakeDetected');
        return;
      }

      debugPrint('🚨 [BG] App is in background. Showing local "Are you safe?" prompt...');
      
      // RESTORED LOCAL NOTIFICATION TRIGGER
      await (bgNotifications as dynamic).show(
        890,
        'Are you safe?',
        'Sudden movement detected. Confirm your safety immediately.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'kavach_foreground',
            'Kavach Safety Service',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            actions: [
              AndroidNotificationAction('yes_safe', 'YES, I AM SAFE', cancelNotification: true),
              AndroidNotificationAction('no_help', 'NO, I NEED HELP', cancelNotification: true),
            ],
          ),
        ),
      );

      service.invoke('shakeDetected');

      // Vibrate locally to alert the user immediately
      for (int i = 0; i < 3; i++) {
        if (isFgHandling || !isAlerting) break;
        if (await Vibration.hasVibrator() ?? false) {
           Vibration.vibrate(duration: 800);
        }
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      await Future.delayed(const Duration(seconds: 11));

      if (isAlerting && !isFgHandling) {
        isAlerting = false;
        await triggerEmergencySequence();
      }
      isAlerting = false;
    }
  });
}
