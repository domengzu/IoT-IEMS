import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // Notification settings
  bool notificationsEnabled;

  // Threshold settings for alerts
  double temperatureThreshold; // in °C
  double noiseThreshold; // in dB
  double gasThreshold; // in ppm

  AppSettings({
    this.notificationsEnabled = true,
    this.temperatureThreshold = 40.0,
    this.noiseThreshold = 100.0,
    this.gasThreshold = 500.0,
  });

  // Create settings from shared preferences
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettings(
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      temperatureThreshold: prefs.getDouble('temperatureThreshold') ?? 40.0,
      noiseThreshold: prefs.getDouble('noiseThreshold') ?? 100.0,
      gasThreshold: prefs.getDouble('gasThreshold') ?? 500.0,
    );
  }

  // Save settings to shared preferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setDouble('temperatureThreshold', temperatureThreshold);
    await prefs.setDouble('noiseThreshold', noiseThreshold);
    await prefs.setDouble('gasThreshold', gasThreshold);
  }
}
