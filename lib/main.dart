import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/refresh_service.dart';
import 'views/navigation_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AwesomeNotifications().initialize(
    'resource://drawable/ic_launcher',
    [
      NotificationChannel(
        channelGroupKey: 'environmental_monitoring_group',
        channelKey: 'environmental_alerts',
        channelName: 'Environmental Alerts',
        channelDescription:
            'Notifications for hazardous environmental conditions',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
        enableVibration: false,
        vibrationPattern: null,
      ),
    ],
  );

  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 40),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              RefreshService(refreshInterval: const Duration(seconds: 2)),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Environmental Monitoring',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const NavigationController(),
      ),
    );
  }
}
