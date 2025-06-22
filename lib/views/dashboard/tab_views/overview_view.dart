import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/dht11_reading.dart';
import '../../../models/noise_reading.dart';
import '../../../models/gas_reading.dart';
import '../../common/reading_gauge.dart';
import '../../../utils/formatting.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../settings/settings_view.dart';
import '../../../models/settings_model.dart';

class OverviewDashboard extends StatefulWidget {
  final DHT11Reading? latestDHT11;
  final NoiseReading? latestNoise;
  final GasReading? latestGas;
  final DateTime lastUpdated;
  final VoidCallback onRefresh;

  const OverviewDashboard({
    super.key,
    this.latestDHT11,
    this.latestNoise,
    this.latestGas,
    required this.lastUpdated,
    required this.onRefresh,
  });

  @override
  State<OverviewDashboard> createState() => _OverviewDashboardState();
}

class _OverviewDashboardState extends State<OverviewDashboard> {
  bool _notificationsInitialized = false;

  // Add tracking variables for alerts that have been shown
  bool _temperatureAlertShown = false;
  bool _noiseAlertShown = false;
  bool _gasAlertShown = false;

  // Timestamp of when we last reset the notification trackers
  DateTime _lastNotificationReset = DateTime.now();

  // Settings for alerts
  late AppSettings _settings;
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await AppSettings.load();
    setState(() {
      _settingsLoaded = true;
    });
    _initializeNotifications();
  }

  void _handleSettingsChanged(AppSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    // Reset alert flags when settings change
    _resetNotificationTrackers();
  }

  @override
  void didUpdateWidget(OverviewDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If more than 30 minutes have passed since the last reset, reset all notification trackers
    if (DateTime.now().difference(_lastNotificationReset).inMinutes > 30) {
      _resetNotificationTrackers();
    }

    // Check for hazardous readings when new data comes in
    if (widget.lastUpdated != oldWidget.lastUpdated &&
        _notificationsInitialized &&
        _settingsLoaded) {
      _checkHazardousReadings();
    }
  }

  void _resetNotificationTrackers() {
    setState(() {
      _temperatureAlertShown = false;
      _noiseAlertShown = false;
      _gasAlertShown = false;
      _lastNotificationReset = DateTime.now();
    });
  }

  Future<void> _initializeNotifications() async {
    // If settings aren't loaded yet, return
    if (!_settingsLoaded) return;

    AwesomeNotifications().initialize('resource://drawable/ic_launcher', [
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
      ),
    ]);

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    _notificationsInitialized = true;

    // Check readings immediately after initialization
    _checkHazardousReadings();
  }

  void _checkHazardousReadings() {
    // Don't check if notifications are disabled or settings aren't loaded
    if (!_settingsLoaded || !_settings.notificationsEnabled) return;

    // Don't check if we don't have data
    if (widget.latestDHT11 == null &&
        widget.latestGas == null &&
        widget.latestNoise == null) {
      return;
    }

    // Check temperature (heat index)
    if (widget.latestDHT11?.heatIndex != null &&
        widget.latestDHT11!.heatIndex! >= _settings.temperatureThreshold &&
        !_temperatureAlertShown) {
      _showHazardNotification(
        id: 1,
        title: 'Extreme Heat Alert',
        body:
            'Heat index has reached ${widget.latestDHT11!.heatIndex}°C - Take precautions!',
        notificationLayout: NotificationLayout.Default,
      );
      _temperatureAlertShown = true;
    } else if (widget.latestDHT11?.heatIndex != null &&
        widget.latestDHT11!.heatIndex! < (_settings.temperatureThreshold - 5) &&
        _temperatureAlertShown) {
      // Reset the tracker if conditions improve significantly (at least 5 degrees below threshold)
      _temperatureAlertShown = false;
    }

    // Check noise level
    if (widget.latestNoise != null &&
        widget.latestNoise!.decibel >= _settings.noiseThreshold &&
        !_noiseAlertShown) {
      _showHazardNotification(
        id: 2,
        title: 'Dangerous Noise Level',
        body:
            'Noise level is ${FormatUtils.toFixed2Decimals(widget.latestNoise!.decibel)} dB - Hearing damage risk!',
        notificationLayout: NotificationLayout.Default,
      );
      _noiseAlertShown = true;
    } else if (widget.latestNoise != null &&
        widget.latestNoise!.decibel < (_settings.noiseThreshold - 15) &&
        _noiseAlertShown) {
      // Reset the tracker if conditions improve significantly (at least 15 dB below threshold)
      _noiseAlertShown = false;
    }

    // Check gas levels
    if (widget.latestGas != null &&
        widget.latestGas!.gasLevel >= _settings.gasThreshold &&
        !_gasAlertShown) {
      _showHazardNotification(
        id: 3,
        title: 'Hazardous Air Quality',
        body:
            'Gas concentration has reached ${widget.latestGas!.gasLevel.toStringAsFixed(1)} ppm - Ventilate immediately!',
        notificationLayout: NotificationLayout.Default,
      );
      _gasAlertShown = true;
    } else if (widget.latestGas != null &&
        widget.latestGas!.gasLevel < (_settings.gasThreshold - 100) &&
        _gasAlertShown) {
      // Reset the tracker if conditions improve significantly (at least 100 ppm below threshold)
      _gasAlertShown = false;
    }
  }

  Future<void> _showHazardNotification({
    required int id,
    required String title,
    required String body,
    required NotificationLayout notificationLayout,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'environmental_alerts',
        title: title,
        body: body,
        notificationLayout: notificationLayout,
        color: Colors.red,
        category: NotificationCategory.Event,
        wakeUpScreen: true,
        autoDismissible: true,
      ),
      actionButtons: [
        NotificationActionButton(key: 'DISMISS', label: 'Dismiss'),
        NotificationActionButton(key: 'VIEW', label: 'View Details'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData =
        widget.latestDHT11 != null ||
        widget.latestNoise != null ||
        widget.latestGas != null;

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No sensor data available'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Environmental Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  // Settings button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsView(
                            onSettingsChanged: _handleSettingsChanged,
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.settings, size: 20),
                  ),
                ],
              ),

              // Add notification status indicator
              if (_settingsLoaded)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        _settings.notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: _settings.notificationsEnabled
                            ? Colors.green
                            : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _settings.notificationsEnabled
                            ? "Alerts enabled"
                            : "Alerts disabled",
                        style: TextStyle(
                          color: _settings.notificationsEnabled
                              ? Colors.green
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Warning banners for hazardous conditions
              _buildWarningBanners(),

              const SizedBox(height: 16),

              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Temperature and humidity readings
                  if (widget.latestDHT11 != null) ...[
                    _buildGridCard(
                      context,
                      'Temperature',
                      '${widget.latestDHT11!.temperature}°C',
                      Icons.thermostat,
                      Colors.red,
                      'Ambient temperature',
                    ),
                    _buildGridCard(
                      context,
                      'Humidity',
                      '${widget.latestDHT11!.humidity}%',
                      Icons.water_drop,
                      Colors.blue,
                      'Relative humidity',
                    ),
                    if (widget.latestDHT11!.heatIndex != null)
                      _buildGridCard(
                        context,
                        'Heat Index',
                        '${widget.latestDHT11!.heatIndex}°C',
                        Icons.whatshot,
                        _getHeatIndexColor(widget.latestDHT11!.heatIndex!),
                        _getHeatIndexDescription(
                          widget.latestDHT11!.heatIndex!,
                        ),
                      ),
                  ],

                  // Noise reading
                  if (widget.latestNoise != null)
                    _buildGridCard(
                      context,
                      'Noise Level',
                      '${FormatUtils.toFixed2Decimals(widget.latestNoise!.decibel)} dB',
                      Icons.volume_up,
                      _getNoiseColor(widget.latestNoise!.decibel),
                      _getNoiseDescription(widget.latestNoise!.decibel),
                    ),

                  // Gas readings
                  if (widget.latestGas != null) ...[
                    _buildGridCard(
                      context,
                      'Gas Level',
                      '${widget.latestGas!.gasLevel.toStringAsFixed(1)} ppm',
                      Icons.air,
                      _getGasColor(widget.latestGas!.gasLevel),
                      _getGasDescription(widget.latestGas!.gasLevel),
                    ),
                    _buildGridCard(
                      context,
                      'Air Quality',
                      _getAirQualityLabel(widget.latestGas!.gasLevel),
                      Icons.healing,
                      _getAirQualityColor(widget.latestGas!.gasLevel),
                      'Based on gas concentration',
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                'Data Sources',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSourceCard(
                context,
                'Temperature & Humidity',
                widget.latestDHT11?.timestamp,
                Icons.thermostat,
                Colors.green,
              ),
              _buildSourceCard(
                context,
                'Noise Levels',
                widget.latestNoise?.timestamp,
                Icons.volume_up,
                Colors.purple,
              ),
              _buildSourceCard(
                context,
                'Gas Readings',
                widget.latestGas?.timestamp,
                Icons.air,
                Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanners() {
    List<Widget> warnings = [];

    // Only check against settings if they're loaded
    if (!_settingsLoaded) return Column(children: warnings);

    // Heat index warning
    if (widget.latestDHT11?.heatIndex != null &&
        widget.latestDHT11!.heatIndex! >= _settings.temperatureThreshold) {
      warnings.add(
        _buildWarningBanner(
          'HIGH HEAT: Heat index is ${widget.latestDHT11!.heatIndex}°C - Caution advised!',
          Colors.red[900]!,
        ),
      );
    }

    // Noise warning
    if (widget.latestNoise != null &&
        widget.latestNoise!.decibel >= _settings.noiseThreshold) {
      warnings.add(
        _buildWarningBanner(
          'DANGEROUS NOISE: ${FormatUtils.toFixed2Decimals(widget.latestNoise!.decibel)} dB - Hearing damage risk!',
          Colors.red[900]!,
        ),
      );
    }

    // Gas warning
    if (widget.latestGas != null &&
        widget.latestGas!.gasLevel >= _settings.gasThreshold) {
      warnings.add(
        _buildWarningBanner(
          'HAZARDOUS AIR QUALITY: ${widget.latestGas!.gasLevel.toStringAsFixed(1)} ppm - Ventilate immediately!',
          Colors.red[900]!,
        ),
      );
    }

    return Column(children: warnings);
  }

  Widget _buildWarningBanner(String message, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(
    BuildContext context,
    String title,
    DateTime? timestamp,
    IconData icon,
    Color color,
  ) {
    final String timeText = timestamp != null
        ? DateFormat('MMM dd, yyyy HH:mm:ss').format(timestamp)
        : 'No data';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text('Last reading: $timeText'),
        trailing: timestamp != null
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error_outline, color: Colors.red),
      ),
    );
  }

  // Helper methods for categorizing sensor readings
  String _getNoiseDescription(double decibel) {
    if (decibel < 40.00) return 'Very quiet environment';
    if (decibel < 60.00) return 'Moderate noise level';
    if (decibel < 80.00) return 'Loud environment';
    if (decibel < 100.00) return 'Very loud, potentially harmful';
    return 'Dangerous noise level';
  }

  Color _getNoiseColor(double decibel) {
    if (decibel < 40.00) return Colors.green;
    if (decibel < 60.00) return Colors.lightGreen;
    if (decibel < 80.00) return Colors.orange;
    if (decibel < 100.00) return Colors.deepOrange;
    return Colors.red;
  }

  String _getGasDescription(double level) {
    if (level < 100) return 'Low gas concentration';
    if (level < 300) return 'Moderate gas level';
    if (level < 500) return 'High gas concentration';
    return 'Dangerous gas level';
  }

  Color _getGasColor(double level) {
    if (level < 100) return Colors.green;
    if (level < 300) return const Color.fromARGB(255, 231, 209, 12);
    if (level < 500) return Colors.orange;
    return Colors.red;
  }

  String _getAirQualityLabel(double level) {
    if (level < 100) return 'Good';
    if (level < 300) return 'Moderate';
    if (level < 500) return 'Unhealthy';
    return 'Hazardous';
  }

  Color _getAirQualityColor(double level) {
    if (level < 100) return Colors.green;
    if (level < 300) return Colors.yellow;
    if (level < 500) return Colors.orange;
    return Colors.red;
  }

  String _getHeatIndexDescription(double heatIndex) {
    if (heatIndex < 27) return 'Comfortable';
    if (heatIndex < 32) return 'Caution';
    if (heatIndex < 40) return 'Extreme Caution';
    if (heatIndex < 54) return 'Danger';
    return 'Extreme Danger';
  }

  Color _getHeatIndexColor(double heatIndex) {
    if (heatIndex < 27) return Colors.green;
    if (heatIndex < 32) return Colors.yellow;
    if (heatIndex < 40) return Colors.orange;
    if (heatIndex < 54) return Colors.deepOrange;
    return Colors.red;
  }
}
