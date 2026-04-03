import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../core/constants.dart';

class MovementDetector extends StatefulWidget {
  final Widget child;
  const MovementDetector({super.key, required this.child});

  @override
  State<MovementDetector> createState() => _MovementDetectorState();
}

class _MovementDetectorState extends State<MovementDetector> with WidgetsBindingObserver {
  // Foreground accelerometer subscription (when app is open)
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  // Background service event subscription
  StreamSubscription? _bgServiceSub;
  
  final FlutterTts _tts = FlutterTts();
  final ApiService _apiService = ApiService();

  bool _isAlerting = false;
  final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(15);
  Timer? _timer;


  DateTime _lastAlert = DateTime.now().subtract(const Duration(seconds: 45));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startForegroundDetection();
    _listenToBackgroundService();
    // Initially tell BG service we are in foreground
    FlutterBackgroundService().invoke('set_foreground', {'isForeground': true});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🏙️ [FG] App Resumed - Suppressing BG Push Notifications');
      FlutterBackgroundService().invoke('set_foreground', {'isForeground': true});
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('🌉 [BG] App Minimized - Enabling BG Push Notifications');
      FlutterBackgroundService().invoke('set_foreground', {'isForeground': false});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelSub?.cancel();
    _bgServiceSub?.cancel();
    _timer?.cancel();
    _countdownNotifier.dispose();
    super.dispose();
  }


  // Foreground detection as a fallback
  void _startForegroundDetection() {
    _accelSub?.cancel();
    _accelSub = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      if (magnitude > 30 && DateTime.now().difference(_lastAlert).inSeconds > 45 && !_isAlerting) {
        debugPrint('🚨 [FG] Shake detected in Foreground: $magnitude');
        _triggerAlert(fromBackground: false);
      }
    });
  }


  // Background: listen for the service telling us a shake happened in background
  void _listenToBackgroundService() {
    _bgServiceSub = FlutterBackgroundService().on('shakeDetected').listen((event) {
      if (!_isAlerting && mounted) {
        debugPrint('🚨 [FG] Received shake event from BG Service');
        _triggerAlert(fromBackground: true);
      }
    });
  }

  void _triggerAlert({bool fromBackground = false}) async {
    if (!mounted) return;
    
    // Stop any current TTS before starting new alert
    await _tts.stop();
    
    setState(() {
      _isAlerting = true;
      _countdownNotifier.value = 15;
      _lastAlert = DateTime.now();
    });


    if (!fromBackground) {
      // Foreground vibration feedback
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 500, 200, 500], intensities: [0, 255, 0, 255]);
      }
    }

    await _tts.speak("Sudden movement detected. Are you safe? You have 15 seconds to respond.");
    
    // Notify Background Service that we are handling it in foreground (if it was a BG shake)
    FlutterBackgroundService().invoke('fgAlertStarted');
    
    _startCountdown();
    if (mounted) {
      _showAlertDialog();
    }
  }


  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_countdownNotifier.value > 0) {
        _countdownNotifier.value--;
      } else {
        timer.cancel();
        _triggerSOS();
      }
    });
  }


  void _triggerSOS() async {
    if (!_isAlerting || !mounted) return;

    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    setState(() => _isAlerting = false);

    _tts.speak("Emergency activated. Contacting all trusted people automatically.");

    // Show a persistent "Sending SOS..." banner on screen
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Sending SOS alert to your contacts...'),
          duration: Duration(seconds: 8),
          backgroundColor: Colors.red,
        ),
      );
    }

    try {
      debugPrint('🚨 [SOS] Step 1: Getting location...');
      
      // Get location with timeout
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
        debugPrint('🚨 [SOS] Step 1 ✅ Location: ${position.latitude}, ${position.longitude}');
      } catch (locError) {
        debugPrint('🚨 [SOS] Step 1 ⚠️ Location failed, using fallback: $locError');
        // Use a fallback zero location rather than crashing
        position = Position(
          latitude: 0.0, longitude: 0.0,
          timestamp: DateTime.now(), accuracy: 0, altitude: 0,
          altitudeAccuracy: 0, headingAccuracy: 0, heading: 0, speed: 0,
          speedAccuracy: 0,
        );
      }

      debugPrint('🚨 [SOS] Step 2: Reading user state...');
      final userProvider = context.read<UserProvider>();
      final token = userProvider.token;
      final user = userProvider.user;
      final contacts = user?['emergencyContacts'] as List? ?? [];

      debugPrint('🚨 [SOS] User email: ${user?['email']}');
      debugPrint('🚨 [SOS] Token present: ${token != null}');
      debugPrint('🚨 [SOS] Contacts count: ${contacts.length}');
      debugPrint('🚨 [SOS] Contacts: $contacts');

      if (token == null) {
        debugPrint('❌ [SOS] FAILED: No auth token. User is not logged in.');
        _tts.speak("You must be logged in to send emergency alerts.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ SOS failed: Please log in first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (contacts.isEmpty) {
        debugPrint('❌ [SOS] FAILED: No emergency contacts saved in profile.');
        _tts.speak("No emergency contacts found. Please add them in your profile first.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ SOS failed: Add emergency contacts in Profile tab first.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 8),
            ),
          );
        }
        return;
      }

      debugPrint('🚨 [SOS] Step 3: Calling backend at ${AppConstants.apiBaseUrl}/emergency/alert ...');
      final response = await _apiService.triggerEmergencyAlert(token, {
        'userId': user?['email'],
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'contacts': contacts,
        'message': "🚨 EMERGENCY ALERT: I may be in danger. Please check on me immediately.",
      });
      
      debugPrint('✅ [SOS] Step 3 ✅ Backend responded: $response');
      _tts.speak("Alert sent successfully. Help is on the way.");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ SOS sent! SMS & call alerts triggered.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 6),
          ),
        );
      }

      // Fire and forget recording in background
      _recordEmergencyAudio(token, contacts);

    } catch (e) {
      debugPrint('❌ [SOS] CRITICAL ERROR: $e');
      _tts.speak("Error triggering alert. Please call emergency services manually.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ SOS Error: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  void _cancelAlert() {
    _timer?.cancel();
    setState(() => _isAlerting = false);
    // Tell the background service to cancel its 15s timer too
    FlutterBackgroundService().invoke('cancelAlert');
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _tts.speak("Safety confirmed. Emergency cancelled.");
  }

  Future<void> _recordEmergencyAudio(String token, List<dynamic> contacts) async {
    final record = AudioRecorder();
    try {
      if (await record.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/emergency_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Start recording
        await record.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
        debugPrint('🎙️ Recording emergency audio...');

        // Wait 30 seconds
        await Future.delayed(const Duration(seconds: 30));

        // Stop and get path
        final path = await record.stop();
        if (path != null) {
          debugPrint('🎙️ Recording finished, uploading...');
          await _apiService.uploadEmergencyAudio(token, path, contacts);
          debugPrint('✅ Audio uploaded to Cloudinary/SMS');
          // Cleanup
          try {
            await File(path).delete();
          } catch (_) {}
        }
      } else {
         debugPrint('❌ Microphone permission denied');
      }
    } catch (e) {
      debugPrint('🎙️ Recording error: $e');
    } finally {
      record.dispose();
    }
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you safe?',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorRed,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sudden movement was detected. If you do not respond, your emergency contacts will be alerted.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: AppTheme.slate, fontSize: 15),
                ),
                const SizedBox(height: 32),
                ValueListenableBuilder<int>(
                  valueListenable: _countdownNotifier,
                  builder: (context, value, child) {
                    return Text(
                      '$value',
                      style: GoogleFonts.outfit(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepNavy,
                      ),
                    );
                  },
                ),
                const Text('seconds remaining', style: TextStyle(color: AppTheme.slate)),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _cancelAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('YES, I AM SAFE'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _triggerSOS,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('NO, I NEED HELP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
