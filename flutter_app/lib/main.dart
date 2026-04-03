import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'navigation/app_router.dart';
import 'providers/user_provider.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KavachApp());
}

class KavachApp extends StatelessWidget {
  const KavachApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize background service after engine is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeBackgroundService();
      
      // FORWARD NATIVE POWER BUTTON SIGNALS
      const nativeChannel = MethodChannel('com.example.kavach/sos');
      int lastTriggerTime = 0;
      
      nativeChannel.setMethodCallHandler((call) async {
        if (call.method == 'trigger_sos') {
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          if (currentTime - lastTriggerTime < 2000) {
            debugPrint('🚨 [UI] Ignoring duplicate SOS signal (debounce)');
            return null;
          }
          lastTriggerTime = currentTime;
          
          debugPrint('🚨 [UI] Hardware SOS signal received, invoking background trigger...');
          FlutterBackgroundService().invoke('forceTriggerSOS');
        }
        return null;
      });
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp.router(
        title: 'Kavach Shield AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
