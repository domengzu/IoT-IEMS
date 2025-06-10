import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/dht11_reading.dart';
import '../../common/reading_gauge.dart';
import '../../common/reading_row.dart';

class DHT11DataView extends StatelessWidget {
  final List<DHT11Reading> readings;
  final Future<void> Function() onRefresh;

  const DHT11DataView({
    super.key,
    required this.readings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Current readings card
        DHT11CurrentCard(reading: readings.first),
        // Historical readings
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              itemCount: readings.length,
              itemBuilder: (context, index) {
                return DHT11ListItem(reading: readings[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class DHT11CurrentCard extends StatelessWidget {
  final DHT11Reading reading;

  const DHT11CurrentCard({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Readings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Updated: ${DateFormat('HH:mm:ss').format(reading.timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ReadingGauge(
                  label: 'Temperature',
                  value: '${reading.temperature}°C',
                  icon: Icons.thermostat,
                  color: Colors.red,
                ),
                ReadingGauge(
                  label: 'Humidity',
                  value: '${reading.humidity}%',
                  icon: Icons.water_drop,
                  color: Colors.blue,
                ),
                if (reading.heatIndex != null)
                  ReadingGauge(
                    label: 'Heat Index',
                    value: '${reading.heatIndex}°C',
                    icon: Icons.whatshot,
                    color: Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DHT11ListItem extends StatelessWidget {
  final DHT11Reading reading;

  const DHT11ListItem({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat(
      'MMM dd, yyyy HH:mm:ss',
    ).format(reading.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading at $formattedTime',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ReadingRow(label: 'Temperature', value: '${reading.temperature}°C'),
            ReadingRow(label: 'Humidity', value: '${reading.humidity}%'),
            if (reading.heatIndex != null)
              ReadingRow(label: 'Heat Index', value: '${reading.heatIndex}°C'),
          ],
        ),
      ),
    );
  }
}
