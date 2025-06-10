import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/dht11_reading.dart';
import '../../../models/noise_reading.dart';
import '../../../models/gas_reading.dart';
import '../../common/reading_gauge.dart';
import '../../../utils/formatting.dart';

class OverviewDashboard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final hasData =
        latestDHT11 != null || latestNoise != null || latestGas != null;

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No sensor data available'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
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
                  Text(
                    'Last updated: ${DateFormat('HH:mm:ss').format(lastUpdated)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grid of sensor data
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  if (latestDHT11 != null) ...[
                    _buildGridCard(
                      context,
                      'Temperature',
                      '${latestDHT11!.temperature}°C',
                      Icons.thermostat,
                      Colors.red,
                      'Ambient temperature',
                    ),
                    _buildGridCard(
                      context,
                      'Humidity',
                      '${latestDHT11!.humidity}%',
                      Icons.water_drop,
                      Colors.blue,
                      'Relative humidity',
                    ),
                    if (latestDHT11!.heatIndex != null)
                      _buildGridCard(
                        context,
                        'Heat Index',
                        '${latestDHT11!.heatIndex}°C',
                        Icons.whatshot,
                        Colors.orange,
                        'Feels like temperature',
                      ),
                  ],

                  if (latestNoise != null)
                    _buildGridCard(
                      context,
                      'Noise Level',
                      FormatUtils.toFixed2Decimals(latestNoise!.decibel) + ' dB',
                      Icons.volume_up,
                      _getNoiseColor(latestNoise!.decibel),
                      _getNoiseDescription(latestNoise!.decibel),
                    ),

                  if (latestGas != null)
                    _buildGridCard(
                      context,
                      'Gas Level',
                      latestGas!.gasLevel.toStringAsFixed(1) + ' ppm',
                      Icons.air,
                      _getGasColor(latestGas!.gasLevel),
                      _getGasDescription(latestGas!.gasLevel),
                    ),

                  if (latestGas != null)
                    _buildGridCard(
                      context,
                      'Air Quality',
                      _getAirQualityLabel(latestGas!.gasLevel),
                      Icons.cleaning_services,
                      _getAirQualityColor(latestGas!.gasLevel),
                      'Based on gas concentration',
                    ),
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
                latestDHT11?.timestamp,
                Icons.thermostat,
                Colors.green,
              ),
              _buildSourceCard(
                context,
                'Noise Levels',
                latestNoise?.timestamp,
                Icons.volume_up,
                Colors.purple,
              ),
              _buildSourceCard(
                context,
                'Gas Readings',
                latestGas?.timestamp,
                Icons.air,
                Colors.teal,
              ),
            ],
          ),
        ),
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
}
