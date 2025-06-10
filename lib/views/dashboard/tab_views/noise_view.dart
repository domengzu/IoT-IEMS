import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/noise_reading.dart';
import '../../common/reading_gauge.dart';
import '../../common/reading_row.dart';
import '../../../utils/formatting.dart';

class NoiseDataView extends StatelessWidget {
  final List<NoiseReading> readings;
  final Future<void> Function() onRefresh;

  const NoiseDataView({
    super.key,
    required this.readings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Current noise reading card
        NoiseCurrentCard(reading: readings.first),
        // Historical noise readings
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              itemCount: readings.length,
              itemBuilder: (context, index) {
                return NoiseListItem(reading: readings[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class NoiseCurrentCard extends StatelessWidget {
  final NoiseReading reading;

  const NoiseCurrentCard({super.key, required this.reading});

  // Helper method to determine noise level category and color
  String _getNoiseCategory(double decibel) {
    if (decibel < 40) return 'Very quiet';
    if (decibel < 60) return 'Moderate';
    if (decibel < 80) return 'Loud';
    if (decibel < 100) return 'Very loud';
    return 'Dangerously loud';
  }

  Color _getNoiseColor(double decibel) {
    if (decibel < 40) return Colors.green;
    if (decibel < 60) return Colors.lightGreen;
    if (decibel < 80) return Colors.orange;
    if (decibel < 100) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final noiseCategory = _getNoiseCategory(reading.decibel);
    final noiseColor = _getNoiseColor(reading.decibel);

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
                  'Current Noise Level',
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ReadingGauge(
                  label: noiseCategory,
                  value: '${FormatUtils.toFixed2Decimals(reading.decibel)} dB',
                  icon: Icons.volume_up,
                  color: noiseColor,
                ),
              ],
            ),
            ListTile(
              title: const Text('Current Noise Level'),
              trailing: Text(
                '${FormatUtils.toFixed2Decimals(reading.decibel)} dB',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoiseListItem extends StatelessWidget {
  final NoiseReading reading;

  const NoiseListItem({super.key, required this.reading});

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
            ReadingRow(label: 'Noise Level', value: '${FormatUtils.toFixed2Decimals(reading.decibel)} dB'),
          ],
        ),
      ),
    );
  }
}
